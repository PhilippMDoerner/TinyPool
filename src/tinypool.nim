import std/[times, monotimes, locks, db_sqlite, logging]

var logger = newConsoleLogger()

type ConnectionPool = object
  connections: seq[DbConn]
  lock: Lock
  defaultPoolSize: int
  burstEndTime: MonoTime
  isInBurstMode: bool
  databasePath: string
  boostModeDuration: Duration


var POOL {.global.}: ConnectionPool #Set in initConnectionPool
proc isEmpty(pool: ConnectionPool): bool = pool.connections.len() == 0
proc isFull(pool: ConnectionPool): bool = pool.connections.len() >= pool.defaultPoolSize


proc createRawDatabaseConnection(databasePath: string): DbConn =
    ## Creates a standard sqlite DbConn to the database this was initialized with
    return open(databasePath, "", "", "")


proc refillConnections(pool: var ConnectionPool) =
  ## Creates a number of database connections equal to the size of the connection pool
  ## and adds them to said pool
  withLock pool.lock:
    for i in 1..pool.defaultPoolSize:
      pool.connections.add(createRawDatabaseConnection(pool.databasePath))


proc initConnectionPool*(databasePath: string, poolSize: int, boostModeDuration: Duration = initDuration(minutes = 30)) = 
  ## Initializes the connection pool globally. To do so requires 
  ## the path to the database (`databasePath`) which shall be connected to, 
  ## and the number of connections within the pool under normal load (`poolSize`).

  POOL.connections = @[]
  POOL.isInBurstMode = false
  POOL.burstEndTime = getMonoTime()
  POOL.defaultPoolSize = poolSize
  POOL.databasePath = databasePath
  POOL.boostModeDuration = boostModeDuration
  initLock(POOL.lock)

  POOL.refillConnections()

  logger.log(lvlNotice, "Initialized pool to database '" & POOL.databasePath & "' with " & $POOL.connections.len() & " connections")


proc activateBurstMode(pool: var ConnectionPool) =
  ## Activates burst mode on the connection pool. Burst mode is active
  ## for a limited time after activation, determined by the burstModeDuration
  ## set during initialization. While active, it allows the pool to contain more
  ## connections than it can contain by default and replenishes the connections 
  ## within the pool. If triggered while burst mode is already active, this 
  ## will refill the pool and reset the timer.
  pool.isInBurstMode = true
  pool.burstEndTime = getMonoTime() + pool.boostModeDuration
  
  pool.refillConnections()


proc updateBurstModeState(pool: var ConnectionPool) =
  ## Checks whether the burst mode on the connection pool has run out and turns
  ## it off if so. Does nothing if burst mode is already off.
  if not pool.isInBurstMode:
    return

  if getMonoTime() > pool.burstEndTime:
    pool.isInBurstMode = false


proc extendBurstModeLifetime(pool: var ConnectionPool) =
  ## Delays the time after which burst mode is turned off for the given pool.
  ## If the point in time is further away from now than the pools boostModeDuration
  ## then the time is not extended. Throws a DbError if burst mode lifetime is
  ## attempted to be extended while pool is not in burst mode.
  if pool.isInBurstMode == false:
    logger.log(lvlError, "Tried to extend pool' burst mode while pool wasn't in burst mode. You have a logic issue!")

  let hasAlreadyMaxBurstModeDuration: bool = pool.burstEndTime - getMonoTime() > pool.boostModeDuration
  if hasAlreadyMaxBurstModeDuration:
    return

  pool.burstEndTime = pool.burstEndTime + initDuration(seconds = 5)


proc borrowConnection(pool: var ConnectionPool): DbConn {.gcsafe.} =
  ## Tries to borrow a database connection from the connection pool.
  ## This operation is thread-safe, as it locks the pool while trying to
  ## borrow a connection from it.
  ## Can activate burst mode if larger amounts of connections are necessary.
  ## Extends the pools burst mode if it is in burst mode and need for
  ## the same level of connections is still present.
  {.cast(gcsafe).}:
    withLock pool.lock:
      if pool.isEmpty():
        pool.activateBurstMode()

      elif not pool.isFull() and pool.isInBurstMode: 
        pool.extendBurstModeLifetime()
        
      result = pool.connections.pop()
      logger.log(lvlNotice, "AFTER BORROW - Number of connections in pool: " & $pool.connections.len())


proc recycleConnection(pool: var ConnectionPool, connection: DbConn) {.gcsafe.} =
  ## Recycles a connection and tries to return it to the pool.
  ## This operation is thread-safe, as it locks the pool while trying to return
  ## the connection.
  ## If the pool is full and not in burst mode, the connection is superfluous 
  ## and thusclosed and garbage collected.
  ## If the pool is in burst mode, it will allow an unlimited number of 
  ## connections into the pool.
  {.cast(gcsafe).}:
    withLock pool.lock:
      pool.updateBurstModeState()

      if pool.isFull() and not pool.isInBurstMode:
        connection.close()
      else:
        pool.connections.add(connection)

      logger.log(lvlNotice, "AFTER RECYCLE - Number of connections in pool: " & $pool.connections.len() )


proc destroyConnectionPool*() =
  ## Destroys the currently initialized pool. This also ensures that all
  ## connections currently within the pool are closed.
  deinitLock(POOL.lock)

  for connection in POOL.connections:
    connection.close()

  logger.log(lvlNotice, "Destroyed pool to database '" & POOL.databasePath & "'")


template withDbConn*(connection: untyped, body: untyped) =
  ## The main way of using connections. Borrows a database connection from 
  ## the pool, executes the body and then recycles the connection
  block: #ensures connection exists only within the scope of this block
    let connection: DbConn = POOL.borrowConnection()
    try:
      body
    finally:
      POOL.recycleConnection(connection)

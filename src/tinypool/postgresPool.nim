import core
import std/[db_postgres]

export db_postgres
export PoolDefect

var POSTGRES_POOL {.global.}: ConnectionPool[DbConn] = nil

proc borrowConnection*(): DbConn {.gcsafe.} =
  {.cast(gcsafe).}:
    POSTGRES_POOL.borrowConnection()

proc recycleConnection*(connection: var DbConn) {.gcsafe.} =
  {.cast(gcsafe).}:
    POSTGRES_POOL.recycleConnection(move connection)

proc initConnectionPool*(
  createConnectionProc: CreateConnectionProc[DbConn], 
  poolSize: int, 
  burstModeDuration: Duration = initDuration(minutes = 30)
) =
  POSTGRES_POOL.initConnectionPool(createConnectionProc, poolSize, burstModeDuration)

proc destroyConnectionPool*() =
  POSTGRES_POOL.destroyConnectionPool()

template withDbConn*(connection: untyped, body: untyped) =
  ## The main way of using connections. Borrows a database connection from 
  ## the pool, executes the body and then recycles the connection
  block: #ensures connection exists only within the scope of this block
    var connection = borrowConnection()
    try:
      body
    finally:
      recycleConnection(connection)

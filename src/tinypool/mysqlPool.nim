import core
import db_connector/[db_mysql]

export db_mysql
export PoolDefect

var MYSQL_POOL {.global.}: ConnectionPool[DbConn] = nil

proc borrowConnection*(): DbConn {.gcsafe.} =
  {.cast(gcsafe).}:
    MYSQL_POOL.borrowConnection()

proc recycleConnection*(connection: var DbConn) {.gcsafe.} =
  {.cast(gcsafe).}:
    MYSQL_POOL.recycleConnection(move connection)

proc initConnectionPool*(
  createConnectionProc: CreateConnectionProc[DbConn], 
  poolSize: int, 
  burstModeDuration: Duration = initDuration(minutes = 30)
) =
  MYSQL_POOL.initConnectionPool(createConnectionProc, poolSize, burstModeDuration)

proc destroyConnectionPool*() =
  MYSQL_POOL.destroyConnectionPool()

template withDbConn*(connection: untyped, body: untyped) =
  ## The main way of using connections. Borrows a database connection from 
  ## the pool, executes the body and then recycles the connection
  block: #ensures connection exists only within the scope of this block
    var connection = borrowConnection()
    try:
      body
    finally:
      recycleConnection(connection)

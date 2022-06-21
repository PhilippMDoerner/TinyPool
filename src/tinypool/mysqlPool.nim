import core
import std/[db_mysql]

export db_mysql
export PoolDefect
export withDbConn

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

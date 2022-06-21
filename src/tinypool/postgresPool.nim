import core
import std/[db_postgres]

export db_postgres
export PoolDefect
export withDbConn

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

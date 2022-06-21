import core
import std/[db_sqlite]

export db_sqlite
export PoolDefect
export withDbConn

var SQLITE_POOL {.global.}: ConnectionPool[DbConn] = nil

proc borrowConnection*(): DbConn {.gcsafe.} =
  {.cast(gcsafe).}:
    SQLITE_POOL.borrowConnection()

proc recycleConnection*(connection: var DbConn) {.gcsafe.} =
  {.cast(gcsafe).}:
    SQLITE_POOL.recycleConnection(move connection)

proc initConnectionPool*(databasePath: string, poolSize: int, burstModeDuration: Duration = initDuration(minutes = 30)) =
  let createConnectionProc: CreateConnectionProc[DbConn] = proc(): DbConn = open(databasePath, "", "", "")
  SQLITE_POOL.initConnectionPool(createConnectionProc, poolSize, burstModeDuration)

proc destroyConnectionPool*() =
  SQLITE_POOL.destroyConnectionPool()

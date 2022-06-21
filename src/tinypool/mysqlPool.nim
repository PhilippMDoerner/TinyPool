import core
import std/[db_mysql]

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
  runnableExamples:
    initConnectionPool(":memory:", 2)

    withDbConn(myCon):
      myCon.exec(sql"""CREATE TABLE "auth_user" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "username" varchar(150) NOT NULL UNIQUE);""")
      myCon.exec(sql"""INSERT INTO auth_user (username) VALUES ('henry');""")
      let rows = myCon.getAllRows(sql"""SELECT * FROM auth_user WHERE username LIKE 'Henry';""")
      assert rows.len() == 1
      assert rows[0].username == "henry"

    destroyConnectionPool()

  block: #ensures connection exists only within the scope of this block
    var connection = borrowConnection()
    try:
      body
    finally:
      recycleConnection(connection)

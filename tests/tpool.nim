# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import std/[unittest, logging, db_sqlite]

import tinypool/pool

setLogFilter(lvlNone)

suite "withDbConn":

  test "Given an initialized pool, when using withDbConn, then be able to create a table, insert and select entries":
    initConnectionPool(":memory:", 2)

    withDbConn(myCon):
      myCon.exec(sql"""CREATE TABLE "auth_user" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "username" varchar(150) NOT NULL UNIQUE)""")
      myCon.exec(sql"""INSERT INTO auth_user (username) VALUES ('henry')""")
      let rows = myCon.getAllRows(sql"""SELECT * FROM auth_user WHERE username LIKE 'Henry'""")
      check rows.len() == 1
      check rows[0][0] == "1"
      check rows[0][1] == "henry"

    destroyConnectionPool()
  
  test "Given using withDbConn with an initialized pool, when using the connection outside of withDbConn, then don't compile":
    initConnectionPool(":memory:", 2)

    withDbConn(myCon):
      discard "I'm not doing anything here"

    check compiles(myCon.exec(sql"""CREATE TABLE "auth_user" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT)""")) == false

    destroyConnectionPool()


  test "Given no initialized pool, when asking for a connection throw a PoolDefect":
    expect PoolDefect:
      withDbConn(myCon):
        myCon.exec(sql"""CREATE TABLE "auth_user" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "username" varchar(150) NOT NULL UNIQUE);""")


  test "Given a destroyed pool, when asking for a connection throw a PoolDefect":
    initConnectionPool(":memory:", 2)
    destroyConnectionPool()

    expect PoolDefect:
      withDbConn(myCon):
        myCon.exec(sql"""CREATE TABLE "auth_user" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "username" varchar(150) NOT NULL UNIQUE);""")


suite "initConnectionPool":
  setup: 
    initConnectionPool(":memory:", 2)
  
  teardown:
    destroyConnectionPool()


  test "Given an initialized pool, when initializing it for a second time, throw a PoolDefect":
    expect PoolDefect:
      initConnectionPool(":memory:", 2)
      
  
  test "Given an initialized pool with 2, when borrowing more connections than the pool has, generate new connections":
    var con1 = borrowConnection()
    var con2 = borrowConnection()
    var con3 = borrowConnection()
    con1.recycleConnection()
    con2.recycleConnection()
    con3.recycleConnection()


suite "destroyConnectionPool":
  test "Given an initialized pool, when having destroyed the pool, then be unable to borrow from it":
    initConnectionPool(":memory:", 2)
    destroyConnectionPool()
    expect PoolDefect:
      discard borrowConnection()

  test "Given an initialized pool, when having destroyed the pool, then be unable to recycle back to it":
    initConnectionPool(":memory:", 2)
    var con = borrowConnection()

    destroyConnectionPool()
    expect PoolDefect:
      con.recycleConnection()

  test "Given an uninitialized pool, when destroying the pool, do nothing":
    destroyConnectionPool()

  test "Given a destroyed pool, when destroying the pool, do nothing":
    initConnectionPool(":memory:", 2)
    destroyConnectionPool()
    destroyConnectionPool()


suite "borrowConnection":
  setup: 
    initConnectionPool(":memory:", 2)
  
  teardown:
    destroyConnectionPool()

  test "Given a borrowed connection, when using it to execute an SQL statement, then execute the SQL statement and be recyclable":
    var con = borrowConnection()
    
    con.exec(sql"""CREATE TABLE "auth_user" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "username" varchar(150) NOT NULL UNIQUE)""")
    con.exec(sql"""INSERT INTO auth_user (username) VALUES ('henry')""")
    let rows = con.getAllRows(sql"""SELECT * FROM auth_user WHERE username LIKE 'Henry'""")
    check rows.len() == 1
    check rows[0][0] == "1"
    check rows[0][1] == "henry"

    con.recycleConnection()
  # TODO: Figure out how to implement this
  # test "Given a borrowed connection, when using it after it has been recycled, throw a PoolDefect":
  #   var con = borrowConnection()
  #   con.recycleConnection()

  #   check compiles(con.exec(sql"""CREATE TABLE "auth_user" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT)""")) == false

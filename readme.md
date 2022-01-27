# TinyPool

Tinypool is a minimalistic sqlite connection pool with support for multi-threaded access.
It's essentially a global-variable `seq[DbConn]` that can be accessed in a thread-safe manner.

Your 2 main ways of interacting with it is either:

1. `borrowConnection` and `recycleConnection` OR
2. `withDbConn(someConnectionVariableName)`

## 1. borrowConnection and recycleConnection

```nim
import tinypool #For convenience reasons, tinypool also exports std/db_sqlite since you'll need that either way

let databasePath = ":memory:"
let defaultPoolSize = 20
initConnections(databasePath, defaultPoolSize)


let myCon: DbConn = borrowConnection()

myCon.exec(sql"""CREATE TABLE "auth_user" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "username" varchar(150) NOT NULL UNIQUE);""")

myCon.exec(sql"""INSERT INTO auth_user (username) VALUES ('henry');""")

let rows = myCon.getAllRows(sql"""SELECT * FROM auth_user WHERE username LIKE 'Henry';""")
assert rows.len() == 1
assert rows[0].username == "henry"

myCon.recycleConnection()
```

## 2. withDbConn

```nim
import tinypool #For convenience reasons, tinypool also exports std/db_sqlite since you'll need that either way

let databasePath = ":memory:"
let defaultPoolSize = 20
initConnections(databasePath, defaultPoolSize)

var rows: seq[Row]
withDbConn(connection):
  myCon.exec(sql"""CREATE TABLE "auth_user" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "username" varchar(150) NOT NULL UNIQUE);""")

  myCon.exec(sql"""INSERT INTO auth_user (username) VALUES ('henry');""")

  let rows = myCon.getAllRows(sql"""SELECT * FROM auth_user WHERE username LIKE 'Henry';""")
assert rows.len() == 1
assert rows[0].username == "henry"

destroyConnectionPool()
```

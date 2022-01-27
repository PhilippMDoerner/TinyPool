# TinyPool

Tinypool is a minimalistic sqlite connection pool with support for multi-threaded access.
It's essentially a global-variable `seq[DbConn]` associated with a `lock` that can be accessed in a thread-safe manner.
It also grows and shrinks as configured, but more on that down the line.

## Quickstart

Your 2 main ways of interacting with tinypool after initialization is either:

1. `withDbConn(someConnectionVariableName)` (recommended)
2. `borrowConnection` and `recycleConnection`

### 1. withDbConn

```nim
import tinypool #For convenience reasons, tinypool also exports std/db_sqlite since you'll need that either way

let databasePath = ":memory:"
let defaultPoolSize = 2
initConnections(databasePath, defaultPoolSize)

var rows: seq[Row]

withDbConn(myCon):
  myCon.exec(sql"""CREATE TABLE "auth_user" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "username" varchar(150) NOT NULL UNIQUE);""")

  myCon.exec(sql"""INSERT INTO auth_user (username) VALUES ('henry');""")

  let rows = myCon.getAllRows(sql"""SELECT * FROM auth_user WHERE username LIKE 'Henry';""")

assert rows.len() == 1
assert rows[0].username == "henry"

destroyConnectionPool()
```

### 2. borrowConnection and recycleConnection

```nim
import tinypool #For convenience reasons, tinypool also exports std/db_sqlite since you'll need that either way

let databasePath = ":memory:"
let defaultPoolSize = 2
initConnections(databasePath, defaultPoolSize)


let myCon: DbConn = borrowConnection()

myCon.exec(sql"""CREATE TABLE "auth_user" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "username" varchar(150) NOT NULL UNIQUE);""")

myCon.exec(sql"""INSERT INTO auth_user (username) VALUES ('henry');""")

let rows = myCon.getAllRows(sql"""SELECT * FROM auth_user WHERE username LIKE 'Henry';""")
assert rows.len() == 1
assert rows[0].username == "henry"

myCon.recycleConnection()
```

## Initialization/Configuration and Destruction

In order for tinypool to work, it needs to be told where the sqlite database is that it shall connect to, and how many connections it is supposed to hold under normal circumstances.

To initialize the pool e.g. on startup of your application, just call `initConnectionPool(databasePath, poolSize)`.
To destroy the pool e.g. on shutdown of your application, just call `destroyConnectionPool`.

## burstMode

If more connections are needed than it has, the pool will temporarily go into "burst mode" and automatically refill with new batch of connections, the amount of which is determined by the `poolSize`.

While the pool is in burst mode it can hold an unlimited amount of connections.

While the pool is not in burst mode, any superfluous connection that is returned to it gets closed.

Burst mode ends after a specified duration (30 minutes), though that gets extended if the connections from the added batch are still needed.

# TinyPool

Tinypool is a minimalistic connection pool with support for multi-threaded access. It supports sqlite, postgres (new with v1.0.0) and mysql (new with v1.0.0).
It's essentially a global-variable `seq[DbConn]` associated with a `lock` that can be accessed in a thread-safe manner.
It also grows and shrinks as configured, but more on that down the line.

## Installation

`nimble install tinypool`

## Quickstart

Your 2 main ways of interacting with tinypool after initialization are either:

1. `withDbConn(someConnectionVariableName)` (recommended)
2. `borrowConnection` and `recycleConnection`

### 1. withDbConn

```nim
import tinypool/sqlitePool #For convenience reasons, sqlitePool also exports std/db_sqlite since you'll need that either way

let databasePath = ":memory:"
let defaultPoolSize = 2
initConnectionPool(databasePath, defaultPoolSize)

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
import tinypool/sqlitePool #For convenience reasons, sqlitePool also exports std/db_sqlite since you'll need that either way

let databasePath = ":memory:"
let defaultPoolSize = 2
initConnectionPool(databasePath, defaultPoolSize)


let myCon: DbConn = borrowConnection()

myCon.exec(sql"""CREATE TABLE "auth_user" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "username" varchar(150) NOT NULL UNIQUE);""")

myCon.exec(sql"""INSERT INTO auth_user (username) VALUES ('henry');""")

let rows = myCon.getAllRows(sql"""SELECT * FROM auth_user WHERE username LIKE 'Henry';""")
assert rows.len() == 1
assert rows[0].username == "henry"

myCon.recycleConnection()

destroyConnectionPool()
```

## Initialization/Configuration and Destruction

In order for tinypool to work, it needs to be told how to connect to the desired database and how many connections it needs. In terms of how to connect to the database, this differs slightly between sqlite and postgres/mysql. As for how many connections, if you're uncertain, I'd recommend ~4 connections.

To initialize the pool e.g. on startup of your application, just call `initConnectionPool`.
To destroy the pool e.g. on shutdown of your application, just call `destroyConnectionPool`.

#### Initializing sqlite pool
For sqlite, it suffices to provide a path to the database file. The application then builds a proc to create connections to that database file itself.

```nim
import tinypool/sqlitePool #For convenience reasons, sqlitePool also exports std/db_sqlite since you'll need that either way

let databasePath = ":memory:"
let defaultPoolSize = 2
initConnectionPool(databasePath, defaultPoolSize)
```
 
#### Initializing postgres/mysql pools
For postgres and mysql it is required to provide a proc with that creates a database connection with this signature: `proc(): DbConn`.
tinypool will use that proc to create connections for the pool as needed.

```nim
import tinypool/postgresPool #For convenience reasons, postgresPool also exports std/db_postgres since you'll need that either way

proc createConnection(): DbConn = open("", "default", "1234", "host=localhost port=5432 dbname=default")
let defaultPoolSize = 2
initConnectionPool(createConnection, defaultPoolSize)
```

## burstMode

If more connections are needed than it has, the pool will temporarily go into "burst mode" and automatically refill with new batch of connections, the amount of which is determined by the `poolSize`.

While the pool is in burst mode it can hold an unlimited amount of connections.

While the pool is not in burst mode, any superfluous connection that is returned to it gets closed.

Burst mode ends after a specified duration (30 minutes), though that gets extended if the connections from the added batch are still needed.

## Enabling Logging
Tinypool logs a variety of messages, but does not supply its own Logger, so it will use whatever logger your application defines.
However, it is up to you whether you want to enable logging of tinypool or not.
It is not enabled by default.
In order to see tinypool's log messages you will have to supply the compilerflag `-d:enableTinyPoolLogging`.
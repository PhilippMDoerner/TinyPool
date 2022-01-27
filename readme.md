# TinyPool

Tinypool is a minimalistic sqlite connection pool with support for multi-threaded access.
It's essentially a global-variable `seq[DbConn]` that can be accessed in a thread-safe manner.

Your 2 main ways of interacting with it is either:

1. `borrowConnection` and `recycleConnection` OR
2. `withDbConn(someConnectionVariableName)`

## 1. borrowConnection and recycleConnection

```nim
import tinypool #For convenience reasons, tinypool also exports std/db_sqlite since you'll need that either way

let searchSQLStatement = sql"""
    SELECT *
    FROM my_fancy_table
    WHERE my_fancy_table.id = ?;
"""
let id = 5

let connection = borrowConnection()
var rows: seq[Row] = connection.getAllRows(
    searchSQLStatement,
    id
  )

connection.recycleConnection()
```

## 2. withDbConn

```nim
import tinypool #For convenience reasons, tinypool also exports std/db_sqlite since you'll need that either way

let searchSQLStatement = sql"""
    SELECT *
    FROM my_fancy_table
    WHERE my_fancy_table.id = ?;
"""
let id = 5

var rows: seq[Row]
withDbConn(connection):
  rows = connection.getAllRows(
    searchSQLStatement,
    id
  )
```

# Package

version       = "1.0.1"
author        = "PhilippMDoerner"
description   = "A minimalistic connection pooling package for sqlite"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.6.4"


# Tasks
task docs, "Write the package docs":
  exec "nim doc --verbosity:0 --warnings:off --project --index:on " &
    "--git.url:git@github.com:PhilippMDoerner/TinyPool.git" &
    "--git.commit:master " &
    "-o:docs/coreapi " &
    "src/tinypool.nim"

task testPostgresContainedCmd, "Runs the test suite":
  exec "nim c -r --mm:orc --deepcopy:on --threads:on --define:ndbPostgresOld tests/tPostgresPool.nim"

task testSqliteContainerCmd, "Runs the test suite":
  exec "nim c -r --mm:orc --deepcopy:on --threads:on tests/tSqlitePool.nim"

task testMysqlContainerCmd, "Runs the test suite":
  exec "nim c -r --mm:orc --deepcopy:on --threads:on tests/tMysqlPool.nim"

task postgresTests, "Run containerized postgres tests":
  echo staticExec "sudo docker image rm tinypool"
  exec "sudo docker-compose run --rm tests-postgres"

task sqliteTests, "Run containerized sqlite tests":
  echo staticExec "sudo docker image rm tinypool"
  exec "sudo docker-compose run --rm tests-sqlite"

task mysqlTests, "Run containerized mysql tests":
  echo staticExec "sudo docker image rm tinypool"
  exec "sudo docker-compose run --rm tests-mysql"

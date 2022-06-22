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
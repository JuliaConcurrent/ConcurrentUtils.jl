# ConcurrentUtils: Concurrent programming tools for Julia

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliaconcurrent.github.io/ConcurrentUtils.jl/dev/)
[![CI](https://github.com/JuliaConcurrent/ConcurrentUtils.jl/actions/workflows/test.yml/badge.svg)](https://github.com/JuliaConcurrent/ConcurrentUtils.jl/actions/workflows/test.yml)

ConcurrentUtils.jl provides high-level and low-level programming tools for concurrent
computing in Julia in order to complement the `Base.Threads` library.  The high-level APIs
include:

* [`Promise{T}`](https://juliaconcurrent.github.io/ConcurrentUtils.jl/dev/#ConcurrentUtils.Promise):
  a memory location that holds a value of type `T` that can be set once and retrieved
  asynchronously.
* [`@tasklet code`](https://juliaconcurrent.github.io/ConcurrentUtils.jl/dev/#ConcurrentUtils.@tasklet):
  a `Promise`-like memoized thunk.
* [`@once code`](https://juliaconcurrent.github.io/ConcurrentUtils.jl/dev/#ConcurrentUtils.@once):
  execute the `code` at most once.
* [`ReadWriteLock`](https://juliaconcurrent.github.io/ConcurrentUtils.jl/dev/#ConcurrentUtils.ReadWriteLock):
  a reader-writer lock.
* ... and more

See more in the [Documentation](https://juliaconcurrent.github.io/ConcurrentUtils.jl/dev/).

    read_write_locks() -> (rlock, wlock)

Return the read handle `rlock` and the write handle `wlock` of a read-write lock.

# Extended help

Supported operations:

* [`acquire(rlock)`](@ref acquire) (`lock`)
* [`try_acquire(rlock; [ntries::Integer])`](@ref try_acquire) (`trylock`): Not very
  efficient but lock-free.  Fail with `AcquiredByWriterError` or `TooManyTries`.
* [`release(rlock)`](@ref) (`unlock`)
* [`acquire(wlock)`](@ref acquire) (`lock`)
* [`try_acquire(wlock)`](@ref try_acquire) (`trylock`): Fail with `NotAcquirableError`.
* [`release(wlock)`](@ref) (`unlock`)

    read_write_lock() -> (rlock, wlock)

Return the read handle `rlock` and the write handle `wlock` of a read-write lock.

# Extended help

Supported operations:

* [`acquire(rlock)`](@ref acquire) (`lock`)
* [`try_race_acquire(rlock; [nspins], [ntries])`](@ref try_race_acquire) (`trylock`): Not
  very efficient but lock-free.  Fail with `TooManyTries`.
* [`release(rlock)`](@ref) (`unlock`)
* [`acquire(wlock)`](@ref acquire) (`lock`)
* [`try_race_acquire(wlock)`](@ref try_race_acquire) (`trylock`): Fail with `NotAcquirableError`.
* [`release(wlock)`](@ref) (`unlock`)

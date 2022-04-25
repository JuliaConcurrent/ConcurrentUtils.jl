    read_write_lock() -> (rlock, wlock)

Return the read handle `rlock` and the write handle `wlock` of a read-write lock.

# Extended help

Supported operations:

* `lock(rlock)`
* `trylock(rlock)` (not very efficient but lock-free)
* `unlock(rlock)`
* `lock(wlock)`
* `trylock(wlock)`
* `unlock(wlock)`

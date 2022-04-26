    lock_read(rwlock)
    lock_read(f, rwlock)

`lock_read(rwlock)` takes reader (shared) lock. It must be released with
[`unlock_read`](@ref).

The second method `lock_read(f, rwlock)` execute the function `f` without any arguments
after taking the reader lock and release it before returning.  `lock_read(f, rwlock)`
returns the result of `f()`.

See also: [`ReadWriteLock`](@ref)

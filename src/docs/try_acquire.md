    try_acquire(lock) -> Ok(nothing) or Err(reason)

Try to acquire `lock` and return `Ok(nothing)` on success.  Return an `Err` wrapping a value
explaining a `reason` of failure.

See the documentation of `typeof(lock)` for possible error types.

## Examples
```julia
julia> using ConcurrentUtils

julia> lock = NonreentrantCLHLock();

julia> try_acquire(lock)
Try.Ok: nothing

julia> try_acquire(lock)
Try.Err: NotAcquirableError()
```

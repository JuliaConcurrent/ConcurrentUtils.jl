    race_acquire(lock) -> isacquired::Bool

Try to acquire `lock` and return `true` on success and `false` on failure.

See also [`try_race_acquire`](@ref).

## Examples
```julia
julia> using ConcurrentUtils

julia> lock = NonreentrantCLHLock();

julia> race_acquire(lock)
true

julia> race_acquire(lock)
false
```

    acquire(lock)

Acquire a `lock`.  It is equivalent to `Base.lock(lock)` but it may support additional
keyword arguments.

See also [`release`](@ref) and [`try_race_acquire`](@ref).

# Extended help

## Examples
```julia
julia> using ConcurrentUtils

julia> lock = ReentrantCLHLock();

julia> acquire(lock);

julia> release(lock);
```

## On naming

ConcurrentUtils.jl uses `acquire`/`release` instead of `lock`/`unlock` so that:

1. Variable `lock` can be used.
2. Make it clear that `ConcurrentUtils.try_race_acquire(lock) -> result::Union{Ok,Err}` and
   `Base.trylock(lock) -> locked::Bool` have different return types.  In particular,
   `try_race_acquire` can report the reason why certain attempt have failed.

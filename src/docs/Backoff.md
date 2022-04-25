    Backoff(mindelay, maxdelay) -> backoff

Create a callable `backoff` where `backoff()` spin-wait some amount of times.

The number of maximum calls to [`spinloop`](@ref) starts at `mindelay` and exponentially
increases up to `maxdelay`.  `backoff()` returns the number of `spinloop` called.

`Backoff` uses an internal RNG and it does not consume the default task-local RNG.

# Extended help
## Examples

If `islocked` does not cause data races, `Backoff` can be used to implement a backoff lock.

```julia
julia> using ConcurrentUtils

julia> function trylock_with_backoff(lck; nspins = 1000, mindelay = 1, maxdelay = 1000)
           backoff = Backoff(mindelay, maxdelay)
           n = 0
           while true
               while islocked(lck)
                   spinloop()
                   n += 1
                   n > nspins && return false
               end
               trylock(lck) && return true
               n += backoff()
           end
       end;

julia> lck = ReentrantLock();

julia> trylock_with_backoff(lck)
true
```

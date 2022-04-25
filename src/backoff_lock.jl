# TODO: export this
mutable struct Backoff
    limit::Int
    @const maxdelay::Int
end

# Avoid introducing a function boundaries and move `backoff` to stack (or registers).
@inline function (backoff::Backoff)()
    limit = backoff.limit
    backoff.limit = min(backoff.maxdelay, 2limit)
    delay = rand(THREAD_LOCAL_RNG[], 1:limit)
    spinfor(delay)
    return delay
end

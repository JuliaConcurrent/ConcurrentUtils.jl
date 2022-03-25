    @tasklet code

Create an object that is a memoized version of `() -> code` but also acts like a `Promise`
that is not settable.

A `t = @tasklet code` supports: `t()`, `fetch(t)`, `wait(t)`, and [`try_fetch`](@ref).

# Examples

```julia
julia> using ConcurrentUtils

julia> t = @tasklet begin
           println("called")
           123
       end;

julia> try_fetch(t)
Try.Err: NotSetError()

julia> t()
called
123

julia> t()
123

julia> fetch(t)
123

julia> wait(t);
```

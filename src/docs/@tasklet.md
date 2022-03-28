    @tasklet code

Create an object that is a memoized version of `() -> code` but also acts like a `Promise`
that is not settable.

A `t = @tasklet code` supports: `t()`, `fetch(t)`, `wait(t)`, and [`try_race_fetch`](@ref).

# Extended help

## Examples

```julia
julia> using ConcurrentUtils

julia> t = @tasklet begin
           println("called")
           123
       end;

julia> try_race_fetch(t)
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

## Memory ordering

An event that retrieves or waits for a value from a tasklet `t` establishes a
happened-before edge from the events in `code`.  Invocations of the API that includes an
event that retrieves or waits for a value from a `promise` include:

* `fetch(t)`
* `wait(t)`
* `try_race_fetch(t)` that returns an `Ok` result.

## Supported operations

A tasklet `t = @tasklet code` supports the following operations:

* `t()`: Evaluate `code` if it hasn't been evaluated. Otherwise, equivalent to `fetch`.
* `fetch(t)`: Wait for other tasks to invoke `t()` and then return the result.
* `wait(t)`: Wait for other tasks to invoke `t()`.
* [`try_race_fetch`](@ref): Try to retrieve the result of `t()` if it is already called.

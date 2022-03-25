    @once code

Execute `code` at most once within the lifetime of the Julia process.  It evaluates to the
result of the first evaluation whenever the same location of the code is evaluated later.

Note that `code` does not have access to the local variables.

# Examples

```julia
julia> using ConcurrentUtils

julia> f() = @once Ref(123);

julia> f() isa Ref
true

julia> f()[]
123
```

`Ref(123)` is evaluated once and the identical `Ref` object is reused whenever `f` is called
in this Julia process:

```julia
julia> f() === f()
true
```

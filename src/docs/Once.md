    Once{T}(f = T)
    Once(f)

A concurrent object for lazily initializing an object of type `T`.

Given `O = Once{T}(f)`, invoking `O[]` evaluates `v = f()` if `f` has not been called via
`O[]` and return the value `v`.  Otherwise, `O[]` returns the value `v` returned from the
first invocation of `O[]`.

# Examples

```julia
julia> using ConcurrentUtils

julia> O = Once{Vector{Int}}(() -> zeros(Int, 3));

julia> v = O[]
3-element Vector{Int64}:
 0
 0
 0

julia> v === O[]
true
```

# Extended help

When used as in `Once{T}(f)`, the function `f` must always return a value of type `T`.  As
such, `T() isa T` must hold for type `T` used as in `Once{T}()`.

When used as in `Once(f)`, the function `f` must always return a value of concrete
consistent type.  If `Once` object is used as a global constant in a package, the type of
the value returned from `f` must not change for different `julia` processes for each stack
of Julia environment.  Currently, `Once(f)` also directly invokes `f()` to compute the
result type but this value is thrown away.  This is because `Once(f)` is assumed to be
called at the top-level of a package for lazily initializing a global state and serializing
the computed value in the precompile cache is not desired.

Known limitation: If `O[]` is evaluated for a global `O::Once{T}` during precompilation, the
resulting value is serialized into the precompile cache.

    ThreadLocalStorage{T}(factory)
    ThreadLocalStorage(factory)

Create a thread-local storage of type `T` created by `factory()`.

An instance `tls` of `ThreadLocalStorage` support the operation `x = tls[]` for obtaining an
object `x` of value `T`.

!!! warning
    Using this API is extremely tricky.  Arguably, it is not even well-defined when and how
    it can be used.

    Theoretically, it is safe to use this API if the programmer can ensure that, once a
    value `x = tls[]` is obtained, the code does not hit any yield points until there is no
    more access to `x`.  However, it is not possible to know if a certain operation is
    yield-free in general.

    Thus, this API currently exists primarily for helping migration of code written using
    `nthreads` and `threadid` in an ad-hoc manner.

An object of type `T` is allocated for each worker thread of the Julia runtime.  If `T` is
not given, `T = typeof(factory())` is used (i.e., `factory` is assumed to be type-stable).

# Extended help

## Examples
```julia
julia> using ConcurrentUtils

julia> tls = ThreadLocalStorage(Ref{Int});

julia> tls[] isa Ref{Int}
true

julia> tls[][] = 123;

julia> tls[][]
123
```

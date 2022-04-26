macro _const(ex)
    ex = esc(ex)
    if VERSION < v"1.8.0-DEV.1148"
        return ex
    else
        return Expr(:const, ex)
    end
end

const var"@const" = var"@_const"

#=
const Historic = if USE_HISTORIC
    Base.require(Base.PkgId(Base.UUID(0xe6ec0b50ef98488aa141280ae2eaf113), "Historic"))
else
    nothing
end

@static if Historic === nothing
    macro record(_...)
        nothing
    end
else
    Historic.@define Debug
    using .Debug: @record
end

"""
    @yield_unsafe expression

Document that `expression` must not yield to the Julia scheduler.

This macro is used purely for documentation.  The `expression` is evaluated
as-is.
"""
macro yield_unsafe(ex)
    esc(ex)
end
=#

function ConcurrentUtils.spinloop()
    GC.safepoint()
    ccall(:jl_cpu_pause, Cvoid, ())
end

function ConcurrentUtils.spinfor(nspins)
    for _ in oneto(nspins)
        spinloop()
    end
end

oneto(::Nothing) = ()
oneto(n) = Base.OneTo(n)

struct Infinity end
const ∞ = Infinity()
Base.:<(::Int, ::Infinity) = true

struct Forever end
Base.iterate(::Forever, _state = nothing) = (nothing, nothing)
Base.eltype(::Type{Forever}) = Nothing
Base.IteratorSize(::Type{Forever}) = Base.IsInfinite()

oneto(::Infinity) = Forever()

struct NegativeInfinity end
Base.:-(::Infinity) = NegativeInfinity()
Base.:<(::Int, ::NegativeInfinity) = false

fieldoffset_by_name(T, name) = fieldoffset(T, findfirst(==(name), fieldnames(T)))

_typeof(x) = typeof(x)
_typeof(::Type{T}) where {T} = Type{T}

pad7() = ntuple(_ -> 0, Val(7))

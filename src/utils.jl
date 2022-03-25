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

oneto(::Nothing) = ()
oneto(n) = Base.OneTo(n)

fieldoffset_by_name(T, name) = fieldoffset(T, findfirst(==(name), fieldnames(T)))

function unwrap_or_else(f, result)
    if Try.iserr(result)
        f(Try.unwrap_err(result))
    else
        Try.unwrap(result)
    end
end

macro return_unwrap(ex)
    quote
        result = $(esc(ex))
        if Try.iserr(result)
            result
        else
            return Try.unwrap(result)
        end
    end
end

abstract type AbstractTasklet{T} end

struct Tasklet{T} <: AbstractTasklet{T}
    thunk::OpaqueClosure{Tuple{},T}
    promise::Promise{T}
end

Tasklet(thunk::OpaqueClosure{Tuple{},T}) where {T} = Tasklet{T}(thunk, Promise{T}())

struct TypedTasklet{T,Thunk} <: AbstractTasklet{T}
    thunk::Thunk
    promise::Promise{T}
end

TypedTasklet{T}(thunk::Thunk) where {T,Thunk} = TypedTasklet{T,Thunk}(thunk, Promise{T}())

macro tasklet(thunk)
    thunk = Expr(:block, __source__, thunk)
    ex = :($Tasklet($Base.Experimental.@opaque () -> $thunk))
    return esc(ex)
end

(tasklet::AbstractTasklet)() = race_put_with!(tasklet.thunk, tasklet.promise)
Base.fetch(tasklet::AbstractTasklet) = fetch(tasklet.promise)
Base.wait(tasklet::AbstractTasklet) = wait(tasklet.promise)
ConcurrentUtils.try_race_fetch(tasklet::AbstractTasklet) = try_race_fetch(tasklet.promise)

macro once(ex)
    @gensym ONCETASK thunk
    ex = Expr(:block, __source__, ex)
    toplevel = quote
        const $ONCETASK = let $thunk = () -> $ex
            $TypedTasklet{$typeof($thunk())}($thunk)
            # Using explicitly typed `TypedTasklet` since an opaque closure cannot be
            # serialized.
        end
    end
    Base.eval(__module__, Expr(:toplevel, __source__, toplevel.args...))
    return esc(:($ONCETASK()))
end

abstract type AbstractTasklet{T} end

struct Tasklet{T} <: AbstractTasklet{T}
    thunk::OpaqueClosure{Tuple{},T}
    promise::Promise{T}
end

Tasklet(thunk::OpaqueClosure{Tuple{},T}) where {T} = Tasklet{T}(thunk, Promise{T}())

#=
struct TypedTasklet{T,Thunk} <: AbstractTasklet{T}
    thunk::Thunk
    promise::Promise{T}
end

TypedTasklet{T}(thunk::Thunk) where {T,Thunk} = TypedTasklet{T,Thunk}(thunk, Promise{T}())
=#

macro tasklet(thunk)
    thunk = Expr(:block, __source__, thunk)
    ex = :($Tasklet($Base.Experimental.@opaque () -> $thunk))
    return esc(ex)
end

(tasklet::AbstractTasklet)() = race_put_with!(tasklet.thunk, tasklet.promise)
Base.fetch(tasklet::AbstractTasklet) = fetch(tasklet.promise)
Base.wait(tasklet::AbstractTasklet) = wait(tasklet.promise)
ConcurrentUtils.try_race_fetch(tasklet::AbstractTasklet) = try_race_fetch(tasklet.promise)

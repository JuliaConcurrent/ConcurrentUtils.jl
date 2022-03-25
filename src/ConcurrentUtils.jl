baremodule ConcurrentUtils

export
    # Macros
    @once,
    @tasklet,
    # Constructors
    NonreentrantCLHLock,
    NotAcquirableError,
    NotSetError,
    OccupiedError,
    Promise,
    Promise,
    ReentrantCLHLock,
    ThreadLocalStorage

export Try, Err, Ok
using Try: Try, Ok, Err

module InternalPrelude
include("prelude.jl")
end  # module InternalPrelude

InternalPrelude.@exported_function fetch_or!
InternalPrelude.@exported_function try_fetch
InternalPrelude.@exported_function try_fetch_or!
InternalPrelude.@exported_function try_put!

macro once end
macro tasklet end

struct OccupiedError{T} <: InternalPrelude.Exception
    value::T
end

struct NotSetError <: InternalPrelude.Exception end
struct NotAcquirableError <: InternalPrelude.Exception end

InternalPrelude.@exported_function acquire
InternalPrelude.@exported_function release
InternalPrelude.@exported_function try_acquire
# function try_acquire_then end
InternalPrelude.@exported_function acquire_then

#=
InternalPrelude.@exported_function isacquirable
InternalPrelude.@exported_function isacquirable_read
InternalPrelude.@exported_function isacquirable_write
=#

InternalPrelude.@exported_function acquire_read
InternalPrelude.@exported_function acquire_read_then
InternalPrelude.@exported_function acquire_write
InternalPrelude.@exported_function acquire_write_then
InternalPrelude.@exported_function read_write_locks
InternalPrelude.@exported_function release_read
InternalPrelude.@exported_function release_write
InternalPrelude.@exported_function try_acquire_read
InternalPrelude.@exported_function try_acquire_write

# Maybe:
# * @static_thread_local_storage
# * Copy AsyncFinalizers.SingleReaderDualBag?

"""
    Internal

Internal module that contains main implementations.
"""
module Internal

using Core.Intrinsics: atomic_fence
using Core: OpaqueClosure

using Try: Try, Ok, Err, @?

import ..ConcurrentUtils: @once, @tasklet
using ..ConcurrentUtils:
    ConcurrentUtils,
    NotAcquirableError,
    NotSetError,
    OccupiedError,
    acquire,
    acquire_read,
    acquire_write,
    fetch_or!,
    release,
    release_read,
    release_write,
    try_acquire_read,
    try_acquire_write,
    try_fetch,
    try_fetch_or!,
    try_put!

#=
if isfile(joinpath(@__DIR__, "config.jl"))
    include("config.jl")
else
    include("default-config.jl")
end
=#

include("utils.jl")
include("promise.jl")
include("tasklet.jl")
include("thread_local_storage.jl")

# Locks
include("lock_interface.jl")
include("clh_lock.jl")
include("read_write_lock.jl")

for _ = 1:2
    nothing
end

end  # module Internal

const Promise = Internal.Promise
const ThreadLocalStorage = Internal.ThreadLocalStorage
const ReentrantCLHLock = Internal.ReentrantCLHLock
const NonreentrantCLHLock = Internal.NonreentrantCLHLock

end  # baremodule ConcurrentUtils

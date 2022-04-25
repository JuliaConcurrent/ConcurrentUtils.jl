baremodule ConcurrentUtils

export
    # Macros
    @once,
    @tasklet,
    # Constructors
    Guard,
    NonreentrantBackoffSpinLock,
    NonreentrantCLHLock,
    NotAcquirableError,
    NotSetError,
    OccupiedError,
    Promise,
    ReadWriteGuard,
    ReentrantBackoffSpinLock,
    ReentrantCLHLock,
    TaskObliviousLock,
    ThreadLocalStorage,
    TooManyTries

export Try, Err, Ok
using Try: Try, Ok, Err

module InternalPrelude
include("prelude.jl")
end  # module InternalPrelude

InternalPrelude.@exported_function race_fetch_or!
InternalPrelude.@exported_function try_race_fetch
InternalPrelude.@exported_function try_race_fetch_or!
InternalPrelude.@exported_function try_race_put!

macro once end
macro tasklet end

struct OccupiedError{T} <: InternalPrelude.Exception
    value::T
end

struct NotSetError <: InternalPrelude.Exception end
struct NotAcquirableError <: InternalPrelude.Exception end
struct TooManyTries <: InternalPrelude.Exception
    nspins::Int
    ntries::Int
end

InternalPrelude.@exported_function acquire
InternalPrelude.@exported_function release
InternalPrelude.@exported_function race_acquire
InternalPrelude.@exported_function try_race_acquire
# function try_race_acquire_then end
InternalPrelude.@exported_function acquire_then
InternalPrelude.@exported_function lock_supports_nspins

#=
InternalPrelude.@exported_function isacquirable
InternalPrelude.@exported_function isacquirable_read
=#

InternalPrelude.@exported_function acquire_read
InternalPrelude.@exported_function acquire_read_then
InternalPrelude.@exported_function read_write_lock
InternalPrelude.@exported_function release_read
InternalPrelude.@exported_function try_race_acquire_read

abstract type AbstractGuard end
abstract type AbstractReadWriteGuard end
# Should abstract types have `Data` as a parameter? But maybe some implementations may want
# to provide a read-only wrapper type?

struct GenericGuard{Lock,Data} <: AbstractGuard
    lock::Lock
    data::Data
    GenericGuard(lock::Lock, data::Data) where {Lock,Data} = new{Lock,Data}(lock, data)
end

struct GenericReadWriteGuard{Lock,Data} <: AbstractReadWriteGuard
    lock::Lock
    data::Data
    GenericReadWriteGuard(lock::Lock, data::Data) where {Lock,Data} =
        new{Lock,Data}(lock, data)
end

InternalPrelude.@exported_function guardwith
InternalPrelude.@exported_function guarding
InternalPrelude.@exported_function guarding_read
# InternalPrelude.@exported_function read_write_guard

InternalPrelude.@exported_function unsafe_takestorages!

InternalPrelude.@exported_function spinloop
InternalPrelude.@exported_function spinfor

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
using Random: Xoshiro

import UnsafeAtomics: UnsafeAtomics, acq_rel
using ExternalDocstrings: @define_docstrings
using Try: Try, Ok, Err, @?

import ..ConcurrentUtils: @once, @tasklet
using ..ConcurrentUtils:
    AbstractGuard,
    AbstractReadWriteGuard,
    ConcurrentUtils,
    GenericGuard,
    GenericReadWriteGuard,
    NotAcquirableError,
    NotSetError,
    OccupiedError,
    TooManyTries,
    acquire,
    acquire_read,
    acquire_read_then,
    race_acquire,
    race_fetch_or!,
    release,
    release_read,
    spinfor,
    spinloop,
    try_race_acquire,
    try_race_acquire_read,
    try_race_fetch,
    try_race_fetch_or!,
    try_race_put!

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
include("backoff_lock.jl")
include("clh_lock.jl")
include("read_write_lock.jl")
include("guards.jl")

end  # module Internal

const Promise = Internal.Promise
const ThreadLocalStorage = Internal.ThreadLocalStorage
const ReentrantBackoffSpinLock = Internal.ReentrantBackoffSpinLock
const NonreentrantBackoffSpinLock = Internal.NonreentrantBackoffSpinLock
const ReentrantCLHLock = Internal.ReentrantCLHLock
const NonreentrantCLHLock = Internal.NonreentrantCLHLock
const TaskObliviousLock = NonreentrantCLHLock

const Guard = Internal.Guard
const ReadWriteGuard = Internal.ReadWriteGuard

Internal.@define_docstrings

end  # baremodule ConcurrentUtils

baremodule ConcurrentUtils

export
    # Macros
    @tasklet,
    # Constructors
    Backoff,
    Guard,
    NotSetError,
    OccupiedError,
    Once,
    Promise,
    ReadWriteGuard,
    ReadWriteLock,
    ThreadLocalStorage

export Try, Err, Ok
using Try: Try, Ok, Err

module InternalPrelude
include("prelude.jl")
end  # module InternalPrelude

InternalPrelude.@exported_function race_put!
InternalPrelude.@exported_function race_put_with!
InternalPrelude.@exported_function try_race_fetch
InternalPrelude.@exported_function try_race_put!
InternalPrelude.@exported_function try_race_put_with!

macro tasklet end

struct OccupiedError{T} <: InternalPrelude.Exception
    value::T
end

struct NotSetError <: InternalPrelude.Exception end

#=
InternalPrelude.@exported_function isacquirable
InternalPrelude.@exported_function isacquirable_read
=#

InternalPrelude.@exported_function trylock_read
InternalPrelude.@exported_function lock_read
InternalPrelude.@exported_function unlock_read

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

import ..ConcurrentUtils: @tasklet
using ..ConcurrentUtils:
    AbstractGuard,
    AbstractReadWriteGuard,
    ConcurrentUtils,
    GenericGuard,
    GenericReadWriteGuard,
    NotSetError,
    OccupiedError,
    lock_read,
    race_put!,
    race_put_with!,
    spinfor,
    spinloop,
    try_race_fetch,
    try_race_put!,
    try_race_put_with!,
    trylock_read,
    unlock_read

#=
if isfile(joinpath(@__DIR__, "config.jl"))
    include("config.jl")
else
    include("default-config.jl")
end
=#

include("utils.jl")
include("promise.jl")
include("once.jl")
include("tasklet.jl")
include("thread_local_storage.jl")

# Locks
include("read_write_lock.jl")
include("guards.jl")
include("backoff.jl")

end  # module Internal

const Promise = Internal.Promise
const Once = Internal.Once
const ThreadLocalStorage = Internal.ThreadLocalStorage
const ReadWriteLock = Internal.ReadWriteLock
const Backoff = Internal.Backoff

const Guard = Internal.Guard
const ReadWriteGuard = Internal.ReadWriteGuard

Internal.@define_docstrings

end  # baremodule ConcurrentUtils

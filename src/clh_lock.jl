struct IsLocked end

mutable struct LockQueueNode
    @atomic state::Union{IsLocked,Task,Nothing}
    _pad::NTuple{7,Int}

    LockQueueNode(state) = new(state)
end

@inline _islocked(node::LockQueueNode) = (@atomic :monotonic node.state) isa IsLocked

# TODO: Compare it with MCSLock
abstract type CLHLock <: Lockable end

mutable struct NonreentrantCLHLock <: CLHLock
    # TODO: node caching
    @atomic tail::LockQueueNode
    @const _pad::NTuple{7,Int}
    current::LockQueueNode
end

const DUMMY_NODE = LockQueueNode(nothing)

NonreentrantCLHLock() =
    NonreentrantCLHLock(LockQueueNode(nothing), ntuple(_ -> 0, Val(7)), DUMMY_NODE)

mutable struct ReentrantCLHLock <: CLHLock
    # TODO: node caching
    @atomic tail::LockQueueNode
    @const _pad::NTuple{7,Int}
    current::LockQueueNode
    @atomic owner::Union{Nothing,Task}
    count::Int
end

ReentrantCLHLock() =
    ReentrantCLHLock(LockQueueNode(nothing), ntuple(_ -> 0, Val(7)), DUMMY_NODE, nothing, 0)

function ConcurrentUtils.try_acquire(lock::CLHLock)
    pred = @atomic :monotonic lock.tail
    if !_islocked(pred)
        node = LockQueueNode(IsLocked())
        _, ok = @atomicreplace(:acquire_release, :acquire, lock.tail, pred => node)
        if ok
            return Ok(nothing)
        end
    end
    return Err(NotAcquirableError())
end

function ConcurrentUtils.acquire(lock::CLHLock; nspins = nothing)
    if lock isa ReentrantCLHLock
        if (@atomic :monotonic lock.owner) === current_task()
            lock.count += 1
            return
        end
    end

    node = LockQueueNode(IsLocked())
    # TODO: do we need acquire for `lock.tail`?
    pred = @atomicswap :acquire_release lock.tail = node
    if !_islocked(pred)
        atomic_fence(:acquire)
        # Main.@tlc notlocked
        @goto locked
    end
    for _ in oneto(nspins)
        if !_islocked(pred)
            atomic_fence(:acquire)
            # Main.@tlc spinlock
            @goto locked
        end
        spinloop()
    end

    task = current_task()
    # TODO: do we need acquire for `pred.state`?
    state, ok = @atomicreplace(:acquire_release, :acquire, pred.state, IsLocked() => task)
    if ok
        @assert state isa IsLocked
        wait()
        @assert pred.state === task
        # @atomic :monotonic pred.state = nothing  # if reusing
    else
        @assert state === nothing
    end
    # Main.@tlc waited

    @label locked
    if lock isa ReentrantCLHLock
        @atomic :monotonic lock.owner = current_task()
        lock.count = 1
    end
    lock.current = node
    return
end

function ConcurrentUtils.release(lock::CLHLock)
    if lock isa ReentrantCLHLock
        @assert (@atomic :monotonic lock.owner) === current_task()
        if (lock.count -= 1) > 0
            return
        end
        @atomic :monotonic lock.owner = nothing
    end
    node = lock.current
    state, ok = @atomicreplace(
        :acquire_release,
        :acquire,
        node.state,
        IsLocked() => nothing,  # try to unlock the node
    )
    if !ok
        # The waiter is already sleeping. Wake it up.
        task = state::Task
        schedule(task)
    end
    return
end

module ConcurrentUtilsTests

include("utils.jl")

include("test_promise.jl")
include("test_tasklet.jl")
include("test_thread_local_storage.jl")

# Locks
include("test_locks.jl")
include("test_read_write_lock.jl")

end  # module ConcurrentUtilsTests

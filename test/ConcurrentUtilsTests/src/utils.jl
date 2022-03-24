module Utils

using ConcurrentUtils

function poll_until(f)
    for _ in 1:1000
        f() && return true
        sleep(0.01)
    end
    return false
end

# 1 tick is about 30 ns
function unfair_sleep(nticks)
    for _ in 1:nticks
        spinloop()
    end
end

end  # module

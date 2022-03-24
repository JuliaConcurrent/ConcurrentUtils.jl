module TestBenchmarks

using Test
using ConcurrentUtilsBenchmarks: clear, setup_smoke

function test_smoke()
    try
        local suite
        @test (suite = setup_smoke()) isa Any
        @test run(suite) isa Any
    finally
        clear()
    end
end

end  # module

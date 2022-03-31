module TestDoctest

using ConcurrentUtils
using Documenter

test() = doctest(ConcurrentUtils; manual = false)

end  # module

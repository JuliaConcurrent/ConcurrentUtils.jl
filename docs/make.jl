using Documenter
using ConcurrentUtils

makedocs(
    sitename = "ConcurrentUtils",
    format = Documenter.HTML(),
    modules = [ConcurrentUtils],
    # Ref:
    # https://juliadocs.github.io/Documenter.jl/stable/lib/public/#Documenter.makedocs
)

deploydocs(
    repo = "JuliaConcurrent/ConcurrentUtils.jl",
    devbranch = "main",
    push_preview = true,
    # Ref:
    # https://juliadocs.github.io/Documenter.jl/stable/lib/public/#Documenter.deploydocs
)

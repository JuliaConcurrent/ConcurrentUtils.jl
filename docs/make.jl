using Documenter
using ConcurrentUtils

makedocs(
    sitename = "ConcurrentUtils",
    format = Documenter.HTML(),
    modules = [ConcurrentUtils],
    # Ref:
    # https://juliadocs.github.io/Documenter.jl/stable/lib/public/#Documenter.makedocs
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#

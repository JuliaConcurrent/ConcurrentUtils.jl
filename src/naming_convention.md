# Naming convention

Following the [naming convention style guide of `Base`][base-naming-convention],
ConcurrentUtils.jl uses underscore `_` to separate underlying concepts.

[base-naming-convention]: https://docs.julialang.org/en/v1/manual/style-guide/#Use-naming-conventions-consistent-with-Julia-base/

* `try_` (prefix): Use Try.jl-based error handling
* `_or` (suffix): Run a callback upon some kind of "failure"
* `race`: A name "modifier" for a racy variant.

Common verbs that appear as a primitive concept:

* `put`
* `fetch`
* `lock`
* `unlock`

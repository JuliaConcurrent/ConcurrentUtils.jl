# ConcurrentUtils.jl

## Promise

```@eval
using DocumentationOverview
using ConcurrentUtils
DocumentationOverview.table_md(
    :[
        Promise,
        try_fetch,
        try_fetch_or!,
        fetch_or!,
        try_put!,
    ],
    namespace = ConcurrentUtils,
    signature = :name,
)
```

```@docs
Promise
try_fetch
try_fetch_or!
fetch_or!
try_put!
```

## Promise-like interfaces

```@eval
using DocumentationOverview
using ConcurrentUtils
DocumentationOverview.table_md(
    :[
        var"@tasklet",
        var"@once",
    ],
    namespace = ConcurrentUtils,
    signature = :name,
)
```

```@docs
@tasklet
@once
```

## Locks

```@eval
using DocumentationOverview
using ConcurrentUtils
DocumentationOverview.table_md(
    :[
        ReentrantCLHLock,
        NonreentrantCLHLock,
        TaskObliviousLock,
        read_write_locks,
        acquire,
        release,
        try_acquire,
        acquire_then,
    ],
    namespace = ConcurrentUtils,
    signature = :name,
)
```

```@docs
ReentrantCLHLock
NonreentrantCLHLock
TaskObliviousLock
read_write_locks
acquire
release
try_acquire
acquire_then
```

## Low-level interfaces

```@eval
using DocumentationOverview
using ConcurrentUtils
DocumentationOverview.table_md(
    :[
        ThreadLocalStorage,
        spinloop,
    ],
    namespace = ConcurrentUtils,
    signature = :name,
)
```

```@docs
ThreadLocalStorage
spinloop
```

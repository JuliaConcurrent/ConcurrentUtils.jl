# ConcurrentUtils.jl

## Promise

```@eval
using DocumentationOverview
using ConcurrentUtils
DocumentationOverview.table_md(
    :[
        Promise,
        try_race_fetch,
        try_race_fetch_or!,
        race_fetch_or!,
        try_race_put!,
    ],
    namespace = ConcurrentUtils,
    signature = :name,
)
```

```@docs
Promise
try_race_fetch
try_race_fetch_or!
race_fetch_or!
try_race_put!
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

## Read-write Lock

```@eval
using DocumentationOverview
using ConcurrentUtils
DocumentationOverview.table_md(
    :[
        ReadWriteLock,
        lock_read,
        unlock_read,
        trylock_read,
        read_write_lock,
    ],
    namespace = ConcurrentUtils,
    signature = :name,
)
```

```@docs
ReadWriteLock
lock_read
unlock_read
trylock_read
read_write_lock
```

## Guards

```@eval
using DocumentationOverview
using ConcurrentUtils
DocumentationOverview.table_md(
    :[
        Guard,
        ReadWriteGuard,
        guarding,
        guarding_read,
    ],
    namespace = ConcurrentUtils,
    signature = :name,
)
```

```@docs
Guard
ReadWriteGuard
guarding
guarding_read
```

## Low-level interfaces

```@eval
using DocumentationOverview
using ConcurrentUtils
DocumentationOverview.table_md(
    :[
        ThreadLocalStorage,
        Backoff,
        spinloop,
    ],
    namespace = ConcurrentUtils,
    signature = :name,
)
```

```@docs
ThreadLocalStorage
Backoff
spinloop
```

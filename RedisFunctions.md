### [Redis Functions](https://redis.io/docs/latest/develop/programmability/functions-intro/)


#### Prologue 


#### I. [Redis programmability](https://redis.io/docs/latest/develop/programmability/) (TL;DR)
> Extending Redis with Lua and Redis Functions

> Redis provides a programming interface that lets you execute custom scripts on the server itself. In Redis 7 and beyond, you can use [Redis Functions](https://redis.io/docs/latest/develop/programmability/functions-intro/) to manage and run your scripts. In Redis 6.2 and below, you use [Lua scripting with the EVAL command](https://redis.io/docs/latest/develop/programmability/eval-intro/) to program the server.

**Background** 

> Redis is, by [definition](https://github.com/redis/redis/blob/unstable/MANIFESTO#L7), a *"domain-specific language for abstract data types"*. The language that Redis speaks consists of its [commands](https://redis.io/docs/latest/commands/). Most the commands specialize at manipulating core [data types](https://redis.io/docs/latest/develop/data-types/) in different ways. In many cases, these commands provide all the functionality that a developer requires for managing application data in Redis.

> The term **programmability** in Redis means having the ability to execute arbitrary user-defined logic by the server. We refer to such pieces of logic as **scripts**. In our case, scripts enable processing the data where it lives, a.k.a *data locality*. Furthermore, the responsible embedding of programmatic workflows in the Redis server can help in reducing network traffic and improving overall performance. Developers can use this capability for implementing robust, application-specific APIs. Such APIs can encapsulate business logic and maintain a data model across multiple keys and different data structures.

> User scripts are executed in Redis by an embedded, sandboxed scripting engine. Presently, Redis supports a single scripting engine, the [Lua 5.1](https://www.lua.org/) interpreter.

> Please refer to the [Redis Lua API Reference](https://redis.io/docs/latest/develop/programmability/lua-api/) page for complete documentation.

**Running scripts**

> Redis provides two means for running scripts.

> Firstly, and ever since Redis 2.6.0, the [EVAL](https://redis.io/docs/latest/commands/eval/) command enables running server-side scripts. Eval scripts provide a quick and straightforward way to have Redis run your scripts ad-hoc. However, using them means that the scripted logic is a part of your application (not an extension of the Redis server). Every applicative instance that runs a script must have the script's source code readily available for loading at any time. That is because scripts are only cached by the server and are volatile. As your application grows, this approach can become harder to develop and maintain.

> Secondly, added in v7.0, Redis Functions are essentially scripts that are first-class database elements. As such, functions decouple scripting from application logic and enable independent development, testing, and deployment of scripts. To use functions, they need to be loaded first, and then they are available for use by all connected clients. In this case, loading a function to the database becomes an administrative deployment task (such as loading a Redis module, for example), which separates the script from the application.

> Please refer to the following pages for more information:

- [Redis Eval Scripts](https://redis.io/docs/latest/develop/programmability/eval-intro/)
- [Redis Functions](https://redis.io/docs/latest/develop/programmability/functions-intro/)

> When running a script or a function, Redis guarantees its atomic execution. The script's execution blocks all server activities during its entire time, similarly to the semantics of [transactions](https://redis.io/docs/latest/develop/using-commands/transactions/). These semantics mean that all of the script's effects either have yet to happen or had already happened. The blocking semantics of an executed script apply to all connected clients at all times.

> Note that the potential downside of this blocking approach is that executing slow scripts is not a good idea. It is not hard to create fast scripts because scripting's overhead is very low. However, if you intend to use a slow script in your application, be aware that all other clients are blocked and can't execute any command while it is running.

**Read-only scripts**

> A read-only script is a script that only executes commands that don't modify any keys within Redis. Read-only scripts can be executed either by adding the no-writes [flag](https://redis.io/docs/latest/develop/programmability/lua-api/#script_flags) to the script or by executing the script with one of the read-only script command variants: [EVAL_RO](https://redis.io/docs/latest/commands/eval_ro/), [EVALSHA_RO](https://redis.io/docs/latest/commands/evalsha_ro/), or [FCALL_RO](https://redis.io/docs/latest/commands/fcall_ro/). They have the following properties:

- They can always be executed on replicas.
- They can always be killed by the [SCRIPT KILL](https://redis.io/docs/latest/commands/script-kill/) command.
- They never fail with OOM error when redis is over the memory limit.
- They are not blocked during write pauses, such as those that occur during coordinated failovers.
- They cannot execute any command that may modify the data set.
- Currently [PUBLISH](https://redis.io/docs/latest/commands/publish/), [SPUBLISH](https://redis.io/docs/latest/commands/spublish/) and [PFCOUNT](https://redis.io/docs/latest/commands/pfcount/) are also considered write commands in scripts, because they could attempt to propagate commands to replicas and AOF file.

> In addition to the benefits provided by all read-only scripts, the read-only script commands have the following advantages:

- They can be used to configure an ACL user to only be able to execute read-only scripts.
- Many clients also better support routing the read-only script commands to replicas for applications that want to use replicas for read scaling.

Read-only script history 

> Read-only scripts and read-only script commands were introduced in Redis 7.0

- Before Redis 7.0.1 [PUBLISH](https://redis.io/docs/latest/commands/publish/), [SPUBLISH](https://redis.io/docs/latest/commands/spublish/) and [PFCOUNT](https://redis.io/docs/latest/commands/pfcount/) were not considered write commands in scripts
- Before Redis 7.0.1 the no-writes [flag](https://redis.io/docs/latest/develop/programmability/lua-api/#script_flags) did not imply allow-oom
- Before Redis 7.0.1 the no-writes [flag](https://redis.io/docs/latest/develop/programmability/lua-api/#script_flags) did not permit the script to run during write pauses.

> The recommended approach is to use the standard scripting commands with the no-writes flag unless you need one of the previously mentioned features.

**Sandboxed script context** 

> Redis places the engine that executes user scripts inside a sandbox. The sandbox attempts to prevent accidental misuse and reduce potential threats from the server's environment.

> Scripts should never try to access the Redis server's underlying host systems, such as the file system, network, or attempt to perform any other system call other than those supported by the API.

> Scripts should operate solely on data stored in Redis and data provided as arguments to their execution.

**Maximum execution time**

> Scripts are subject to a maximum execution time (set by default to five seconds). This default timeout is enormous since a script usually runs in less than a millisecond. The limit is in place to handle accidental infinite loops created during development.

> It is possible to modify the maximum time a script can be executed with millisecond precision, either via redis.conf or by using the [CONFIG SET](https://redis.io/docs/latest/commands/config-set/) command. The configuration parameter affecting max execution time is called busy-reply-threshold.

> When a script reaches the timeout threshold, it isn't terminated by Redis automatically. Doing so would violate the contract between Redis and the scripting engine that ensures that scripts are atomic. Interrupting the execution of a script has the potential of leaving the dataset with half-written changes.

> Therefore, when a script executes longer than the configured timeout, the following happens:

- Redis logs that a script is running for too long.
- It starts accepting commands again from other clients but will reply with a BUSY error to all the clients sending normal commands. The only commands allowed in this state are [SCRIPT KILL](https://redis.io/docs/latest/commands/script-kill/), [FUNCTION KILL](https://redis.io/docs/latest/commands/function-kill/), and SHUTDOWN NOSAVE.
- It is possible to terminate a script that only executes read-only commands using the [SCRIPT KILL](https://redis.io/docs/latest/commands/script-kill/) and [FUNCTION KILL](https://redis.io/docs/latest/commands/function-kill/) commands. These commands do not violate the scripting semantic as no data was written to the dataset by the script yet.
- If the script had already performed even a single write operation, the only command allowed is SHUTDOWN NOSAVE that stops the server without saving the current data set on disk (basically, the server is aborted).

[Redis functions](https://redis.io/docs/latest/develop/programmability/functions-intro/)

Scripting with Redis 7 and beyond

[Scripting with Lua](https://redis.io/docs/latest/develop/programmability/eval-intro/)

Executing Lua in Redis

[Redis Lua API reference](https://redis.io/docs/latest/develop/programmability/lua-api/)

Executing Lua in Redis

[Debugging Lua scripts in Redis](https://redis.io/docs/latest/develop/programmability/lua-debugging/)

How to use the built-in Lua debugger


#### II. [Redis Functions](https://redis.io/docs/latest/develop/programmability/functions-intro/)
> Scripting with Redis 7 and beyond

> Redis Functions is an API for managing code to be executed on the server. This feature, which became available in Redis 7, supersedes the use of [EVAL](https://redis.io/docs/latest/develop/programmability/eval-intro/) in prior versions of Redis.

**Prologue (or, what's wrong with Eval Scripts?)**

Prior versions of Redis made scripting available only via the [EVAL](https://redis.io/docs/latest/commands/eval/) command, which allows a Lua script to be sent for execution by the server. The core use cases for [Eval Scripts](https://redis.io/docs/latest/develop/programmability/eval-intro/) is executing part of your application logic inside Redis, efficiently and atomically. Such script can perform conditional updates across multiple keys, possibly combining several different data types.

Using [EVAL](https://redis.io/docs/latest/commands/eval/) requires that the application sends the entire script for execution every time. Because this results in network and script compilation overheads, Redis provides an optimization in the form of the [EVALSHA](https://redis.io/docs/latest/commands/evalsha/) command. By first calling [SCRIPT LOAD](https://redis.io/docs/latest/commands/script-load/) to obtain the script's SHA1, the application can invoke it repeatedly afterward with its digest alone.

By design, Redis only caches the loaded scripts. That means that the script cache can become lost at any time, such as after calling [SCRIPT FLUSH](https://redis.io/docs/latest/commands/script-flush/), after restarting the server, or when failing over to a replica. The application is responsible for reloading scripts during runtime if any are missing. The underlying assumption is that scripts are a part of the application and not maintained by the Redis server.

This approach suits many light-weight scripting use cases, but introduces several difficulties once an application becomes complex and relies more heavily on scripting, namely:

1. All client application instances must maintain a copy of all scripts. That means having some mechanism that applies script updates to all of the application's instances.
2. Calling cached scripts within the context of a [transaction](https://redis.io/docs/latest/develop/using-commands/transactions/) increases the probability of the transaction failing because of a missing script. Being more likely to fail makes using cached scripts as building blocks of workflows less attractive.
3. SHA1 digests are meaningless, making debugging the system extremely hard (e.g., in a [MONITOR](https://redis.io/docs/latest/commands/monitor/) session).
4. When used naively, [EVAL](https://redis.io/docs/latest/commands/eval/) promotes an anti-pattern in which scripts the client application renders verbatim scripts instead of responsibly using the [KEYS and ARGV Lua APIs](https://redis.io/docs/latest/develop/programmability/lua-api/#runtime-globals).
5. Because they are ephemeral, a script can't call another script. This makes sharing and reusing code between scripts nearly impossible, short of client-side preprocessing (see the first point).

> To address these needs while avoiding breaking changes to already-established and well-liked ephemeral scripts, Redis v7.0 introduces Redis Functions.

**What are Redis Functions?**

> Redis functions are an evolutionary step from ephemeral scripting.

> Functions provide the same core functionality as scripts but are first-class software artifacts of the database. Redis manages functions as an integral part of the database and ensures their availability via data persistence and replication. Because functions are part of the database and therefore declared before use, applications aren't required to load them during runtime nor risk aborted transactions. An application that uses functions depends only on their APIs rather than on the embedded script logic in the database.

> Whereas ephemeral scripts are considered a part of the application's domain, functions extend the database server itself with user-provided logic. They can be used to expose a richer API composed of core Redis commands, similar to modules, developed once, loaded at startup, and used repeatedly by various applications / clients. Every function has a unique user-defined name, making it much easier to call and trace its execution.

> The design of Redis Functions also attempts to demarcate between the programming language used for writing functions and their management by the server. Lua, the only language interpreter that Redis presently support as an embedded execution engine, is meant to be simple and easy to learn. However, the choice of Lua as a language still presents many Redis users with a challenge.

> The Redis Functions feature makes no assumptions about the implementation's language. An execution engine that is part of the definition of the function handles running it. An engine can theoretically execute functions in any language as long as it respects several rules (such as the ability to terminate an executing function).

> Presently, as noted above, Redis ships with a single embedded [Lua 5.1](https://redis.io/docs/latest/develop/programmability/lua-api/) engine. There are plans to support additional engines in the future. Redis functions can use all of Lua's available capabilities to ephemeral scripts, with the only exception being the [Redis Lua scripts debugger](https://redis.io/docs/latest/develop/programmability/lua-debugging/).

> Functions also simplify development by enabling code sharing. Every function belongs to a single library, and any given library can consist of multiple functions. **The library's contents are immutable, and selective updates of its functions aren't allowed. Instead, libraries are updated as a whole with all of their functions together in one operation.** This allows calling functions from other functions within the same library, or sharing code between functions by using a common code in library-internal methods, that can also take language native arguments.

> Functions are intended to better support the use case of maintaining a consistent view for data entities through a logical schema, as mentioned above. As such, functions are stored alongside the data itself. Functions are also persisted to the AOF file and replicated from master to replicas, so they are as durable as the data itself. When Redis is used as an ephemeral cache, additional mechanisms (described below) are required to make functions more durable.

> Like all other operations in Redis, the execution of a function is atomic. A function's execution blocks all server activities during its entire time, similarly to the semantics of transactions. These semantics mean that all of the script's effects either have yet to happen or had already happened. The blocking semantics of an executed function apply to all connected clients at all times. Because running a function blocks the Redis server, functions are meant to finish executing quickly, so you should avoid using long-running functions.


#### III. 


#### IV. 


#### V. Bibliography
1. [Redis programmability](https://redis.io/docs/latest/develop/programmability/)
2. [Scripting with Lua](https://redis.io/docs/latest/develop/programmability/eval-intro/)
3. [Redis Lua API reference](https://redis.io/docs/latest/develop/programmability/lua-api/)
4. [Redis functions](https://redis.io/docs/latest/develop/programmability/functions-intro/)
5. [Lua 5.1 Reference Manual](https://www.lua.org/manual/5.1/)
6. [Debugging Lua scripts in Redis](https://redis.io/docs/latest/develop/programmability/lua-debugging/)



#### VI. Appendix
**Script command summary**
```
SCRIPT <subcommand> [<arg> [value] [opt] ...]. Subcommands are:

    DEBUG (YES|SYNC|NO)
        Set the debug mode for subsequent scripts executed.
    EXISTS <sha1> [<sha1> ...]
        Return information about the existence of the scripts in the script cache.
    FLUSH [ASYNC|SYNC]
        Flush the Lua scripts cache. Very dangerous on replicas.
        When called without the optional mode argument, the behavior is determined by the
        lazyfree-lazy-user-flush configuration directive. Valid modes are:
    ASYNC: Asynchronously flush the scripts cache.
    SYNC: Synchronously flush the scripts cache.
    KILL
        Kill the currently executing Lua script.
    LOAD <script>
        Load a script into the scripts cache without executing it.
    HELP
        Print this help.
```

**Function command summary**
```
FUNCTION <subcommand> [<arg> [value] [opt] ...]. Subcommands are:

    LOAD [REPLACE] <FUNCTION CODE>
        Create a new library with the given library name and code.
    DELETE <LIBRARY NAME>
        Delete the given library.
    LIST [LIBRARYNAME PATTERN] [WITHCODE]
        Return general information on all the libraries:
        Library name
        The engine used to run the Library
        Library description
        Functions list
        * Library code (if WITHCODE is given)
        It also possible to get only function that matches a pattern using LIBRARYNAME argument.
    STATS
        Return information about the current function running:
        Function name
        Command used to run the function
        Duration in MS that the function is running
        If no function is running, return nil
        In addition, returns a list of available engines.
    KILL
        Kill the current running function.
    FLUSH [ASYNC|SYNC]
        Delete all the libraries.
        When called without the optional mode argument, the behavior is determined by the
        lazyfree-lazy-user-flush configuration directive. Valid modes are:
        * ASYNC: Asynchronously flush the libraries.
        * SYNC: Synchronously flush the libraries.
    DUMP
        Return a serialized payload representing the current libraries, can be restored using FUNCTION RESTORE command
    RESTORE <PAYLOAD> [FLUSH|APPEND|REPLACE]
        Restore the libraries represented by the given payload, it is possible to give a restore policy to
        control how to handle existing libraries (default APPEND):
        * FLUSH: delete all existing libraries.
        * APPEND: appends the restored libraries to the existing libraries. On collision, abort.
        * REPLACE: appends the restored libraries to the existing libraries, On collision, replace the old
        libraries with the new libraries (notice that even on this option there is a chance of failure"
        in case of functions name collision with another library).
    HELP
        Print this help.
```


#### Epilogue 


### EOF (2025/07/31)
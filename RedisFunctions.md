### Redis Function 


#### Prologue 


#### I. [Redis programmability](https://redis.io/docs/latest/develop/programmability/) (TL;DR)
> Extending Redis with Lua and Redis Functions

> Redis provides a programming interface that lets you execute custom scripts on the server itself. In Redis 7 and beyond, you can use [Redis Functions](https://redis.io/docs/latest/develop/programmability/functions-intro/) to manage and run your scripts. In Redis 6.2 and below, you use [Lua scripting with the EVAL command](https://redis.io/docs/latest/develop/programmability/eval-intro/) to program the server.

**Background** 

Redis is, by [definition](https://github.com/redis/redis/blob/unstable/MANIFESTO#L7), a *"domain-specific language for abstract data types"*. The language that Redis speaks consists of its [commands](https://redis.io/docs/latest/commands/). Most the commands specialize at manipulating core [data types](https://redis.io/docs/latest/develop/data-types/) in different ways. In many cases, these commands provide all the functionality that a developer requires for managing application data in Redis.

> The term **programmability** in Redis means having the ability to execute arbitrary user-defined logic by the server. We refer to such pieces of logic as **scripts**. In our case, scripts enable processing the data where it lives, a.k.a *data locality*. Furthermore, the responsible embedding of programmatic workflows in the Redis server can help in reducing network traffic and improving overall performance. Developers can use this capability for implementing robust, application-specific APIs. Such APIs can encapsulate business logic and maintain a data model across multiple keys and different data structures.

> User scripts are executed in Redis by an embedded, sandboxed scripting engine. Presently, Redis supports a single scripting engine, the Lua 5.1 interpreter.

> Please refer to the Redis Lua API Reference page for complete documentation.



#### II. 


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
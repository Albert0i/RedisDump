

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



1. [Redis programmability](https://redis.io/docs/latest/develop/programmability/)
2. [Scripting with Lua](https://redis.io/docs/latest/develop/programmability/eval-intro/)
3. [Redis Lua API reference](https://redis.io/docs/latest/develop/programmability/lua-api/)
4. [Redis functions](https://redis.io/docs/latest/develop/programmability/functions-intro/)
5. [Debugging Lua scripts in Redis](https://redis.io/docs/latest/develop/programmability/lua-debugging/)


> FUNCTION HELP
 "FUNCTION <subcommand> [<arg> [value] [opt] ...]. Subcommands are:"
 "LOAD [REPLACE] <FUNCTION CODE>"
 "    Create a new library with the given library name and code."
 "DELETE <LIBRARY NAME>"
 "    Delete the given library."
 "LIST [LIBRARYNAME PATTERN] [WITHCODE]"
 "    Return general information on all the libraries:"
 "    * Library name"
 "    * The engine used to run the Library"
1 "    * Library description"
1 "    * Functions list"
1 "    * Library code (if WITHCODE is give"
1 "    It also possible to get only function that matches a pattern using LIBRARYNAME argument."
1 "STATS"
1 "    Return information about the current function running:"
1 "    * Function name"
1 "    * Command used to run the function"
1 "    * Duration in MS that the function is running"
1 "    If no function is running, return nil"
2 "    In addition, returns a list of available engines."
2 "KILL"
2 "    Kill the current running function."
2 "FLUSH [ASYNC|SYNC]"
2 "    Delete all the libraries."
2 "    When called without the optional mode argument, the behavior is determined by the"
2 "    lazyfree-lazy-user-flush configuration directive. Valid modes are:"
2 "    * ASYNC: Asynchronously flush the libraries."
2 "    * SYNC: Synchronously flush the libraries."
2 "DUMP"
3 "    Return a serialized payload representing the current libraries, can be restored using FUNCTION RESTORE command"
3 "RESTORE <PAYLOAD> [FLUSH|APPEND|REPLACE]"
3 "    Restore the libraries represented by the given payload, it is possible to give a restore policy to"
3 "    control how to handle existing libraries (default APPEN:"
3 "    * FLUSH: delete all existing libraries."
3 "    * APPEND: appends the restored libraries to the existing libraries. On collision, abort."
3 "    * REPLACE: appends the restored libraries to the existing libraries, On collision, replace the old"
3 "      libraries with the new libraries (notice that even on this option there is a chance of failure"
3 "      in case of functions name collision with another librar."
3 "HELP"
4 "    Print this help."
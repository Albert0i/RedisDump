### [Redis Functions](https://redis.io/docs/latest/develop/programmability/functions-intro/)


#### Prologue 


#### I. [Redis programmability](https://redis.io/docs/latest/develop/programmability/) (TL;DR)
> Extending Redis with Lua and Redis Functions

> Redis provides a programming interface that lets you execute custom scripts on the server itself. In Redis 7 and beyond, you can use [Redis Functions](https://redis.io/docs/latest/develop/programmability/functions-intro/) to manage and run your scripts. In Redis 6.2 and below, you use [Lua scripting with the EVAL command](https://redis.io/docs/latest/develop/programmability/eval-intro/) to program the server.

##### **Background** 

> Redis is, by [definition](https://github.com/redis/redis/blob/unstable/MANIFESTO#L7), a *"domain-specific language for abstract data types"*. The language that Redis speaks consists of its [commands](https://redis.io/docs/latest/commands/). Most the commands specialize at manipulating core [data types](https://redis.io/docs/latest/develop/data-types/) in different ways. In many cases, these commands provide all the functionality that a developer requires for managing application data in Redis.

> The term **programmability** in Redis means having the ability to execute arbitrary user-defined logic by the server. We refer to such pieces of logic as **scripts**. In our case, scripts enable processing the data where it lives, a.k.a *data locality*. Furthermore, the responsible embedding of programmatic workflows in the Redis server can help in reducing network traffic and improving overall performance. Developers can use this capability for implementing robust, application-specific APIs. Such APIs can encapsulate business logic and maintain a data model across multiple keys and different data structures.

> User scripts are executed in Redis by an embedded, sandboxed scripting engine. Presently, Redis supports a single scripting engine, the [Lua 5.1](https://www.lua.org/) interpreter.

> Please refer to the [Redis Lua API Reference](https://redis.io/docs/latest/develop/programmability/lua-api/) page for complete documentation.

##### **Running scripts**

> Redis provides two means for running scripts.

> Firstly, and ever since Redis 2.6.0, the [EVAL](https://redis.io/docs/latest/commands/eval/) command enables running server-side scripts. Eval scripts provide a quick and straightforward way to have Redis run your scripts ad-hoc. However, using them means that the scripted logic is a part of your application (not an extension of the Redis server). Every applicative instance that runs a script must have the script's source code readily available for loading at any time. That is because scripts are only cached by the server and are volatile. As your application grows, this approach can become harder to develop and maintain.

> Secondly, added in v7.0, Redis Functions are essentially scripts that are first-class database elements. As such, functions decouple scripting from application logic and enable independent development, testing, and deployment of scripts. To use functions, they need to be loaded first, and then they are available for use by all connected clients. In this case, loading a function to the database becomes an administrative deployment task (such as loading a Redis module, for example), which separates the script from the application.

> Please refer to the following pages for more information:

- [Redis Eval Scripts](https://redis.io/docs/latest/develop/programmability/eval-intro/)
- [Redis Functions](https://redis.io/docs/latest/develop/programmability/functions-intro/)

> When running a script or a function, Redis guarantees its atomic execution. The script's execution blocks all server activities during its entire time, similarly to the semantics of [transactions](https://redis.io/docs/latest/develop/using-commands/transactions/). These semantics mean that all of the script's effects either have yet to happen or had already happened. The blocking semantics of an executed script apply to all connected clients at all times.

> Note that the potential downside of this blocking approach is that executing slow scripts is not a good idea. It is not hard to create fast scripts because scripting's overhead is very low. However, if you intend to use a slow script in your application, be aware that all other clients are blocked and can't execute any command while it is running.

##### **Read-only scripts**

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

##### **Sandboxed script context** 

> Redis places the engine that executes user scripts inside a sandbox. The sandbox attempts to prevent accidental misuse and reduce potential threats from the server's environment.

> Scripts should never try to access the Redis server's underlying host systems, such as the file system, network, or attempt to perform any other system call other than those supported by the API.

> Scripts should operate solely on data stored in Redis and data provided as arguments to their execution.

##### **Maximum execution time**

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


#### II. [Redis Functions](https://redis.io/docs/latest/develop/programmability/functions-intro/) (TL;DR)
> Scripting with Redis 7 and beyond

> Redis Functions is an API for managing code to be executed on the server. This feature, which became available in Redis 7, supersedes the use of [EVAL](https://redis.io/docs/latest/develop/programmability/eval-intro/) in prior versions of Redis.

##### **Prologue (or, what's wrong with Eval Scripts?)**

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

##### **What are Redis Functions?**

> Redis functions are an evolutionary step from ephemeral scripting.

> Functions provide the same core functionality as scripts but are first-class software artifacts of the database. Redis manages functions as an integral part of the database and ensures their availability via data persistence and replication. Because functions are part of the database and therefore declared before use, applications aren't required to load them during runtime nor risk aborted transactions. An application that uses functions depends only on their APIs rather than on the embedded script logic in the database.

> Whereas ephemeral scripts are considered a part of the application's domain, functions extend the database server itself with user-provided logic. They can be used to expose a richer API composed of core Redis commands, similar to modules, developed once, loaded at startup, and used repeatedly by various applications / clients. Every function has a unique user-defined name, making it much easier to call and trace its execution.

> The design of Redis Functions also attempts to demarcate between the programming language used for writing functions and their management by the server. Lua, the only language interpreter that Redis presently support as an embedded execution engine, is meant to be simple and easy to learn. However, the choice of Lua as a language still presents many Redis users with a challenge.

> The Redis Functions feature makes no assumptions about the implementation's language. An execution engine that is part of the definition of the function handles running it. An engine can theoretically execute functions in any language as long as it respects several rules (such as the ability to terminate an executing function).

> Presently, as noted above, Redis ships with a single embedded [Lua 5.1](https://redis.io/docs/latest/develop/programmability/lua-api/) engine. There are plans to support additional engines in the future. Redis functions can use all of Lua's available capabilities to ephemeral scripts, with the only exception being the [Redis Lua scripts debugger](https://redis.io/docs/latest/develop/programmability/lua-debugging/).

> Functions also simplify development by enabling code sharing. Every function belongs to a single library, and any given library can consist of multiple functions. **The library's contents are immutable, and selective updates of its functions aren't allowed. Instead, libraries are updated as a whole with all of their functions together in one operation.** This allows calling functions from other functions within the same library, or sharing code between functions by using a common code in library-internal methods, that can also take language native arguments.

> Functions are intended to better support the use case of maintaining a consistent view for data entities through a logical schema, as mentioned above. As such, functions are stored alongside the data itself. **Functions are also persisted to the AOF file and replicated from master to replicas, so they are as durable as the data itself.** When Redis is used as an ephemeral cache, additional mechanisms (described below) are required to make functions more durable.

> Like all other operations in Redis, the execution of a function is atomic. A function's execution blocks all server activities during its entire time, similarly to the semantics of [transactions](https://redis.io/docs/latest/develop/using-commands/transactions/). These semantics mean that all of the script's effects either have yet to happen or had already happened. **The blocking semantics of an executed function apply to all connected clients at all times. Because running a function blocks the Redis server, functions are meant to finish executing quickly, so you should avoid using long-running functions**.

##### **Loading libraries and functions** 

> Let's explore Redis Functions via some tangible examples and Lua snippets.

> At this point, if you're unfamiliar with Lua in general and specifically in Redis, you may benefit from reviewing some of the examples in [Introduction to Eval Scripts](https://redis.io/docs/latest/develop/programmability/eval-intro/) and [Lua API](https://redis.io/docs/latest/develop/programmability/lua-api/) pages for a better grasp of the language.

> Every Redis function belongs to a single library that's loaded to Redis. Loading a library to the database is done with the [FUNCTION LOAD](https://redis.io/docs/latest/commands/function-load/) command. The command gets the library payload as input, the library payload must start with Shebang statement that provides a metadata about the library (like the engine to use and the library name). The Shebang format is:
```
#!<engine name> name=<library name>
```

Let's try loading an empty library:
```
redis> FUNCTION LOAD "#!lua name=mylib\n"
(error) ERR No functions registered
```

The error is expected, as there are no functions in the loaded library. Every library needs to include at least one registered function to load successfully. A registered function is named and acts as an entry point to the library. When the target execution engine handles the [FUNCTION LOAD](https://redis.io/docs/latest/commands/function-load/) command, it registers the library's functions.

The Lua engine compiles and evaluates the library source code when loaded, and expects functions to be registered by calling the `redis.register_function()` API.

The following snippet demonstrates a simple library registering a single function named knockknock, returning a string reply:
```
#!lua name=mylib
redis.register_function(
  'knockknock',
  function() return 'Who\'s there?' end
)
```

In the example above, we provide two arguments about the function to Lua's redis.register_function() API: its registered name and a callback.

We can load our library and use [FCALL](https://redis.io/docs/latest/commands/fcall/) to call the registered function:
```
redis> FUNCTION LOAD "#!lua name=mylib\nredis.register_function('knockknock', function() return 'Who\\'s there?' end)"
mylib
redis> FCALL knockknock 0
"Who's there?"
```

Notice that the [FUNCTION LOAD](https://redis.io/docs/latest/commands/function-load/) command returns the name of the loaded library, this name can later be used [FUNCTION LIST](https://redis.io/docs/latest/commands/function-list/) and [FUNCTION DELETE](https://redis.io/docs/latest/commands/function-delete/).

We've provided [FCALL](https://redis.io/docs/latest/commands/fcall/) with two arguments: the function's registered name and the numeric value 0. This numeric value indicates the number of key names that follow it (the same way [EVAL](https://redis.io/docs/latest/commands/eval/) and [EVALSHA](https://redis.io/docs/latest/commands/evalsha/) work).

We'll explain immediately how key names and additional arguments are available to the function. As this simple example doesn't involve keys, we simply use 0 for now.

##### **Input keys and regular arguments**

> Before we move to the following example, it is vital to understand the distinction Redis makes between arguments that are names of keys and those that aren't.

> While key names in Redis are just strings, unlike any other string values, these represent keys in the database. The name of a key is a fundamental concept in Redis and is the basis for operating the Redis Cluster.

> **Important**: To ensure the correct execution of Redis Functions, both in standalone and clustered deployments, all names of keys that a function accesses must be explicitly provided as input key arguments.

> Any input to the function that isn't the name of a key is a regular input argument.

> Now, let's pretend that our application stores some of its data in Redis Hashes. We want an [HSET](https://redis.io/docs/latest/commands/hset/)-like way to set and update fields in said Hashes and store the last modification time in a new field named `_last_modified_`. We can implement a function to do all that.

> Our function will call [TIME](https://redis.io/docs/latest/commands/time/) to get the server's clock reading and update the target Hash with the new fields' values and the modification's timestamp. The function we'll implement accepts the following input arguments: the Hash's key name and the field-value pairs to update.

> The Lua API for Redis Functions makes these inputs accessible as the first and second arguments to the function's callback. The callback's first argument is a Lua table populated with all key names inputs to the function. Similarly, the callback's second argument consists of all regular arguments.

The following is a possible implementation for our function and its library registration:
```
#!lua name=mylib

local function my_hset(keys, args)
  local hash = keys[1]
  local time = redis.call('TIME')[1]
  return redis.call('HSET', hash, '_last_modified_', time, unpack(args))
end

redis.register_function('my_hset', my_hset)
```

If we create a new file named *mylib.lua* that consists of the library's definition, we can load it like so (without stripping the source code of helpful whitespaces):
```
$ cat mylib.lua | redis-cli -x FUNCTION LOAD REPLACE
```

> We've added the REPLACE modifier to the call to [FUNCTION LOAD](https://redis.io/docs/latest/commands/function-load/) to tell Redis that we want to overwrite the existing library definition. Otherwise, we would have gotten an error from Redis complaining that the library already exists.

> Now that the library's updated code is loaded to Redis, we can proceed and call our function:
```
redis> FCALL my_hset 1 myhash myfield "some value" another_field "another value"
(integer) 3
redis> HGETALL myhash
1) "_last_modified_"
2) "1640772721"
3) "myfield"
4) "some value"
5) "another_field"
6) "another value"
```

> In this case, we had invoked [FCALL](https://redis.io/docs/latest/commands/fcall/) with 1 as the number of key name arguments. That means that the function's first input argument is a name of a key (and is therefore included in the callback's keys table). After that first argument, all following input arguments are considered regular arguments and constitute the args table passed to the callback as its second argument.

##### **Expanding the library**

> We can add more functions to our library to benefit our application. The additional metadata field we've added to the Hash shouldn't be included in responses when accessing the Hash's data. On the other hand, we do want to provide the means to obtain the modification timestamp for a given Hash key.

> We'll add two new functions to our library to accomplish these objectives:

1. The `my_hgetall` Redis Function will return all fields and their respective values from a given Hash key name, excluding the metadata (i.e., the `_last_modified_` field).
2. The `my_hlastmodified` Redis Function will return the modification timestamp for a given Hash key name.

> The library's source code could look something like the following:
```
#!lua name=mylib

local function my_hset(keys, args)
  local hash = keys[1]
  local time = redis.call('TIME')[1]
  return redis.call('HSET', hash, '_last_modified_', time, unpack(args))
end

local function my_hgetall(keys, args)
  redis.setresp(3)
  local hash = keys[1]
  local res = redis.call('HGETALL', hash)
  res['map']['_last_modified_'] = nil
  return res
end

local function my_hlastmodified(keys, args)
  local hash = keys[1]
  return redis.call('HGET', hash, '_last_modified_')
end

redis.register_function('my_hset', my_hset)
redis.register_function('my_hgetall', my_hgetall)
redis.register_function('my_hlastmodified', my_hlastmodified)
```

> While all of the above should be straightforward, note that the `my_hgetall` also calls `redis.setresp(3)`. That means that the function expects [RESP3](https://github.com/redis/redis-specifications/blob/master/protocol/RESP3.md) replies after calling `redis.call()`, which, unlike the default RESP2 protocol, provides dictionary (associative arrays) replies. Doing so allows the function to delete (or set to nil as is the case with Lua tables) specific fields from the reply, and in our case, the `_last_modified_` field.

> Assuming you've saved the library's implementation in the *mylib.lua* file, you can replace it with:
```
$ cat mylib.lua | redis-cli -x FUNCTION LOAD REPLACE
```

> Once loaded, you can call the library's functions with [FCALL](https://redis.io/docs/latest/commands/fcall/):
```
redis> FCALL my_hgetall 1 myhash
1) "myfield"
2) "some value"
3) "another_field"
4) "another value"
redis> FCALL my_hlastmodified 1 myhash
"1640772721"
```

> You can also get the library's details with the [FUNCTION LIST](https://redis.io/docs/latest/commands/function-list/) command:
```
redis> FUNCTION LIST
1) 1) "library_name"
   2) "mylib"
   3) "engine"
   4) "LUA"
   5) "functions"
   6) 1) 1) "name"
         2) "my_hset"
         3) "description"
         4) (nil)
         5) "flags"
         6) (empty array)
      2) 1) "name"
         2) "my_hgetall"
         3) "description"
         4) (nil)
         5) "flags"
         6) (empty array)
      3) 1) "name"
         2) "my_hlastmodified"
         3) "description"
         4) (nil)
         5) "flags"
         6) (empty array)
```

> You can see that it is easy to update our library with new capabilities.

##### **Reusing code in the library**

On top of bundling functions together into database-managed software artifacts, libraries also facilitate code sharing. We can add to our library an error handling helper function called from other functions. The helper function check_keys() verifies that the input keys table has a single key. Upon success it returns nil, otherwise it returns an [error reply](https://redis.io/docs/latest/develop/programmability/lua-api/#redis.error_reply).

> The updated library's source code would be:
```
#!lua name=mylib

local function check_keys(keys)
  local error = nil
  local nkeys = table.getn(keys)
  if nkeys == 0 then
    error = 'Hash key name not provided'
  elseif nkeys > 1 then
    error = 'Only one key name is allowed'
  end

  if error ~= nil then
    redis.log(redis.LOG_WARNING, error);
    return redis.error_reply(error)
  end
  return nil
end

local function my_hset(keys, args)
  local error = check_keys(keys)
  if error ~= nil then
    return error
  end

  local hash = keys[1]
  local time = redis.call('TIME')[1]
  return redis.call('HSET', hash, '_last_modified_', time, unpack(args))
end

local function my_hgetall(keys, args)
  local error = check_keys(keys)
  if error ~= nil then
    return error
  end

  redis.setresp(3)
  local hash = keys[1]
  local res = redis.call('HGETALL', hash)
  res['map']['_last_modified_'] = nil
  return res
end

local function my_hlastmodified(keys, args)
  local error = check_keys(keys)
  if error ~= nil then
    return error
  end

  local hash = keys[1]
  return redis.call('HGET', keys[1], '_last_modified_')
end

redis.register_function('my_hset', my_hset)
redis.register_function('my_hgetall', my_hgetall)
redis.register_function('my_hlastmodified', my_hlastmodified)
```

> After you've replaced the library in Redis with the above, you can immediately try out the new error handling mechanism:
```
127.0.0.1:6379> FCALL my_hset 0 myhash nope nope
(error) Hash key name not provided
127.0.0.1:6379> FCALL my_hgetall 2 myhash anotherone
(error) Only one key name is allowed
```

> And your Redis log file should have lines in it that are similar to:
```
...
20075:M 1 Jan 2022 16:53:57.688 # Hash key name not provided
20075:M 1 Jan 2022 16:54:01.309 # Only one key name is allowed
```

##### **Functions in cluster**

> As noted above, Redis automatically handles propagation of loaded functions to replicas. In a Redis Cluster, it is also necessary to load functions to all cluster nodes. This is not handled automatically by Redis Cluster, and needs to be handled by the cluster administrator (like module loading, configuration setting, etc.).

> As one of the goals of functions is to live separately from the client application, this should not be part of the Redis client library responsibilities. Instead, redis-cli --cluster-only-masters --cluster call host:port FUNCTION LOAD ... can be used to execute the load command on all master nodes.

> Also, note that redis-cli --cluster add-node automatically takes care to propagate the loaded functions from one of the existing nodes to the new node.

##### **Functions and ephemeral Redis instances**

> In some cases there may be a need to start a fresh Redis server with a set of functions pre-loaded. Common reasons for that could be:

- Starting Redis in a new environment
- Re-starting an ephemeral (cache-only) Redis, that uses functions

> In such cases, we need to make sure that the pre-loaded functions are available before Redis accepts inbound user connections and commands.

> To do that, it is possible to use redis-cli --functions-rdb to extract the functions from an existing server. This generates an RDB file that can be loaded by Redis at startup.

##### **Function flags**

> Redis needs to have some information about how a function is going to behave when executed, in order to properly enforce resource usage policies and maintain data consistency.

> For example, Redis needs to know that a certain function is read-only before permitting it to execute using [FCALL_RO](https://redis.io/docs/latest/commands/fcall_ro/) on a read-only replica.

> By default, Redis assumes that all functions may perform arbitrary read or write operations. Function Flags make it possible to declare more specific function behavior at the time of registration. Let's see how this works.

> In our previous example, we defined two functions that only read data. We can try executing them using [FCALL_RO](https://redis.io/docs/latest/commands/fcall_ro/) against a read-only replica.
```
redis > FCALL_RO my_hgetall 1 myhash
(error) ERR Can not execute a function with write flag using fcall_ro.
```

> Redis returns this error because a function can, in theory, perform both read and write operations on the database. As a safeguard and by default, Redis assumes that the function does both, so it blocks its execution. The server will reply with this error in the following cases:

1. Executing a function with [FCALL](https://redis.io/docs/latest/commands/fcall/) against a read-only replica.
2. Using [FCALL_RO](https://redis.io/docs/latest/commands/fcall_ro/) to execute a function.
3. A disk error was detected (Redis is unable to persist so it rejects writes).

> In these cases, you can add the no-writes flag to the function's registration, disable the safeguard and allow them to run. To register a function with flags use the [named arguments](https://redis.io/docs/latest/develop/programmability/lua-api/#redis.register_function_named_args) variant of `redis.register_function`.

> The updated registration code snippet from the library looks like this:
```
redis.register_function('my_hset', my_hset)
redis.register_function{
  function_name='my_hgetall',
  callback=my_hgetall,
  flags={ 'no-writes' }
}
redis.register_function{
  function_name='my_hlastmodified',
  callback=my_hlastmodified,
  flags={ 'no-writes' }
}
```

> Once we've replaced the library, Redis allows running both `my_hgetall` and `my_hlastmodified` with [FCALL_RO](https://redis.io/docs/latest/commands/fcall_ro/) against a read-only replica:
```
redis> FCALL_RO my_hgetall 1 myhash
1) "myfield"
2) "some value"
3) "another_field"
4) "another value"
redis> FCALL_RO my_hlastmodified 1 myhash
"1640772721"
```

For the complete documentation flags, please refer to [Script flags](https://redis.io/docs/latest/develop/programmability/lua-api/#script_flags).


#### III. A Quick Start Guide 
For those who don't want to crawl through official documentations: 

- [Redis programmability](https://redis.io/docs/latest/develop/programmability/) outlines the whole picture of Redis programming ecology. 
- [Scripting with Lua](https://redis.io/docs/latest/develop/programmability/eval-intro/) describes scripting with Lua script in general.
- [Redis functions](https://redis.io/docs/latest/develop/programmability/functions-intro/) describes the new Redis Functions available from Redis 7 onward. 

Redis Functions are written in Lua and loaded into a Redis Server. They survive a server reboot and provide better way to share code among Redis clients. Redis Functions can be invoked either programmatically or in Redis CLI via [FCALL](https://redis.io/docs/latest/commands/fcall/) or [FCALL_RO](https://redis.io/docs/latest/commands/fcall_ro/) depending on whether the functions perform read/write or write only operations. The use of [FCALL_RO](https://redis.io/docs/latest/commands/fcall_ro/) offers subtle advantages and you *should* always stick to this regulation. If you are already familiar with Lua script, converting existing scripts into Redis Function is only a couple of steps. 

Code template for Redis function: 
```
#!lua name=mylib

redis.register_function('myfunc', function(KEYS, ARGV) 
    -- Required: 
    -- Optional: 
    -- Example usage: 
    -- Output: 

    <place your lua script here>

  end )
```

Code template for Redis function with **no-writes** [flag](https://redis.io/docs/latest/develop/programmability/lua-api/#script_flags):
```
#!lua name=mylib

redis.register_function{
    function_name = 'myfunc',
    callback = function(KEYS, ARGV)
      -- Required: 
      -- Optional: 
      -- Example usage: 
      -- Output: 

      <place your lua script here>

    end,
    flags = { 'no-writes' }
  }
```

The first line states that you are using Lua as scripting engine and the library name is mylib. Functions of read/write and read only bear different syntax. You can create a file mixed with read write and read only functions as I do. All functions of a library have to loaded in one go. 

`loader.js`
```
import { redis } from './redis/redis.js'
import { readFile } from 'fs/promises';

/*
   main 
*/
await redis.connect();

// Load Lua function from file
const luaScript = await readFile('./src/myLib.lua', 'utf8');
console.log(await redis.sendCommand(['FUNCTION', 'LOAD', 'REPLACE', luaScript]), 'loaded');

await redis.close();
process.exit(0)
```

Run command to load Redis Functions with: 
```
node src/loader.js
mylib loaded
```

And check with: 
```
> FUNCTION LIST LIBRARYNAME mylib
1) 1) "library_name"
   2) "mylib"
   3) "engine"
   4) "LUA"
   5) "functions"
   6) 1) 1) "name"
         2) "scanTextChi"
         3) "description"
         4) "null"
         5) "flags"
         6) 1) "no-writes"
      2) 1) "name"
         2) "zSumScore"
         3) "description"
         4) "null"
         5) "flags"
         6) 1) "no-writes"
      3) 1) "name"
         2) "toFix"
         3) "description"
         4) "null"
         5) "flags"
         6) 1) "no-writes"
      4) 1) "name"
         2) "zAddIncr"
         3) "description"
         4) "null"
         5) "flags"
         6) (empty list or set)
      5) 1) "name"
         2) "delall"
         3) "description"
         4) "null"
         5) "flags"
         6) (empty list or set)
      6) 1) "name"
         2) "countKeys"
         3) "description"
         4) "null"
         5) "flags"
         6) 1) "no-writes"
      7) 1) "name"
         2) "ver"
         3) "description"
         4) "null"
         5) "flags"
         6) 1) "no-writes"
```

Done!


#### IV. Example usage
##### **Really trivial things**
```
FCALL_RO VER 0
FCALL_RO TOFIX 2 123.456 2
FCALL_RO TOFIX 1 123.456
```

##### **Utility functions**
```
FCALL_RO COUNTKEYS 1 fts:chinese:documents:*
FCALL_RO COUNTKEYS 0
FCALL DELALL 1 temp:*
```

##### **Extension to underlaying Data Structures**
```
FCALL ZADDINCR 1 testz a b c d e f 
FCALL_RO ZSUMSCORE 1 testz
```

##### **Proof of concept**
```
FCALL_RO SCANTEXTCHI 5 fts:chinese:documents:* key 鄭文公 0 10  id textChi visited
FCALL_RO SCANTEXTCHI 3 fts:chinese:documents:* key 鄭文公
```

##### **sendCommand**
Call it straightly: 
```
console.log(await redis.sendCommand(['FCALL_RO', 'VER', '0']))
console.log(await redis.sendCommand(['FCALL_RO', 'COUNTKEYS', '0']))
console.log(await redis.sendCommand(['FCALL_RO', 'SCANTEXTCHI', '3', 
    'fts:chinese:documents:*', 'key', '陳文公', 
    'id', 'key', 'textChi', 'visited']))
console.log(await redis.sendCommand(['FCALL_RO', 'SCANTEXTCHI', '3', 
    'fts:chinese:documents:*', 'key', '陳文公'])) 
```

##### **fCall** and **fCallRo**
Or more intuitively, to wrap the sendCommands with: 
```
redis.fCall = function(name, keys = [], args = []) {
    const numkeys = keys.length.toString();
    return this.sendCommand(['FCALL', name, numkeys, ...keys, ...args]);
  };

redis.fCallRo = function(name, keys = [], args = []) {
    const numkeys = keys.length.toString();
    return this.sendCommand(['FCALL_RO', name, numkeys, ...keys, ...args]);
  };
```

Call it accordingly: 
```
console.log(await redis.fCallRo('ver', [], []))
console.log(await redis.fCallRo('countKeys', [], []))
console.log(await redis.fCallRo('scanTextChi', 
    ['fts:chinese:documents:*', 'key', '陳文公'], 
    ['id', 'key', 'textChi', 'visited']))
console.log(await redis.fCallRo('scanTextChi', 
    ['fts:chinese:documents:*', 'key', '陳文公']))
```


#### V. Bibliography
1. [Redis programmability](https://redis.io/docs/latest/develop/programmability/)
2. [Scripting with Lua](https://redis.io/docs/latest/develop/programmability/eval-intro/)
3. [Redis Lua API reference](https://redis.io/docs/latest/develop/programmability/lua-api/)
4. [Redis functions](https://redis.io/docs/latest/develop/programmability/functions-intro/)
5. [Lua 5.1 Reference Manual](https://www.lua.org/manual/5.1/)
6. [Debugging Lua scripts in Redis](https://redis.io/docs/latest/develop/programmability/lua-debugging/)
7. [The Castle by Franz Kafka](https://files.libcom.org/files/Franz%20Kafka-The%20Castle%20(Oxford%20World's%20Classics)%20(2009).pdf)


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
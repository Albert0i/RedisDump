import { redis } from './redis/redis.js'

/*
   main 
*/
const script = `
    -- array style table
    local table1 = { "iong_dev", "active" }
    -- Or explicitly specify the index
    -- local table1 = { [2] = "iong_dev", [1] = "active" }

    -- dictionary style table
    local table2 = { name = "iong_dev", status = "active" }

    local table3 = { 'name', 'iong_dev', 'status', 'active', 'age', 59 }

    -- unpack() looks for numeric index starting from 1, which 
    -- doesn't exist in dictionary style table. 
    redis.log(redis.LOG_NOTICE, unpack(table1))
    -- will output: 'iong_dev active' in redis.log  

    -- A call to unpack(table2) return nil, nil     
    -- redis.log(redis.LOG_NOTICE, unpack(table2))
    -- results in an error. 

    redis.log(redis.LOG_NOTICE, cjson.encode(table1))
    -- will output: '["iong_dev","active"]' in redis.log

    redis.log(redis.LOG_NOTICE, cjson.encode(table2))
    -- will output: '{"name":"iong_dev","status":"active"}' in redis.log
    
    -- Similarly, array style table has length; 
    -- dictionary style table HAS NOT... 

    -- Set the 'myhash', effectively the same as: 
    -- HSET myhash name iong_dev status active age 59
    redis.call('HSET', 'myhash', unpack(table3, 3, 6))

    -- returns: [ 2, 0 ]
    -- return { #table1, #table2 }
    -- return { name = "iong_dev", status = "active" }
    redis.setresp(3)
    return { map={ name = "iong_dev", status = "active" } }
`
await redis.connect()
await redis.sendCommand(['HELLO', '3'])

console.log(await redis.eval(script, { keys: [], arguments: [] }))

await redis.close()
process.exit(0)

/*
node:internal/modules/run_main:104
    triggerUncaughtException(
    ^

[SimpleError: ERR redis.log() requires two arguments or more. script: 9a81afe7c8515723aefe02c8e6f7e1a87be3d5f2, on @user_script:18.]
*/
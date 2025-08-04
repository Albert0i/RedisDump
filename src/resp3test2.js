import { redis } from './redis/redis.js'

/*
   main 
*/
const script = `
    redis.setresp(3)
    local mykey = 'some:temp:key'
    -- local myobj = { "name", "iong_dev", "status", "active", "score", 98" } 
    local myobj = {} 
    local myreturn = {}
    
    table.insert(myobj, "name")
    table.insert(myobj, "iong_dev")
    table.insert(myobj, "status")
    table.insert(myobj, "active")
    table.insert(myobj, "score")
    table.insert(myobj, 98)
    
    redis.call('HSET', mykey, unpack(myobj))
    myreturn = redis.call('HGETALL', mykey)
    redis.call('UNLINK', mykey)

    return myreturn
  `
await redis.connect()

console.log(await redis.sendCommand(['HELLO', '3']));

const result = await redis.eval(script, { keys: [], arguments: [] })

console.log('The result is', result)

await redis.close();
process.exit(0)

/*
HELLO 3
EVAL 'redis.setresp(3) return { name = "iong_dev", status = "active", score = 98 }' 0 

*/
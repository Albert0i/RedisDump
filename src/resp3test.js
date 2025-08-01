import { redis } from './redis/redis.js'

/*
   main 
*/
const script = `
    redis.setresp(3)
    return cjson.encode({ name = "iong_dev", status = "active", score = 98 })
  `
await redis.connect()

await redis.sendCommand(['HELLO', '3']);
console.log(await redis.sendCommand(['HELLO']));

const result = await redis.eval(script, { keys: [], arguments: [] })
const data = JSON.parse(result)

console.log('The result is', result)
console.log('The data is', data)

await redis.close();
process.exit(0)

/*
HELLO 3
EVAL 'redis.setresp(3) return { name = "iong_dev", status = "active", score = 98 }' 0 

*/
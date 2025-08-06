import { redis } from './redis/redis.js'

/*
   main 
*/
const script = `
    redis.setresp(3)
    return { map = { name = "iong_dev", status = "active", score = 98 } }
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
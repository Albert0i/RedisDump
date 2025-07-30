import { redis } from './redis/redis.js'

/*
   main 
*/
const script = `
    local function table_to_array(tbl)
      local arr = {}
      for k, v in pairs(tbl) do
        table.insert(arr, tostring(k))
        table.insert(arr, v)
      end
      return arr
    end

    redis.setresp(3)
    return { name = "iong_dev", status = "active", score = 98 }
  `
await redis.connect()

await redis.sendCommand(['HELLO', '3']);
console.log(await redis.sendCommand(['HELLO']));

console.log('The result is', 
    await redis.eval(script, { keys: [], arguments: [] }))

await redis.close();
process.exit(0)

/*
HELLO 3
EVAL 'redis.setresp(3) return { name = "iong_dev", status = "active", score = 98 }' 0 

*/
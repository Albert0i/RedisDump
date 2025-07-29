import { redis } from './redis/redis.js'

/*
   main 
*/
await redis.connect()

await redis.sendCommand(['HELLO', '3']);
console.log(await redis.sendCommand(['HELLO']));

console.log(await redis.sendCommand(['FCALL_RO', 'RESP3', '0']))

await redis.close();
process.exit(0)

/*
redis.fCall = function(name, keys = [], args = []) {
    const numkeys = keys.length.toString();
    return this.sendCommand(['FCALL', name, numkeys, ...keys, ...args]);
  };
*/
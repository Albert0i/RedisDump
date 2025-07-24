import { redis } from './redis/redis.js'

/*
   main 
*/
await redis.connect()

console.log(await redis.fCall('ver', [], []))
console.log(await redis.fCall('countKeys', [], []))
console.log(await redis.fCall('scanTextChi', 
    ['fts:chinese:documents:*', 'key', '陳文公'], 
    ['id', 'key', 'textChi', 'visited']))

await redis.close();
process.exit(0)

/*
redis.fCall = function(name, keys = [], args = []) {
    const numkeys = keys.length.toString();
    return this.sendCommand(['FCALL', name, numkeys, ...keys, ...args]);
  };
*/
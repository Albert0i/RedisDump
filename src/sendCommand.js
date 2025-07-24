import { redis } from './redis/redis.js'

/*
   main 
*/
await redis.connect()

console.log(await redis.sendCommand(['FCALL', 'VER', '0']))
console.log(await redis.sendCommand(['FCALL', 'COUNTKEYS', '0']))
console.log(await redis.sendCommand(['FCALL', 'SCANTEXTCHI', '3', 
    'fts:chinese:documents:*', 'key', '陳文公', 
    'id', 'key', 'textChi', 'visited']))

await redis.close();
process.exit(0)

/*
redis.fCall = function(name, keys = [], args = []) {
    const numkeys = keys.length.toString();
    return this.sendCommand(['FCALL', name, numkeys, ...keys, ...args]);
  };
*/
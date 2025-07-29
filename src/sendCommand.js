import { redis } from './redis/redis.js'

/*
   main 
*/
await redis.connect()

console.log(await redis.sendCommand(['FCALL_RO', 'VER', '0']))
console.log(await redis.sendCommand(['FCALL_RO', 'COUNTKEYS', '0']))
console.log(await redis.sendCommand(['FCALL_RO', 'SCANTEXTCHI', '3', 
    'fts:chinese:documents:*', 'key', '鄭文公', 
    'id', 'key', 'textChi', 'visited']))
console.log(await redis.sendCommand(['FCALL_RO', 'SCANTEXTCHI', '3', 
     'fts:chinese:documents:*', 'key', '鄭文公'])) 

await redis.close();
process.exit(0)

/*
redis.fCall = function(name, keys = [], args = []) {
    const numkeys = keys.length.toString();
    return this.sendCommand(['FCALL', name, numkeys, ...keys, ...args]);
  };
*/
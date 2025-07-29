import { redis } from './redis/redis.js'

/*
   main 
*/
await redis.connect()

console.log(await redis.fCallRo('ver', [], []))
console.log(await redis.fCallRo('countKeys', [], []))
console.log(await redis.fCallRo('scanTextChi', 
    ['fts:chinese:documents:*', 'key', '鄭文公'], 
    ['id', 'textChi', 'visited']))
console.log(await redis.fCallRo('scanTextChi', 
    ['fts:chinese:documents:*', 'key', '鄭文公']))

await redis.close();
process.exit(0)

/*
redis.fCall = function(name, keys = [], args = []) {
    const numkeys = keys.length.toString();
    return this.sendCommand(['FCALL', name, numkeys, ...keys, ...args]);
  };
*/
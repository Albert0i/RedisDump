import { redis } from './redis/redis.js'
import { readFile } from 'fs/promises';

/*
   main 
*/
await redis.connect();

// 1️⃣ Load Lua function from file
const luaScript = await readFile('./src/lua/myLib.lua', 'utf8');
console.log(await redis.sendCommand(['FUNCTION', 'LOAD', 'REPLACE', luaScript]), 'loaded');

// // 2️⃣ Call the function
// // const result = await redis.sendCommand(['FCALL', 'countKeys', '1', '*']);
// // console.log('Function result:', result); // Who's there?
// // 🔍 Call the Lua function with a key pattern
// const pattern = 'user:*'; // Adjust this to your actual key prefix
// const result = await redis.sendCommand(['FCALL', 'countKeys', '1', '*']);
// console.log('Function result:', result); // Who's there?

// // 3️⃣ Remove the function library
// //await redis.sendCommand(['FUNCTION', 'DELETE', 'mylib']);
// console.log('Function library removed.');

await redis.close();
process.exit(0)

/*
   FCALL <function_name> <numkeys> <key1> <key2> ... <arg1> <arg2> ...

   FCALL ver 0 

   FCALL countKeys 1 *

   ZADD test 1 a 1 b 1 c
   ZRANGE test 0 -1 WITHSCORES
   FCALL zAddIncr 1 test a
   FCALL zAddIncr 1 test a
   FCALL zAddIncr 1 test b
   ZRANGE test 0 -1 WITHSCORES

   FCALL zSumScore 1 test 

   FCALL scanTextChi 5 'fts:chinese:documents:*' 'key' '鄭文公' '0' '10' id textChi visited

   FCALL fsTextChi 4 'textChi' '世界' '0' '10' fts:chinese:tokens:世 fts:chinese:tokens:界

   FCALL getVisitedDocs 3 'fts:chinese:visited' '0' '10' id  textChi visited
*/
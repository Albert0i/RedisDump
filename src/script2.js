import fs from 'fs';
import path from 'path';
import { redis } from './redis/redis.js'

async function loadScript(path_to_script) {
    // Absolute or relative path to your file
    const filePath = path.resolve(path_to_script);
    // Read the contents as a string
    const fileContents = fs.readFileSync(filePath, 'utf-8');

    return await redis.scriptLoad(fileContents);
} 

/*
   main 
*/
await redis.connect()

const sha = await loadScript('./src/lua/zAddIncr.lua')
const shaRo = await loadScript('./src/lua/zSumScore.lua')

await redis.evalSha(sha, { 
    keys: [ 'testz' ], 
    args: ['a', 'b', 'c', 'd', 'e', 'f' ] 
})

await redis.close()
process.exit(0)

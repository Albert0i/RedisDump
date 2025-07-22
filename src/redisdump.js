/*
   redisdump.js 
*/
import { redis } from './redis/redis.js'
import { createWriteStream } from 'fs';
import { format } from 'date-fns';

async function dumpRedis(prefix, scanCount, outputFile) {
  const output = createWriteStream(outputFile, { flags: 'w' });
  let counter = 0; 
  let cursor = '0';
  let keys = []

  console.log(`Saving Redis commands to ${outputFile} with prefix ${prefix}...`);    
  try {
    do {
      const result = await redis.scan(cursor, {
        MATCH: prefix,
        COUNT: scanCount, 
      });

      cursor = result.cursor;
      keys = result.keys;

      for (const key of keys) {
        const type = await redis.type(key);

        switch (type) {
          case 'string': {
            const val = await redis.get(key);
            output.write(`SET "${key}" "${val}"\n`);
            break;
          }
          case 'list': {
            const items = await redis.lRange(key, 0, -1);
            items.forEach(item => {
              output.write(`RPUSH "${key}" "${item}"\n`);
            });
            break;
          }
          case 'set': {
            const members = await redis.sMembers(key);
            if (members.length)
              output.write(`SADD "${key}" ${members.map(m => `"${m}"`).join(' ')}\n`);
            break;
          }
          case 'zset': {
            const zitems = await redis.zRangeWithScores(key, 0, -1);
            zitems.forEach(({ value, score }) => {
              output.write(`ZADD "${key}" ${score} "${value}"\n`);
            });
            break;
          }
          case 'hash': {
            const fields = await redis.hGetAll(key);
            const flat = Object.entries(fields).map(([k, v]) => `"${k}" "${v}"`).join(' ');
            output.write(`HSET "${key}" ${flat}\n`);
            break;
          }
          case 'ReJSON-RL': {
            const json = await redis.sendCommand(['JSON.GET', key]);
            output.write(`JSON.SET "${key}" "." '${json}'\n`);
            break;
          }
          default:
            output.write(`# Skipped ${key}: unsupported type "${type}"\n`);
        }
        counter = counter + 1 
        if ((counter / scanCount) === Math.floor(counter / scanCount) ) {
          console.log(counter)
        }
      }
    } while (cursor !== '0');
  } catch (err) {
    throw err;
  } finally {
    console.log(counter)
    output.end();
  }
}

/*
   main 
*/
const args = process.argv.slice(2); 
const prefix = args[0] || '*';  // default '*'
const scanCount = 1000          // adjust batch size as needed

const dateSuffix = format(new Date(), 'yyyy-MM-dd');
const outputFile = `./data/dump (${dateSuffix}).redis`;

if (args.includes('--help')) {
  console.log(`
redisdump.js - Dump Redis keys as executable redis-cli commands

Usage:
  node redisdump.js [KEY_PATTERN]

Options:
  --help           Show this help message
  KEY_PATTERN      Optional Redis MATCH pattern (default: "*")

Behavior:
  - Uses SCAN with COUNT 1000 to iterate keys efficiently
  - Overwrites output file on each run
  - Creates a dump file named: dump (YYYY-MM-DD).redis
  - Outputs native commands: SET, RPUSH, SADD, ZADD, HSET, JSON.SET
  - Can be restored using: redis-cli < dump (YYYY-MM-DD).redos

Examples:
  node src/redisdump.js              # Dump all keys
  node src/redisdump.js user:*       # Dump keys matching "user:*"
  node src/redisdump.js --help       # Show help
`);
} else {
  await redis.connect()
  await dumpRedis(prefix, scanCount, outputFile);
  await redis.close()
}

process.exit(0)

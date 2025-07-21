/*
   redisdump.js 
*/
import { redis } from './redis/redis.js'
import { createWriteStream } from 'fs';

const REDISDUMP = './data/dump.redis'
const SCANCOUNT = 1000
const output = createWriteStream(`${REDISDUMP}`, { flags: 'a' });

async function dumpRedis() {
  try {
    await redis.connect();
    let counter = 0; 
    let cursor = '0';
    let keys = []

    do {
      const result = await redis.scan(cursor, {
        MATCH: '*',
        COUNT: SCANCOUNT, // adjust batch size as needed
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
        if ((counter / SCANCOUNT) === Math.floor(counter / SCANCOUNT) ) {
          console.log(counter)
        }
      }
    } while (cursor !== '0');

    console.log(`Redis commands saved to ${REDISDUMP}`);
  } catch (err) {
    console.error('❌ Error during dump:', err);
  } finally {
    console.log(counter)
    output.end();
    await redis.close();
  }
}

dumpRedis();
process.exit(0)

import 'dotenv/config'
import { createClient } from 'redis'

const redis = createClient({ 
        socket: {
            port: process.env.REDIS_PORT,       // Redis port
            host: process.env.REDIS_HOST,       // Redis host    
            tls: false
        }, 
        password: process.env.REDIS_PASSWORD,   // Redis password 
    })

redis.on('error', (err) => console.log('Redis Client Error', err));

redis.fCall = function(name, keys = [], args = []) {
    const numkeys = keys.length.toString();
    return this.sendCommand(['FCALL', name, numkeys, ...keys, ...args]);
  };

redis.fCallRo = function(name, keys = [], args = []) {
    const numkeys = keys.length.toString();
    return this.sendCommand(['FCALL_RO', name, numkeys, ...keys, ...args]);
  };

export { redis }

/*
   node-redis
   https://www.npmjs.com/package/redis
*/
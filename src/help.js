export const info = `
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
`
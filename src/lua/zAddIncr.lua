-- KEYS[1] = sorted set key
-- ARGV[1] = member name

local added = redis.call('ZADD', KEYS[1], 'NX', 1, ARGV[1])

if added == 0 then
  -- Member existed, increment score
  return redis.call('ZINCRBY', KEYS[1], 1, ARGV[1])
else
  -- Member was added with initial score of 1
  return 1
end

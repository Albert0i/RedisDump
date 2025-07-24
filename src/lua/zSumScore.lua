-- KEYS[1] = sorted set key

local total = 0
local members = redis.call('ZRANGE', KEYS[1], 0, -1, 'WITHSCORES')

for i = 2, #members, 2 do
  total = total + tonumber(members[i])
end

return total
-- KEYS[1] = prefix pattern (e.g., "user:*")
local cursor = "0"
local totalCount = 0  
local totalSize = 0   


repeat
  local result = redis.call("SCAN", cursor, "MATCH", KEYS[1], "COUNT", 1000)
  cursor = result[1]
  local keys = result[2]

  for i = 1, #keys do
    totalCount = totalCount + 1

    -- The unit returned by Redis’s MEMORY USAGE command is bytes
    local size = redis.call("MEMORY", "USAGE", keys[i])
    if size then
      totalSize = totalSize + size
    end
  end
until cursor == "0"

return { totalCount, totalSize }
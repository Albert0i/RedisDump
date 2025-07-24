--[[
  Lua script to fetch Hash Entries from a Sorted Set by Score

  Parameters:
    KEYS[1] - Name of the Sorted set, "fts:documents:visited for example
    KEYS[2] - The number of documents to skip, '0' for example; 
    KEYS[3] - The maximum number of documents to return, '10' for example; 
    ARGV[] - Fields to be returned, ["id", "textChi", "visited"] for example.

  Returns:
    Array of array contains the documents.
]]
local offset = tonumber(KEYS[2])
local limit = tonumber(KEYS[3])

local matched = {}  -- result to be returned 
local index = 1     -- index to place retrieved value

-- Read members from high to low score
local keys = redis.call("ZREVRANGEBYSCORE", KEYS[1], '+inf', '-inf', 'LIMIT', offset, limit)

for _, key in ipairs(keys) do
    -- Take limit 
    if limit > 0 then 
      -- If no field names specified to return 
      if ARGV[1] == "*" then
        matched[index] = redis.call("HGETALL", key)
      else        
        matched[index] = redis.call("HMGET", key, unpack(ARGV))
      end

      -- Increase the index 
      index = index + 1
      -- Decrease the limit
      limit = limit - 1
    else 
      -- Readhed limit before scan completed
      return matched
    end 
end

-- Scan completed
return matched

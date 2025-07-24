--[[
  Lua script uses ZINTERSTORE to calculate hashes matching "document:*"
  and return HASH objects.

  Parameters:
    KEYS[1] - Field name contains the text, "textChi" for example;
    KEYS[2] - Value contained, "韓非子" for example; 
    KEYS[3] - The number of documents to skip, '0' for example; 
    KEYS[4] - The maximum number of documents to return, '10' for example; 
    ARGV[]  - list of source keys, ["fts:chinese:tokens:世", "fts:chinese:tokens:界"] for example.

  Returns:
    Array of array contains the documents.
--]]
local offset = tonumber(KEYS[3])
local limit = tonumber(KEYS[4])

local matched = {}  -- result to be returned 
local index = 1     -- index to place retrieved value

local tempkey = 'temp:'..KEYS[2]  -- destination key
local tempkeyTTL = 30             -- delete after n seconds 

-- Step 1: Collect cardinalities
local sets = {}
for i = 1, #ARGV do
  local key = ARGV[i]
  local count = redis.call('ZCARD', key)
  table.insert(sets, { key = key, count = count })
end

-- Step 2: Sort by cardinality (ascending)
table.sort(sets, function(a, b)
  return a.count < b.count
end)

-- Step 3: Build args for ZINTERSTORE
local args = {}
table.insert(args, tempkey)         -- destination key
table.insert(args, #sets)           -- number of source keys

for i = 1, #sets do
  table.insert(args, sets[i].key)   -- sorted source keys
end

-- Step 4: Add aggregation method
table.insert(args, 'AGGREGATE')
table.insert(args, 'MIN')

-- Step 5: Execute and expire
local n = redis.call('ZINTERSTORE', unpack(args))
redis.call('EXPIRE', tempkey, tempkeyTTL)

-- If intersect is not empty 
if ( n > 0 ) then 
  -- ZREVRANGEBYSCORE "temp:世界" +inf -inf WITHSCORES
  local z = redis.call('ZREVRANGEBYSCORE', tempkey, '+inf', '-inf', 'WITHSCORES')
  -- Example result: { "userA", "42", "userB", "37", "userC", "29" }
  for i = 1, #z, 2 do
    local key = z[i]
    local score = tonumber(z[i + 1])

    -- Get the field value to inspect 
    local text = redis.call("HGET", key, KEYS[1])

    -- If found and contains the value
    if (text) and (string.find(text, KEYS[2])) then 
      -- Skip offset 
      if offset > 0 then 
        offset = offset - 1
      else 
        -- Take limit 
        if limit > 0 then 
          matched[index] = { redis.call("HGETALL", key), score }

          -- Increase the index 
          index = index + 1
          -- Decrease the limit
          limit = limit - 1
        else 
          -- Readhed limit before scan completed
          return matched
        end 
      end 
    end 
  end
end

-- Search completed
return matched

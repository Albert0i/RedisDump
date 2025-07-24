--[[
  Lua script uses ZINTER to calculate hashes matching "document:*"
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
local z = redis.call('ZINTER', #ARGV, unpack(ARGV))

for _, key in ipairs(z) do 
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
        matched[index] = redis.call("HGETALL", key)

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

-- Search completed
return matched

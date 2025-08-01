#!lua name=mylib

-- Redis Version
-- No parameter is required:
-- Example usage: FCALL_RO VER 0
-- Output: "8.0.2"
local function ver(KEYS, ARGV)
  return redis.REDIS_VERSION
end

-- Lua Runtime libraries 
-- No parameter is required:
-- Example usage: FCALL_RO LIBS 0
-- Output:  1) " 1) _G              [Variable]"
--          2) " 2) _VERSION        [Variable]"
--          3) " 3) assert          [Function]"
--          4) " 4) bit             [Variable]"
--          5) " 5) cjson           [Variable]"
--          6) " 6) cmsgpack        [Variable]"
local function libs(KEYS, ARGV)
  local libs = {}
  for k, v in pairs(_G) do
    local vtype = type(v)
    local category = (vtype == "function") and "Function" or "Variable"
    table.insert(libs, { name = k, category = category })
  end
  
  -- Sort by name
  table.sort(libs, function(a, b) return a.name < b.name end)
  
  -- Build formatted output
  local result = {}
  for i, item in ipairs(libs) do
    table.insert(result, string.format("%2d) %-15s [%s]", i, item.name, item.category))
  end
  
  -- Return as a multi-line array
  return result
end 

-- Return RESP3 object
-- No parameter is required:
-- Example usage: FCALL_RO RESP3 0
-- Output:  "{ name = "iong_dev", status = "active", score = 98 }" if RESP3 is supported; 
--          "[]" if RESP3 is not supported.

local function resp3(KEYS, ARGV)
  redis.setresp(3)
  return { name = "iong_dev", status = "active", score = 98 }  
end

-- Round up to number of decimals
-- Required:
--      KEYS[1] = Number to be rounded
-- Optional:
--      KEYS[2] = Decimal positions, 2 if unspecified
-- Example usage: FCALL_RO TOFIX 2 123.456 2
--                FCALL_RO TOFIX 1 123.456
-- Output: "123.46"
local function toFix(KEYS, ARGV)
  local n = tonumber(KEYS[1])
  local digits = tonumber(KEYS[2]) or 2

  return string.format("%." .. digits .. "f", n)
end


-- Count number of keys and size of a pattern
-- Optional:
--      KEYS[1] = Prefix pattern (e.g., "user:*"), * if unspecified
-- Example usage: FCALL_RO COUNTKEYS 1 fts:chinese:documents:*
--                FCALL_RO COUNTKEYS 0
-- Output:  1) "29104"
--          2) "53.10M"
local function countKeys(KEYS, ARGV)
  local key = KEYS[1] or '*'
  local cursor = "0"
  local totalCount = 0
  local totalSize = 0

  repeat
    local result = redis.call("SCAN", cursor, "MATCH", key, "COUNT", 1000)
    cursor = result[1]
    local keys = result[2]

    for i = 1, #keys do
      totalCount = totalCount + 1
      local size = redis.call("MEMORY", "USAGE", keys[i])
      if size then
        totalSize = totalSize + size
      end
    end
  until cursor == "0"

  return { tostring(totalCount), toFix( { totalSize / 1024 /1024 } )..'M' }
end

-- Delete keys of a pattern
-- Required::
--      KEYS[1] = Prefix pattern (e.g., "user:*")
-- Example usage: FCALL DELALL 1 temp:*
-- Output: 1) Number of keys deleted
local function delall(KEYS, ARGV)
  local pattern = KEYS[1]
  local cursor = "0"
  local deletedCount = 0

  if (pattern == nil or pattern == '*') then
      return -1
  end    
  repeat
      local result = redis.call("SCAN", cursor, "MATCH", pattern, "COUNT", 1000)
      cursor = result[1]
      local keys = result[2]

      for i = 1, #keys do
          redis.call("UNLINK", keys[i])
          deletedCount = deletedCount + 1
      end
  until cursor == "0"

  return deletedCount
end


-- Add member to Sorted Set
-- Required:
--      KEYS[1] = Sorted Set key
--      ARGV[] = One or more members 
-- Example usage: FCALL ZADDINCR 1 testz a b c d e f 
-- Output: 6
local function zAddIncr(KEYS, ARGV) 
  local key = KEYS[1]
  local added = 0
  local n = 0

  for i = 1, #ARGV do
    -- Add with initial score of 1
    added = redis.call('ZADD', key, 'NX', 1, ARGV[i])

    -- Member existed, increment score
    if added == 0 then 
      redis.call('ZINCRBY', key, 1, ARGV[i])
    end
    n = n + 1
  end
  
  return n
end

-- Sum score of Sorted Set
-- Required:
--      KEYS[1] = Sorted Set key
-- Optional: 
--      KEYS[2] = Segment size (optional, default = 1000)
-- Example usage: FCALL_RO ZSUMSCORE 1 testz
-- Output: 6
local function zSumScore(KEYS, ARGV)
  local key = KEYS[1]
  --local segmentSize = tonumber(KEYS[2]) or 1000
  local segmentSize = (KEYS[2] == "0") and 1 or tonumber(KEYS[2]) or 1000
  local total = 0
  local start = 0
  local batch
  
  repeat
    batch = redis.call('ZRANGE', key, start, start + segmentSize - 1, 'WITHSCORES')
    for i = 2, #batch, 2 do
    total = total + tonumber(batch[i])
    end
    start = start + segmentSize
  until #batch == 0
  
  return total
end

--
-- Experimental !!!
-- 
local function debugPrint(message)
  redis.log(redis.LOG_WARNING, 'DEBUG > ' .. (message or ''))
end

local function table_to_string(tbl)
  local parts = {}
  for k, v in pairs(tbl) do
    local key = tostring(k)
    local val = tostring(v)

    if (val == "") then 
      val = "nil"
    end
    table.insert(parts, key .. " = '" .. val .. "'")
  end
  return "{" .. table.concat(parts, ", ") .. "}"
end

-- Builds a key-value table from two equally sized input tables
local function array_to_map(field_name_table, field_value_table)
  local result = {}

  debugPrint()
  debugPrint("field_name_table: " .. table_to_string(field_name_table))
  debugPrint("field_value_table: " .. table_to_string(field_value_table))

  for i = 1, #field_name_table do
    result[field_name_table[i]] = field_value_table[i]
  end

  debugPrint("result_table: " .. table_to_string(result))
  return result
end

-- 
-- Return Redis hashes matching a pattern and has a field which contains a value,
-- 
--  Required:
--      KEYS[1] - Key pattern to scan for, "documents:*" for example;
--      KEYS[2] - Field name to check for, "textChi" for example;
--      KEYS[3] - Value to to check for, "韓非子" for example; 
--  Optional:
--      KEYS[4] - Number of documents to skip, 0 if unspecified; 
--      KEYS[5] - Maximum number of documents to return, 10 if unspecified; 
--      ARGV[]  - Fields to return, ["id", "textChi", "visited"] for example,
--                Return all fields if unspecified.
--  Returns:
--      Array of array contains the documents.
--  Example usage: 
--      FCALL_RO SCANTEXTCHI 5 fts:chinese:documents:* key 鄭文公 0 10  id textChi visited
--      FCALL_RO SCANTEXTCHI 3 fts:chinese:documents:* key 鄭文公
--  Output: 
--
local function scanTextChi(KEYS, ARGV)
  local keyPrefix = KEYS[1]
  local fieldName = KEYS[2]
  local checkValue = KEYS[3]
  local offset = tonumber(KEYS[4]) or 0
  local limit = tonumber(KEYS[5]) or 10
  
  local cursor = "0"  -- the cursor.
  local matched = {}  -- result to be returned 
  local index = 1     -- index to place retrieved value

  repeat
  local scan = redis.call("SCAN", cursor, "MATCH", keyPrefix, "COUNT", 100)
  -- "scan" returns [ cursor, keys ]
  cursor = scan[1]
  local keys = scan[2]

  for _, key in ipairs(keys) do
      -- Get the field value to inspect 
      local text = redis.call("HGET", key, fieldName)
      
      -- If found and contains the value
      if (text) and (string.find(text, checkValue)) then 
      -- Skip offset 
      if offset > 0 then 
          offset = offset - 1
      else 
          -- Take limit 
          if limit > 0 then 
          -- If no field names specified to return 
          if (ARGV[1] or "*") == "*" then
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
      end 
  end
  until (cursor == "0") -- Loop until no more keys found

  -- Scan completed
  return matched
end

--
-- Register Redis Functions 
-- 
redis.register_function{
  function_name='ver',
  callback=ver,
  flags={ 'no-writes' }
}

redis.register_function{
  function_name='libs',
  callback=libs,
  flags={ 'no-writes' }
}

redis.register_function{
  function_name = 'resp3',
  callback = resp3,
    flags = { 'no-writes' }
}

redis.register_function{
  function_name = 'toFix',
  callback = toFix,
  flags = { 'no-writes' }
}

redis.register_function{
  function_name = 'countKeys',
  callback = countKeys,
  flags = { 'no-writes' }
} 

redis.register_function('delall', delall )

redis.register_function('zAddIncr', zAddIncr)

redis.register_function{
  function_name = 'zSumScore',
  callback = zSumScore,
    flags = { 'no-writes' }
}

redis.register_function{
  function_name = 'scanTextChi',
  callback = scanTextChi,
    flags = { 'no-writes' }
}

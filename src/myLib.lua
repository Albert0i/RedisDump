#!lua name=mylib

-- Redis Version
-- No parameter is required:
-- Example usage: FCALL_RO VER 0
-- Output: "8.0.2"
local function ver(KEYS, ARGV)
  return redis.REDIS_VERSION
end

-- Format linux timestamp to YYYY-MM-DD HH:MM:SS.DDD format
-- Required:
--      KEYS[1] = Timestamp to be formatted
-- Optional:
--      KEYS[2] = Timezone, +8 if unspecified
-- Example usage: FCALL_RO FORMATTS 1 1754022140.809510
--                FCALL_RO FORMATTS 2 1754022140.809510 8
-- Output: "2025-08-01 12:22:20.809"
local function formatTS(KEYS, ARGV)
  local offset = tonumber(KEYS[2]) or 8 -- UTC+8
  local ts = tonumber(KEYS[1])
  if not ts then return "Invalid timestamp" end

  ts = ts + (offset * 3600)

  -- Split into whole seconds and milliseconds
  local secFloor = math.floor(ts)
  local millis = math.floor((ts - secFloor) * 1000)

  -- Days in each month (non-leap year)
  local monthDays = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}

  local function isLeap(year)
    return (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
  end

  local minute = math.floor(secFloor / 60) % 60
  local hour = math.floor(secFloor / 3600) % 24
  local days = math.floor(secFloor / 86400)

  local year = 1970
  while true do
    local leap = isLeap(year)
    local daysInYear = leap and 366 or 365
    if days < daysInYear then break end
    days = days - daysInYear
    year = year + 1
  end

  local month = 1
  while true do
    local dim = monthDays[month]
    if month == 2 and isLeap(year) then dim = 29 end
    if days < dim then break end
    days = days - dim
    month = month + 1
  end

  local day = days + 1
  local sec = secFloor % 60

  return string.format("%04d-%02d-%02d %02d:%02d:%02d.%03d", year, month, day, hour, minute, sec, millis)
end

-- Timestamp
-- Optional:
--      KEYS[1] = Timezone, +8 if unspecified
-- Example usage: FCALL_RO TIMESTAMP 0
--                FCALL_RO TIMESTAMP 1 8
-- Output: "2025-08-01 14:49:37.686"
local function timestamp(KEYS, ARGV) 
  local offset = tonumber(KEYS[1]) or 8 -- UTC+8
  local time = redis.call('TIME')
  local timestampPart = time[1]
  local microsecondsPart = time[2]

  return formatTS({ timestampPart + (microsecondsPart / 1000000), offset }) 
end

-- Random
-- Optional:
--      KEYS[1] = Positive value will return integer 1 ~ value; 
--                otherwise returns 0 ~ 1 float point number. 
-- Example usage: FCALL_RO TIMESTAMP 0
--                FCALL_RO TIMESTAMP 1 8
-- Output: "2025-08-01 14:49:37.686"
local function random(KEYS, ARGV)
  local val = tonumber(KEYS[1])

  -- Seed using high-entropy time stamp
  local t = redis.call('TIME')
  math.randomseed(t[1] * 1000000 + t[2])

  if val ~= nil and val > 1 then
      return tostring(math.random(1, math.floor(val)))
  else
      return tostring(math.random())
  end
end

-- Log message 
-- Optional:
--      KEYS[1] = Message to be written to redis.log. 
-- Example usage: FCALL_RO CONSOLELOG 1 "Hello, World!"
--                FCALL_RO CONSOLELOG 0 
-- Output: "Ok"
local function consoleLog(KEYS, ARGV)
  local message = KEYS[1] or 
  '"Years of love have been forgot, In the hatred of a minute." - Edgar Allan Poe'

  redis.log(redis.LOG_WARNING, 'LOG > ' .. message)
  return 'Ok'
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

  local function toFix(number, decimal)
    local n = tonumber(number)
    local digits = tonumber(decimal) or 2
  
    return string.format("%." .. digits .. "f", n)
  end  

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

  return { tostring(totalCount), toFix( totalSize / 1024 /1024 )..'M' }
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

-- Expire keys of a pattern
-- Required::
--      KEYS[1] = Prefix pattern (e.g., "user:*")
--      KEYS[2] = Seconds 
-- Optional: 
--      KEYS[3] = NX | XX | GT | LT
-- Example usage: FCALL DELALL 1 temp:*
-- Output: 1) Number of keys deleted
local function expireall(KEYS, ARGV)
  local pattern = KEYS[1]
  local seconds = tonumber(KEYS[2])
  local option = KEYS[3]
  local validOptions = { NX = true, XX = true, GT = true, LT = true }

  local cursor = "0"
  local expireCount = 0

  if (pattern == nil or pattern == '*') then
      return -1
  end 
  if option and not validOptions[option] then
    return -1
  end  

  repeat
      local result = redis.call("SCAN", cursor, "MATCH", pattern, "COUNT", 1000)
      cursor = result[1]
      local keys = result[2]

      for i = 1, #keys do
          if (option) then 
            redis.call("EXPIRE", keys[i], seconds, option)
          else 
            redis.call("EXPIRE", keys[i], seconds)
          end           
          expireCount = expireCount + 1
      end
  until cursor == "0"

  return expireCount
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
-- local function debugPrint(message)
--   redis.log(redis.LOG_WARNING, 'DEBUG > ' .. (message or ''))
-- end

-- local function table_to_string(tbl)
--   local parts = {}
--   for k, v in pairs(tbl) do
--     local key = tostring(k)
--     local val = tostring(v)

--     if (val == "") then 
--       val = "nil"
--     end
--     table.insert(parts, key .. " = '" .. val .. "'")
--   end
--   return "{" .. table.concat(parts, ", ") .. "}"
-- end

-- Builds a key-value table from two equally sized input tables
-- local function array_to_map(field_name_table, field_value_table)
--   local result = {}

--   debugPrint()
--   debugPrint("field_name_table: " .. table_to_string(field_name_table))
--   debugPrint("field_value_table: " .. table_to_string(field_value_table))

--   for i = 1, #field_name_table do
--     result[field_name_table[i]] = field_value_table[i]
--   end

--   debugPrint("result_table: " .. table_to_string(result))
--   return result
-- end

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
  function_name = 'formatTS',
  callback = formatTS,
  flags = { 'no-writes' }
}

redis.register_function{
  function_name = 'timestamp',
  callback = timestamp,
  flags = { 'no-writes' }
}

redis.register_function{
  function_name = 'random',
  callback = random,
  flags = { 'no-writes' }
}

redis.register_function{
  function_name = 'consoleLog',
  callback = consoleLog,
  flags = { 'no-writes' }
}

redis.register_function{
  function_name = 'countKeys',
  callback = countKeys,
  flags = { 'no-writes' }
} 

redis.register_function('delall', delall )

redis.register_function('expireall', expireall )

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


--
-- Testing !!!
--
-- local function my_hset(keys, args)
--   local hash = keys[1]
--   local time = redis.call('TIME')[1]
--   return redis.call('HSET', hash, '_last_modified_', time, unpack(args))
-- end

-- local function my_hgetall(keys, args)
--   redis.setresp(3)
--   local hash = keys[1]
--   local res = redis.call('HGETALL', hash)
--   res['map']['_last_modified_'] = nil
--   return res
-- end

-- local function my_hlastmodified(keys, args)
--   local hash = keys[1]
--   return redis.call('HGET', hash, '_last_modified_')
-- end

-- redis.register_function('my_hset', my_hset)
-- redis.register_function('my_hgetall', my_hgetall)
-- redis.register_function('my_hlastmodified', my_hlastmodified)

-- 
-- FCALL my_hset 1 myhash myfield "some value" another_field "another value"
-- FCALL my_hgetall 1 myhash 
-- FCALL my_hlastmodified 1 myhash 
-- 

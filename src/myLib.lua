#!lua name=mylib

redis.register_function{
    function_name = 'ver',
    callback = function(KEYS, ARGV)
      -- No parameter is required:
      -- Example usage: FCALL_RO VER 0
      -- Output: "8.0.2"
      return redis.REDIS_VERSION
    end,
    flags = { 'no-writes' }
  }  

redis.register_function{
    function_name = 'toFix',
    callback = function(KEYS, ARGV)
      -- Required:
      --      KEYS[1] = Number to be rounded
      -- Optional:
      --      KEYS[2] = Decimal positions, 2 if unspecified
      -- Example usage: FCALL_RO TOFIX 2 123.456 2
      --                FCALL_RO TOFIX 1 123.456
      -- Output: "123.46"

      local n = tonumber(KEYS[1])
      local digits = tonumber(KEYS[2]) or 2
  
      return string.format("%." .. digits .. "f", n)
    end,
    flags = { 'no-writes' }
  }


redis.register_function{
    function_name = 'countKeys',
    callback = function(KEYS, ARGV)
      -- Optional:
      --      KEYS[1] = Prefix pattern (e.g., "user:*"), * if unspecified
      -- Example usage: FCALL_RO COUNTKEYS 1 fts:chinese:documents:*
      --                FCALL_RO COUNTKEYS 0
      -- Output:  1) "29104"
      --          2) "53.10M"

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
  
      local totalSizeHuman = string.format("%.2f", totalSize / 1024 / 1024) .. 'M'
      return { tostring(totalCount), totalSizeHuman }
    end,
    flags = { 'no-writes' }
  } 

redis.register_function('delall', function(KEYS, ARGV)
    -- Required::
    --      KEYS[1] = Prefix pattern (e.g., "user:*")
    -- Example usage: FCALL DELALL 1 temp:*
    -- Output: 1) Number of keys deleted

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
  end )

redis.register_function('zAddIncr', function(KEYS, ARGV) 
    -- Required:
    --      KEYS[1] = Sorted Set key
    --      ARGV[] = One or more members 
    -- Example usage: FCALL ZADDINCR 1 testz a b c d e f 
    -- Output: 6

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
  end )

redis.register_function{
  function_name = 'zSumScore',
  callback = function(KEYS, ARGV)
      -- Required:
      --      KEYS[1] = Sorted Set key
      -- Optional: 
      --      KEYS[2] = Segment size (optional, default = 1000)
      -- Example usage: FCALL_RO ZSUMSCORE 1 testz
      -- Output: 6

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
    end,
    flags = { 'no-writes' }
  }


redis.register_function{
  function_name = 'scanTextChi',
  callback = function(KEYS, ARGV)
    --[[
      Lua script to scan Redis for hashes matching "document:*"
      and return HASH objects.

      Required:
          KEYS[1] - Key pattern to scan for, "documents:" for example;
          KEYS[2] - Field name to scan for, "textChi" for example;
          KEYS[3] - Value to scan for, "韓非子" for example; 
      Optional:
          KEYS[4] - The number of documents to skip, 0 if unspecified; 
          KEYS[5] - The maximum number of documents to return, 10 if unspecified; 
          ARGV[] - Fields to be returned, ["id", "textChi", "visited"] for example. 
                  All fields will be returned if unspecified.
      Returns:
          Array of array contains the documents.
      Example usage: 
          FCALL_RO SCANTEXTCHI 5 fts:chinese:documents:* key 鄭文公 0 10  id textChi visited
          FCALL_RO SCANTEXTCHI 3 fts:chinese:documents:* key 鄭文公
      Output: 
    --]]
    
      local offset = tonumber(KEYS[4]) or 0
      local limit = tonumber(KEYS[5]) or 10

      local cursor = "0"  -- the cursor.
      local matched = {}  -- result to be returned 
      local index = 1     -- index to place retrieved value

      repeat
      local scan = redis.call("SCAN", cursor, "MATCH", KEYS[1], "COUNT", 100)
      -- "scan" returns [cursor, keys] 
      cursor = scan[1]
      local keys = scan[2]

      for _, key in ipairs(keys) do
          -- Get the field value to inspect 
          local text = redis.call("HGET", key, KEYS[2])
          
          -- If found and contains the value
          if (text) and (string.find(text, KEYS[3])) then 
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
    end,
    flags = { 'no-writes' }
  }

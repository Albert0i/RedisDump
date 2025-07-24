#!lua name=mylib

redis.register_function('ver', function(KEYS, ARGV) 
    -- No parameter is required: 
    -- Example usage: FCALL VER 0
    -- Output: "8.0.2"

    return redis.REDIS_VERSION 
end )

redis.register_function('toFix', function(KEYS, ARGV)
    -- Required: 
    --      KEYS[1] = Number to be rounded
    -- Optional: 
    --      KEYS[2] = Dcimal positions, 2 if unspecified
    -- Example usage: FCALL TOFIX 2 123.456 2
    --                FCALL TOFIX 1 123.456
    -- Output: "123.46"

    local n = KEYS[1]
    local digits = KEYS[2] or 2

    return string.format("%." .. (digits or 0) .. "f", n)
end )

redis.register_function('countKeys', function(KEYS, ARGV)
    -- Optional: 
    --      KEYS[1] = Prefix pattern (e.g., "user:*"), * if unspecified 
    -- Example usage: FCALL COUNTKEYS 1 fts:chinese:documents:*
    --                FCALL COUNTKEYS 0
    -- Output:  1) "29104"
    --          2) "53.10M"

    local key = KEYS[1] or '*'
    local cursor = "0"
    local totalCount = 0 
    local totalSize = 0 
    local totalSizeHuman = 0

    repeat
    local result = redis.call("SCAN", cursor, "MATCH", key, "COUNT", 1000)
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

    totalSizeHuman = string.format("%." .. (2) .. "f", totalSize / 1024 /1024) .. 'M'

    -- return { totalCount, totalSize }
    return { totalCount, totalSizeHuman }
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

redis.register_function('zSumScore', function(KEYS, ARGV) 
    -- Required:
    --      KEYS[1] = Sorted Set key
    -- Example usage: FCALL ZSUMSCORE 1 testz
    -- Output: 6

    local key = KEYS[1]
    local total = 0
    local members = redis.call('ZRANGE', key, 0, -1, 'WITHSCORES')

    for i = 2, #members, 2 do
    total = total + tonumber(members[i])
    end

    return total
end )

redis.register_function('scanTextChi', function(KEYS, ARGV) 
    --[[
    Lua script to scan Redis for hashes matching "document:*"
    and return HASH objects.

    Required: :
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
        FCALL SCANTEXTCHI 5 fts:chinese:documents:* key 鄭文公 0 10  id textChi visited
        FCALL SCANTEXTCHI 3 fts:chinese:documents:* key 鄭文公
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
end )


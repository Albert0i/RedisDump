#!lua name=mylib

redis.register_function('ver', function(KEYS, ARGV) 
    -- No parameter is required: 
    -- Example usage: FCALL VER 0
    -- Output: "8.0.2"

    return redis.REDIS_VERSION 
end )

redis.register_function('toFix', function(KEYS, ARGV)
    -- KEYS[1] = Number to be rounded
    -- KEYS[2] = Dcimal positions
    -- Example usage: FCALL TOFIX 2 123.456 2
    -- Output: "123.46"

    local n = KEYS[1]
    local digits = KEYS[2]

    return string.format("%." .. (digits or 0) .. "f", n)
end )

redis.register_function('countKeys', function(KEYS, ARGV)
    -- KEYS[1] = Prefix pattern (e.g., "user:*")
    -- Example usage: FCALL COUNTKEYS 1 fts:chinese:documents:*
    -- Output:  1) "29104"
    --          2) "53.10M"

    local cursor = "0"
    local totalCount = 0 
    local totalSize = 0 
    local totalSizeHuman = 0

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

    totalSizeHuman = string.format("%." .. (2) .. "f", totalSize / 1024 /1024) .. 'M'

    -- return { totalCount, totalSize }
    return { totalCount, totalSizeHuman }
end )

redis.register_function('zAddIncr', function(KEYS, ARGV) 
    -- KEYS[1] = Sorted Set key
    -- ARGV[] = One or more members 
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
    -- KEYS[1] = Sorted Set key
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

    Parameters:
        KEYS[1] - Key pattern to scan for, "documents:" for example;
        KEYS[2] - Field name to scan for, "textChi" for example;
        KEYS[3] - Value to scan for, "韓非子" for example; 
        KEYS[4] - The number of documents to skip, '0' for example; 
        KEYS[5] - The maximum number of documents to return, '10' for example; 
        ARGV[] - Fields to be returned, ["id", "textChi", "visited"] for example.

    Returns:
        Array of array contains the documents.
    --]]
    local offset = tonumber(KEYS[4])
    local limit = tonumber(KEYS[5])

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
        end 
    end
    until (cursor == "0") -- Loop until no more keys found

    -- Scan completed
    return matched
end )

redis.register_function('fsTextChi', function(KEYS, ARGV) 
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
end )

redis.register_function('getVisitedDocs', function(KEYS, ARGV) 
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
end )


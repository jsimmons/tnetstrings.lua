--[[
    tnetstring implementation

--]]

-- We don't have to local these since we're not using module, but we will
-- anyway for performance' sake.
local find = string.find
local sub = string.sub
local len = string.len
local tonumber = tonumber
local type = type

-- Since nil can't be stored in a Lua table, we need a sentinal value to take
-- its place.
local function null()
    return null -- Trick stolen from Json4Lua, returns itself.
end

-- We need access to the parse function from the parsers, so do it this way
local parse

local parsers = {
    [','] = function(blob, blob_length, blob_type, extra)
        return blob, extra
    end;

    ['#'] = function(blob, blob_length, blob_type, extra)
        local n = tonumber(blob)
        if not n then
            return nil, 'could not parse number payload'
        end
        return n, extra
    end;

    ['!'] = function(blob, blob_length, blob_type, extra)
        if blob == 'true' then
            return true, extra
        elseif blob == 'false'
            then return false, extra
        else
            return nil, 'invalid boolean payload'
        end
    end;

    ['~'] = function(blob, blob_length, blob_type, extra)
        return null, extra
    end;
    
    [']'] = function(blob, blob_length, blob_type, extra)
        if blob_length == 0 then
            return {}
        end

        local result, n = {}, 1

        local val, ext = nil, blob
        repeat
            val, ext = parse(ext)

            -- If val is nil, then ext is actually an error message.
            if not val then
                return val, ext
            end

            result[n] = val
            n = n + 1
        until not ext

        return result, extra
    end;

    ['}'] = function(blob, blob_length, blob_type, extra)
        if blob_length == 0 then
            return {}
        end
        
        local result = {}

        local key, val, ext = nil, nil, blob
        repeat
            key, ext = parse(ext)

            if not key then
                return nil, ext
            end
            if type(key) ~= 'string' then
                return nil, 'dict keys must be strings'
            end
            if not ext then
                return nil, 'unbalanced dict'
            end

            local val, ext = parse(ext)
            if not val then
                return nil, ext
            end

            result[key] = val
        until not ext

        return result, extra
    end;
}

parse = function(data)
    -- Find the interesting points in the data.
    local colon_pos = find(data, ':', 1, true)
    if not colon_pos then
        return nil, 'could not find colon'
    end

    local length = tonumber(sub(data, 1, colon_pos - 1))
    if not length then
        return nil, 'no blob length found'
    end

    local blob_begin = colon_pos + 1
    local blob_end = colon_pos + length
    local blob = sub(data, blob_begin, blob_end)
    local blob_type = sub(data, blob_end + 1, blob_end + 1)

    if len(blob) ~= length then
        return nil, 'invalid blob length'
    end
    if len(blob_type) ~= 1 then
        return nil, 'could not find type code'
    end

    local extra = sub(data, blob_end + 2)
    if len(extra) == 0 then
        extra = nil
    end

    local parser = parsers[blob_type]
    if not parser then
        return nil, 'invalid type code'
    end

    return parser(blob, length, blob_type, extra)
end

local function dump()

end

return {
    parse = parse;
    dump = dump;
    null = null;
}


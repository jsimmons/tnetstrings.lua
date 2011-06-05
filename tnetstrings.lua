--[[
    tnetstring implementation

    Joshua Simmons
--]]

-- We don't have to local these since we're not using module, but we will
-- anyway for performance' sake.
local concat = table.concat
local error = error
local find = string.find
local len = string.len
local sub = string.sub
local tonumber = tonumber
local tostring = tostring
local type = type

-- Since nil can't be stored in a Lua table, we need a sentinal value to take
-- its place.
local function null()
    return null -- Trick stolen from Json4Lua, returns itself.
end

-- We need access to the parse function from the parsers, so do it this way
local parse

local parsers = {
    -- Blob, plain ol data.
    [','] = function(blob, blob_length, blob_type, extra)
        return blob, extra
    end;

    -- Number, well, integer, but we're going to use lua's tonumber anyway.
    ['#'] = function(blob, blob_length, blob_type, extra)
        local n = tonumber(blob)
        if not n then
            return nil, 'could not parse number payload'
        end
        return n, extra
    end;

    -- Boolean, we check the text even though it's not strictly necessary for
    -- a reasonable implementation.
    ['!'] = function(blob, blob_length, blob_type, extra)
        if blob == 'true' then
            return true, extra
        elseif blob == 'false'
            then return false, extra
        else
            return nil, 'invalid boolean payload'
        end
    end;

    -- Null, has to be 0 in length.
    ['~'] = function(blob, blob_length, blob_type, extra)
        if blob_length ~= 0 then
            return nil, 'null must have 0 length'
        end

        return null, extra
    end;
    
    -- List, we just put it in a table.
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

    -- Dictionary, we just put it in a table too.
    ['}'] = function(blob, blob_length, blob_type, extra)
        if blob_length == 0 then
            return {}
        end
        
        local result = {}

        local key, val, ext = nil, nil, blob
        repeat
            key, ext = parse(ext, ',')

            if not key then
                return nil, ext
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

-- Takes a data string and returns a single tns value from it. Any remaining
-- data is also returned. In case of parsing errors, or if the expected type
-- does not match the type found, then the function returns nil followed by an
-- error message. For simplicities sake, the expected type is given as a tns
-- string type code.
parse = function(data, expected)
    assert(type(data) == 'string')

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

    if expected and expected ~= blob_type then
        return nil, 'type did not match expected'
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

local list_mt = {
    __tostring = function() return 'tns list' end;
}

-- Wrap up a table so it's treated as an array.
local function list(tab, n)
    if not n then
        n = #tab
    end

    return setmetatable({data = tab, n = n}, list_mt)
end

local function insert(into, data)
    local n = (into.n or 0) + 1
    into[n] = data
    into.n = n
end

-- We need access to the dump method from the dumpers so declare this here
local dump

local dumpers = {
    ['string'] = function(str, target)
        local length = len(str)
        insert(target, tostring(length))
        insert(target, ':')
        insert(target, str)
        insert(target, ',')
    end;

    ['number'] = function(num, target)
        local str = tostring(num)
        local length = len(str)
        insert(target, tostring(length))
        insert(target, ':')
        insert(target, str)
        insert(target, '#')
    end;

    ['function'] = function(f, target)
        if f == null then
            insert(target, '0:~')
        else
            error('cannot encode functions')
        end
    end;

    ['boolean'] = function(b, target)
        if b then
            insert(target, '4:true!')
        else
            insert(target, '5:false!')
        end
    end;

    ['table'] = function(tab, target)
        local payload = {}
        if tostring(tab) == 'tns list' then
            -- list
            local n, data = tab.n, tab.data
            for i = 1, n do
                insert(payload, dump(data[i]))
            end
            
            -- be a little bit tricky and append the type char here, remember
            -- to take one away from the payload length!
            insert(payload, ']')
        else
            -- dict
            for k, v in pairs(tab) do
                if type(k) ~= 'string' then
                    error('dict keys must be strings')
                end

                insert(payload, dump(k))
                insert(payload, dump(v))
            end

            -- same issue as list
            insert(payload, '}')
        end

        local payload_str = concat(payload, '')

        -- We have to take one away because we added the type char to the end
        local payload_len = len(payload_str) - 1

        insert(target, tostring(payload_len))
        insert(target, ':')
        insert(target, payload_str)
    end;
}

-- Takes a Lua object and returns a tnetstring representation of it.
-- Unlike the decode method, this aborts with an error if you feed it bad data.
dump = function(object)
    local output = {}

    local t = type(object)
    local dumper = dumpers[t]

    if not dumper then
        error('unable to dump type ' .. t, 2)
    end

    dumper(object, output)

    return concat(output, '')
end

return {
    parse = parse;
    list = list;
    dump = dump;
    null = null;
}


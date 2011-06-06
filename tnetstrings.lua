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

-- Since nil can't be stored in a Lua table, we need a sentinel value to take
-- its place.
local function null()
    return null -- Trick stolen from Json4Lua, returns itself.
end

-- We need access to the parse function from the parsers, so do it this way
local parse

local parsers = {
    -- Blob, plain ol data.
    [','] = function(data, offset, length)
        return sub(data, offset, offset + length - 1)
    end;

    -- Number, well, integer, but we're going to use lua's tonumber anyway.
    ['#'] = function(data, offset, length)
        local n = tonumber(sub(data, offset, offset + length - 1))
        if not n then
            return nil, 'could not parse number payload'
        end
        return n
    end;

    -- Boolean, we check the text even though it's not strictly necessary for
    -- a reasonable implementation.
    ['!'] = function(data, offset, length)
        local blob = sub(data, offset, offset + length - 1)
        if blob == 'true' then
            return true, extra
        elseif blob == 'false'
            then return false, extra
        else
            return nil, 'invalid boolean payload'
        end
    end;

    -- Null, has to be 0 in length.
    ['~'] = function(data, offset, length)
        if length ~= 0 then
            return nil, 'null must have 0 length'
        end

        return null
    end;
    
    -- List, we just put it in a table.
    [']'] = function(data, offset, length)
        if length == 0 then
            return {}
        end

        local result, n = {}, 1

        local val, ext_pos = nil, offset
        repeat
            val, ext_pos = parse(data, nil, ext_pos)

            -- If val is nil, then ext is actually an error message.
            if val == nil then
                return val, ext_pos
            end

            result[n] = val
            n = n + 1
        until ext_pos == (offset + length)

        return result
    end;

    -- Dictionary, we just put it in a table too.
    ['}'] = function(data, offset, length)
        if length == 0 then
            return {}
        end
        
        local result = {}

        local key, val, ext_pos = nil, nil, offset
        repeat
            key, ext_pos = parse(data, ',', ext_pos)

            if key == nil then
                return nil, ext
            end

            if not ext_pos then
                return nil, 'unbalanced dict'
            end

            val, ext_pos = parse(data, nil, ext_pos)
            if val == nil then
                return nil, ext
            end

            result[key] = val
        until ext_pos == (offset + length)

        return result
    end;
}

-- Takes a data string and returns a single tns value from it. Any remaining
-- data is also returned. In case of parsing errors, or if the expected type
-- does not match the type found, then the function returns nil followed by an
-- error message. For simplicities sake, the expected type is given as a tns
-- string type code.
parse = function(data, expected, offset)
    assert(type(data) == 'string')

    offset = offset or 1

    -- Find the interesting points in the data.
    local colon_pos = find(data, ':', offset, true)
    if not colon_pos then
        return nil, 'could not find colon'
    end

    local length = tonumber(sub(data, offset, colon_pos - 1))
    if not length then
        return nil, 'no blob length found'
    end

    local blob_begin = colon_pos + 1
    local blob_end = colon_pos + length
    local blob_type = sub(data, blob_end + 1, blob_end + 1)

    if len(blob_type) ~= 1 then
        return nil, 'could not find type code'
    end

    if expected and expected ~= blob_type then
        return nil, 'type did not match expected'
    end

    local parser = parsers[blob_type]
    if not parser then
        return nil, 'invalid type code'
    end

    return parser(data, blob_begin, length), blob_end + 2
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

    -- We treat any tables with an array part as arrays.
    ['table'] = function(tab, target)
        local payload = {}
        -- We already know this is a table, so this is well defined.
        local n = #tab
        if n > 0 then
            -- list
            for i = 1, n do
                insert(payload, dump(tab[i]))
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
    null = null;
    parse = parse;
    dump = dump;
}


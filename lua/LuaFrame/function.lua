-- callback
local callbacks = setmetatable({}, { __mode = "k" })

local function callback(fn, obj)
    if obj == nil then return fn end

    local t = callbacks[obj]
    if t == nil then
        t = {}
        callbacks[obj] = t
    end
    if t[fn] == nil then
        t[fn] = function(...) fn(obj, ...) end
    end
    return t[fn]
end
declare("callback", callback)

local function trace(...)
    if __EDITMODE then
        print(...)
    end
end
declare("trace", trace)

-- tryget
local function tryget(tbl, key)
    local value = rawget(tbl, key)
    return value ~= nil, value
end
declare("tryget", tryget)

-- tryset
local function tryset(to, toKey, from, fromKey)
    local value = rawget(from, fromKey)
    if value ~= nil and value ~= to[toKey] then
        to[toKey] = value
        return true
    end
    return false
end
declare("tryset", tryset)

-- table.tostring, print_r
local _print = print
local function table_tostring(t, done, eof, depth ,filterKeys)
    done = done or {}
    local result = {}
    if pcall(pairs, t) then
        for k, v in pairs(t) do
            if type(k) ~= "string" or not string.match(k, "^__") then
                local key = type(k) == "string" and tostring(k) or ("[" .. tostring(k) .. "]")
                local show = true
                if filterKeys then
                    for i=1,#filterKeys do
                        if key == filterKeys[i] then
                            show = false
                            break
                        end
                    end
                end
                if show then
                    local ident = depth and string.rep("\t", depth + 1) or ""
                    if type(v) == "table" then
                        -- if done[v] then
                        --     table.insert(result, string.format("%s%s=[%s]", ident, key, tostring(v)))
                        -- else
                        --     done[v] = true
                            table.insert(result, string.format("%s%s=%s", ident, key, table_tostring(v, done, eof, depth and depth + 1 or nil,filterKeys)))
                        -- end
                    elseif type(v) == "string" then
                        table.insert(result, string.format("%s%s=%q", ident, key, tostring(v)))
                    elseif type(v) == "function" then
                        table.insert(result, string.format("%s%s=[%s]", ident, key, tostring(v)))
                    else
                        table.insert(result, string.format("%s%s=%s", ident, key, tostring(v)))
                    end
                end
            end
        end
    end
    return string.format("{%s%s%s%s}", eof, table.concat(result, ", " .. eof), eof, depth and string.rep("\t", depth) or "")
end

function table.tostring(t, filterKeys, formatted)
    --assert(type(t) == "table")
    if type(t) == "table" then
        formatted = formatted == true or formatted == nil
        return table_tostring(t, {}, formatted and "\n" or "", formatted and 0 or nil,filterKeys)
    else
        return t
    end
end
-- 清除table值
function table.clear(t, arr)
    if arr then
        local count = #t
        for i = 1, count do t[i] = nil end
    else
        for k in pairs(t) do t[k] = nil end
    end
end

local function print_r(...)
    local values = table.pack(...)
    for i, v in ipairs(values) do
        if type(v) == "table" then
            values[i] = table_tostring(v, {}, "")
        else
            values[i] = tostring(v)
        end
    end
    _print(table.unpack(values))
end
declare("print_r", print_r)

function table.print(t)
    print(table.tostring(t,nil, true));
end

-- 计算字符串长度，中文算2个字符
function string.count(s)
    local count = 0
    local i, len = 1, s:len()
    while i <= len do
        local flag = s:byte(i) >> 4
        if flag < 8 then                       -- 0xxx xxxx
            count = count + 1
            i = i + 1
        elseif flag == 12 or flag == 13 then   -- 110x xxxx
            count = count + 2
            i = i + 2
        elseif flag == 14 then                 -- 1110 xxxx
            count = count + 2
            i = i + 3
        end
    end
    return count
end

-- 指定返回值的范围
function math.clamp(v, min, max)
    if v < min then
        v = min
    elseif max < v then
        v = max
    end
    return v
end

function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields + 1] = c end)
    return fields
end

function table.clone(t, nometa)
    if not t then
        return
    end
    local u = {}

    if not nometa then
        setmetatable(u, getmetatable(t))
    end

    for i, v in pairs(t) do
        if type(v) == "table" then
            u[i] = table.clone(v)
        else
            u[i] = v
        end
    end

    return u
end

function table.size(t)
    local s = 0;
    for k, v in pairs(t) do
        if v ~= nil then s = s + 1; end
    end
    return s;
end

function table.indexOf(t, v)
    for i, v_ in ipairs(t) do
        if v_ == v then return i end
    end
    return nil
end

--查找
function table.find(t, func)
    for k, v in pairs(t) do
        if func(v) then return v end
    end
    return nil
end

--查找key
function table.findKey(t, func)
    for k, v in pairs(t) do
        if func(v) then return k end
    end
    return nil
end

--查找索引
function table.findIndex(t, func)
    for i, v in ipairs(t) do
        if func(v) then return i end
    end
    return nil
end

function table.union(t0, t1)
    local t = {}
    for i, v in ipairs(t0) do table.insert(t, v) end
    for i, v in ipairs(t1) do table.insert(t, v) end
    return t
end

function table.appendList(t0, t1)
    for i, v in ipairs(t1) do table.insert(t0, v) end
end

function table.filter(t, func)
    local matches = {}
    for k, v in pairs(t) do
        if func(v, k) then table.insert(matches, v) end
    end

    return matches
end

function table.contains(t0, t1)
    if (not t0) then return false end
    if (not t1) then return true end
    for k, v in pairs(t1) do
        if (not t0[k]) then
            return false
        end
    end
    return true
end

function table.equal(t0, t1)
    return table.contains(t0, t1) and table.contains(t1, t0)
end

--映射
function table.map(t, func)
    local newT = {}
    for k, v in pairs(t) do
        newT[k] = func(v);
    end
    return newT;
end


--四舍五入
function math.round(value)
    return math.floor(value + 0.5)
end
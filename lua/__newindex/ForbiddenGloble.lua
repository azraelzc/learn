local __g = _G
-- export global variable
local cc = {}
cc.exports = {}
setmetatable(cc.exports, {
    __newindex = function(_, name, value)
        rawset(__g, name, value)
    end,

    __index = function(_, name)
        return rawget(__g, name)
    end
})

-- disable create unexpected global variable
setmetatable(__g, {
    __newindex = function(_, name, value)
        local msg = "USE 'cc.exports.%s = value' INSTEAD OF SET GLOBAL VARIABLE"
        error(string.format(msg, name), 0)
    end
})

-- export global
cc.exports.MY_GLOBAL = "hello"
-- use global
print(MY_GLOBAL)
-- or
print(_G.MY_GLOBAL)
-- or
print(cc.exports.MY_GLOBAL)

-- delete global
cc.exports.MY_GLOBAL = nil

-- global function
local function test_function_()
end
cc.exports.test_function = test_function_

-- if you set global variable, get an error
INVALID_GLOBAL = "no"
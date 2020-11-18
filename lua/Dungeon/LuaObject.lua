local Object = {}
Object.__index = Object
function Object:new()
end

function Object:extend()
    local SubClass = {}
    for k, v in pairs(self) do
        SubClass[k] = v
    end
    SubClass.__index = SubClass
    SubClass.super = self
    setmetatable(SubClass, self)
    return SubClass
end

function Object:__call(...)
    local object = setmetatable({}, self)
    object:new(...)
    return object
end

return Object
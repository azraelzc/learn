local LuaObject = require("LuaObject")

local Person = LuaObject:extend()

function Person:new(name)
	print("===Person:new==",name)
    Person.super.new(self)
    self.name = name
end

function Person:print()
    print("name is ", self,self.name)
end

function Person:idle()
    print(" idle ")
end

return Person
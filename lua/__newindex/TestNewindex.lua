local mt = {
	__newindex = function (t,name,value)
		print("---newindex---",t,name,value)
		rawset(t,name,value)
	end
}

local t = {}
setmetatable(t,mt)
t.name = "111"
print(t)
print(t.name)
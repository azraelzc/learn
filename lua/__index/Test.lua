print("===start===")

local Student = require("Student")
local sList = {}

for i=1,3 do
	local s = Student("name"..i,i*10)
	table.insert(sList,s)
end

print("===#sList===",#sList)

for i=1,#sList do
	local s = sList[i]
	s:print()
end

print("===end===")

local message = "sequence id check failed last:3131 now:3125"
local startIndex,endIndex = string.find(message,"now")
local str = string.sub(message,startIndex,#message)

print(string.find(message,"aaa"))
print(str)
local file = io.open("testFile.txt", "a")
print("==file==",file)
local time = os.date("%Y/%m/%d %H:%M:%S", os.time())
local log = "\n"..time .. "\n test log"
io.write(log)
io.close(file)
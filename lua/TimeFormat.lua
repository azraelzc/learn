local time = 1598337074
local function formatCountdown(timestamp)
	local h = 0
	local m = 0
	local s = 0
	if timestamp >= 3600 then
		h = math.modf(timestamp/3600)
		timestamp = math.mod(timestamp,60)
	end
	print("===h===",h,timestamp)
	if timestamp >= 60 then
		m = math.modf(timestamp/60)
		timestamp = math.mod(timestamp,60)
	end 
	print("===m===",m,timestamp)
	s = timestamp
	return string.format("%02d:%02d:%02d",h,m,s)
end 

local function formatToDateTime(timestamp)
	return os.date("%Y/%m/%d %H:%M:%S",unixtime)
end

local function timeInterval()
	local s = os.clock()
	local e = os.clock()
	print(" s "..s)
	print("used time"..e-s.." seconds")
end
print(formatToDateTime(time))

timeInterval()
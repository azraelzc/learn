local  M = {}

local testStr = "@张新颖，他胡说"

function M.RemoveRichSymbol(str)
	local lenInByte = #str
	local i = 1
	local hasRichSymbol = false
	local startRichIndex = 0
	local endRichIndex = 0
	while true do
        if i > lenInByte or (hasRichSymbol and endRichIndex > 0) then
            break
        end
		local curByte = string.byte(str, i)
        if curByte == 60 then
			hasRichSymbol = true
			startRichIndex = i
		elseif curByte == 62 then
			endRichIndex = i
		end
		i = i + 1
    end
	if hasRichSymbol then
		str = M.StringRemove(str,startRichIndex,endRichIndex)
		str = M.RemoveRichSymbol(str)
	end
	
	return str
end

--[[
utf-8编码规则
单字节 - 0起头
   1字节  0xxxxxxx   0 - 127
多字节 - 第一个字节n个1加1个0起头
   2 字节 110xxxxx   192 - 223
   3 字节 1110xxxx   224 - 239
   4 字节 11110xxx   240 - 247
可能有1-4个字节
返回文字占用长度和视觉上占用长度
--]]
local function checkCharCode(charCode)
	print("====",charCode)
	if charCode == 64 or charCode == 37 then
		return 1,3
	elseif charCode < 127 then
      return 1,1
	elseif charCode <= 223 then
      return 2,2
	elseif charCode <= 239 then
      return 3,2
	elseif charCode <= 247 then
      return 4,2
	else
      -- 讲道理不会走到这里^_^
      return 0,0
	end
end

function M.GetStrWordNum(str)
    local fontSize = 20
    local lenInByte = #str
    local count = 0
    local i = 1
    while true do
        if i > lenInByte then
            break
        end
		local curByte = string.byte(str, i)
        local byteCount = checkCharCode(curByte)
		print("==byteCount==",byteCount)
        if byteCount > 0 then
			i = i + byteCount
			count = count + 1
		end
    end
    return count
end

function M.GetStrLen(str)
    local lenInByte = #str
    local width = 0
    local i = 1
    while true do
        if i > lenInByte then
            break
        end
		local curByte = string.byte(str, i)
        local byteCount,fontSize = checkCharCode(curByte)
        i = i + byteCount
        width = width + fontSize
    end
    return width
end

function M.StringSub(str, startIndex, endIndex)
   local tempStr = str 
   local byteStart = 1 -- string.sub截取的开始位置
   local byteEnd = -1 -- string.sub截取的结束位置
   local index = 0  -- 字符记数
   local bytes = 0  -- 字符的字节记数

   startIndex = math.max(startIndex, 1)
   endIndex = endIndex or -1
   while string.len(tempStr) > 0 do    
      if index == startIndex - 1 then
         byteStart = bytes+1;
      elseif index == endIndex then
         byteEnd = bytes;
         break;
      end
	  local curByte = string.byte(str, bytes+1)
	  if curByte == nil then
		byteEnd = endIndex
		break
	  end
      bytes = bytes +checkCharCode(curByte)
      index = index + 1
   end
   return string.sub(str, byteStart, byteEnd)
end

function M.StringRemove(str,startIndex, endIndex)
	local removeStr = string.sub(str, startIndex, endIndex)
	return string.gsub(str, removeStr, "")
end

--文字显示长度限制并省略
function M.GetOmitString(str,len,omitStr)
	str = M.RemoveRichSymbol(str)
    local strLen = M.GetStrWordNum(str)
    local retStr = ""
    if strLen <= len then
        retStr = str
    else
        retStr = M.StringSub(str,1,len-1)
        if omitStr then
            retStr = retStr .. omitStr
        end
    end
    return retStr
end

print(M.GetStrLen(testStr))
--M.RemoveRichSymbol(testStr)
--print(M.GetOmitString(testStr,10,"..."))
--print(M.Sub(testStr,1,3))
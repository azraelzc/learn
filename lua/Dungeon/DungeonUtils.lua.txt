local csv = require("Dungeon.LuaCallCsvData")
local dungeonDefine = require("Dungeon.DungeonDefine")

local M = {}

function M.commonRandom(tDatas,tWeights)
    local total = 0
    local index = 0
    local retData
    for i=1,#tWeights do
        total = total + tWeights[i]
    end
    local rNum = math.random(1,total)
    for i=1,#tWeights do
        total = total - tWeights[i]
        if total <= rNum then
            index = i
            retData = tDatas[i]
            table.remove(tDatas,i)
            table.remove(tWeights,i)
            break
        end
    end
    return retData,tDatas,tWeights,index
end

function M.copyTable(t,depth)
    local newT = {}
    depth = depth or 1
    if depth >= 10 then
        return t
    end
    for k,v in pairs(t) do
        if type(v) == "table" then
            newT[k] = M.copyTable(v,depth+1)
        else
            newT[k]= v
        end
    end
    return newT
end

function M.PairTabMsg( tab, closeTab, depth, msg )
    closeTab = closeTab or {}
    depth = depth or 1
    msg = msg or ""
    if depth >= 10 then
        return msg
    end
    if depth == 1 then
        msg = msg .. tostring(tab) .. "  "
    end
    if type(tab) == "table" then
        -- print("  now  print  : ", depth, tab )
        local t1 = ""
        for i=1,depth-1 do
            t1 = t1 .. "\t"
        end
        local tt = t1 .. "\t"
        -- msg = msg .. "\n" .. t1 .. "{"
        msg = msg .. "{"
        for k,v in pairs(tab) do
            -- print("  now  in  : ", depth, k, v )
            if type(v) == "table" then
                local f = true
                for i,cv in ipairs(closeTab) do
                    if cv == v then
                        f = false
                        break
                    end
                end
                if f then
                    table.insert(closeTab, v)
                    msg = msg .. "\n" .. tt .. k .. " : "
                    local m2 = M.PairTabMsg(v, closeTab, depth+1 )
                    msg = msg .. m2
                    -- print("  here  is m2 : ", m2)
                end
            else
                msg = msg .. "\n" .. tt .. k .. " : " .. tostring(v)
            end
        end
        msg = msg .. "\n" .. t1 .. "}"
    else
        msg = tostring(tab)
    end
    return msg
end

--字符串分割函数,按|分割
function M.split(str, split_char)      
    local sub_str_tab = {}
    while true do          
        local pos = string.find(str, split_char) 
        if not pos then              
            table.insert(sub_str_tab,str)
            break
        end  
        local sub_str = string.sub(str, 1, pos - 1)              
        table.insert(sub_str_tab,sub_str)
        str = string.sub(str, pos + 1, string.len(str))
    end      
    return sub_str_tab
end

local function GetEffectStr(retStr,effectId,level,overlay)
    local length = CS.JumpCSV.DungeonEffectCsvData.EffectRoundNumberArray(effectId).Length
    if length >= level then
        retStr = string.gsub(retStr,"{0}",math.abs(CS.JumpCSV.DungeonEffectCsvData.EffectRoundNumberFromArray(effectId,level-1)))
    end
    length = CS.JumpCSV.DungeonEffectCsvData.TriggerRoundArray(effectId).Length
    if length >= level then
        retStr = string.gsub(retStr,"{1}",math.abs(CS.JumpCSV.DungeonEffectCsvData.TriggerRoundFromArray(effectId,level-1)))
    end
    length = CS.JumpCSV.DungeonEffectCsvData.EffectPara1Array(effectId).Length
    if length >= level then
        retStr = string.gsub(retStr,"{2}",math.floor(math.abs(CS.JumpCSV.DungeonEffectCsvData.EffectPara1FromArray(effectId,level-1)/10))*overlay)
    end
    length = CS.JumpCSV.DungeonEffectCsvData.EffectPara2Array(effectId).Length
    if length >= level then
        retStr = string.gsub(retStr,"{3}",math.floor(math.abs(CS.JumpCSV.DungeonEffectCsvData.EffectPara2FromArray(effectId,level-1)/10))*overlay)
    end
    length = CS.JumpCSV.DungeonEffectCsvData.EffectPara3Array(effectId).Length
    if length >= level then
        retStr = string.gsub(retStr,"{4}",math.floor(math.abs(CS.JumpCSV.DungeonEffectCsvData.EffectPara3FromArray(effectId,level-1)/10))*overlay)
    end
    length = CS.JumpCSV.DungeonEffectCsvData.EffectPara4Array(effectId).Length
    if length >= level then
        retStr = string.gsub(retStr,"{5}",math.floor(math.abs(CS.JumpCSV.DungeonEffectCsvData.EffectPara4FromArray(effectId,level-1)/10))*overlay)
    end
    length = CS.JumpCSV.DungeonEffectCsvData.EffectPara5Array(effectId).Length
    if length >= level then
        retStr = string.gsub(retStr,"{6}",math.floor(math.abs(CS.JumpCSV.DungeonEffectCsvData.EffectPara5FromArray(effectId,level-1)/10))*overlay)
    end
    length = CS.JumpCSV.DungeonEffectCsvData.TargetTeamNumArray(effectId).Length
    if length >= level then
        retStr = string.gsub(retStr,"{7}",math.abs(CS.JumpCSV.DungeonEffectCsvData.TargetTeamNumFromArray(effectId,level-1)))
    end
    length = CS.JumpCSV.DungeonEffectCsvData.TargetUnitNumArray(effectId).Length
    if length >= level then
        retStr = string.gsub(retStr,"{8}",math.abs(CS.JumpCSV.DungeonEffectCsvData.TargetUnitNumFromArray(effectId,level-1)))
    end
    return retStr
end

--effect描述
function M.GetEffectDescByIdAndLevel(effectId,level,overlay)
    local retStr = ""
    if ISCLIENT then
        retStr = CS.Loc.Str(CS.JumpCSV.DungeonEffectCsvData.EffectDesLocFromArray(effectId,level-1))
        retStr = GetEffectStr(retStr,effectId,level,overlay)
    end
    return retStr
end

function M.GetEffectDescByEffect(effect)
    return M.GetEffectDescByIdAndLevel(effect.id,effect.level,effect.overlay)
end

function M.GetEffectDescById(effectId)
    return M.GetEffectDescByIdAndLevel(effectId,1,1)
end 

--effect详细描述
function M.GetEffectDetailDescByIdAndLevel(effectId,level,overlay)
    local retStr = ""
    if ISCLIENT then
        retStr = CS.Loc.Str(CS.JumpCSV.DungeonEffectCsvData.EffectDetailDesLocFromArray(effectId,level-1))
        retStr = GetEffectStr(retStr,effectId,level,overlay)
    end
    return retStr
end

function M.GetEffectDetailDescByEffect(effect)
    return M.GetEffectDetailDescByIdAndLevel(effect.id,effect.level,effect.overlay)
end

function M.GetEffectDetailDescById(effectId)
    return M.GetEffectDetailDescByIdAndLevel(effectId,1,1)
end

--权重随机，t={data,weight}
function M.RandomWeight(t)
    local ret
    local total = 0
    for i=1,#t do
        total = total + t[i].weight
    end
    local rNum = math.random(total)
    local index = 0
    for i=1,#t do
        total = total - t[i].weight
        if rNum >= total then
            ret = t[i].data
            index = i
            break
        end
    end
    return ret,index
end

function M.LayerToMapId(dungeonType,layer)
    local mapId = 0
    if layer > 0 then
        mapId = csv.CallCsvData("DungeonThemeCsvData","Map","MapFromArray",dungeonType,layer)
    end
    return mapId
end

function M.LayerToTier(dungeonType,layer)
    local tier = 0
    if layer > 0 then
        local mapId = csv.CallCsvData("DungeonThemeCsvData","Map","MapFromArray",dungeonType,layer)
        tier = math.fmod(mapId , 1000)  
    end
    return tier
end

function M.getlayerOpenOffsetTime(value,layer)
    if ISCLIENT then
        local csvOpenLayers = CS.JumpCSV.DungeonThemeCsvData.OpenLayerArray(value)
        for i=0,csvOpenLayers.Length-1 do
            local csvOpenLayer = CS.JumpCSV.DungeonThemeCsvData.OpenLayerFromArray(value,i)
            if csvOpenLayer>=layer then 
                return  CS.JumpCSV.DungeonThemeCsvData.OpenTimeFromArray(value,i)
            end
        end
        print("check csv  , have layer not find open time layer: "..layer)
    end
    return 0
end

function M.getServerOpenTime(value)
    if ISCLIENT then
        local str = CS.JumpCSV.DungeonThemeCsvData.ConditionParamFromArray(value,0) 
        local hour = CS.JumpCSV.DungeonThemeCsvData.ConditionParamFromArray(value,1)
        local time = str.." "..hour   
        return CS.Joywinds.TimeUtility.ToServerTime(CS.Joywinds.TimeUtility.GetDateTimeByStr(time))
    end
    return 0
end

function M.getTimeStampByLayer(startTime, value, layer)
    if ISCLIENT then
        local offsetTime = M.getlayerOpenOffsetTime(value,layer)
        if offsetTime then 
            -- local serverOpenTime = M.getServerOpenTime(value)
            local serverOpenTime = startTime
            return serverOpenTime+offsetTime
        else
            return 0
        end
    end
    return 0
end

function M.getLayerOpenTime(startTime, value, layer)
    local str = "" 
    if ISCLIENT then
        local ERId = require("ERId")
        -- local time = M.getTimeStampByLayer(startTime, value, layer) - CS.Joywinds.TimeUtility.ToServerTime(CS.TimeClock.LocalNow)
        local time = M.getTimeStampByLayer(startTime, value, layer) - CS.TimeClock.UnixNow
        -- print("-----------", startTime, CS.TimeClock.UnixNow, time, "-----------")
        if time > 0 then 
            local day , _ = math.modf(time/(3600*24))       
            local hour , _ = math.modf((time-day*3600*24)/3600)
            local min , _ = math.modf((time-day*3600*24-hour*3600)/60)
            local second = time-day*3600*24-hour*3600-min*60       
            if day >0 then 
                str = str..CS.Loc.Str(ERId.LOC_RECHARGE_TIME_DAY,day)
            end
            if hour >0 then 
                str = str..CS.Loc.Str(ERId.LOC_RECHARGE_TIME_HOUR,hour)
            end
            if min >0 then 
                str = str..CS.Loc.Str(ERId.LOC_RECHARGE_TIME_MIN,min)
            end
            if second >0 then 
                str = str..CS.Loc.Str(ERId.LOC_RECHARGE_TIME_SEC,second)
            end
            return time,CS.Loc.Str(ERId.LOC_DUNGEON_TREASURE_OPEN_COUNT_DOWN,str)
        end
    end
    return 0,str
end

return M
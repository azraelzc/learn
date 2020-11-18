local M = {}

local function listToTable(data)
    local t = {}
    for i=0,data.Length-1 do
        local d = data[i]
        if type(d) == "userdata" then
            d=listToTable(d)
        end
        table.insert(t,d)
    end
    return t
end

function M.CallCsvData(className,rowName,methodName,id,index)  
    local data
    if ISCLIENT then
        if index == nil then
            data = CS.Joywinds.LuaCallCsvData.GetCsvData(className,methodName,id)
        else
            data = CS.Joywinds.LuaCallCsvData.GetCsvData(className,methodName,id,index-1)
        end
        if type(data) == "userdata" then
            data = listToTable(data)
        end
    else
        local csv = require("datasys.csv")
        if index == nil then
            data = csv.get_dungeon_config_value(className,rowName,id)
        else
            data = csv.get_dungeon_config_value(className,rowName,id, index)
        end
    end
    return data
end

function M.CsvContainsId(className, id)
    local flag = false
    if ISCLIENT then
        local dic = CS.Joywinds.LuaCallCsvData.GetRecordIdValue(className)
        flag = dic:ContainsKey(id)
    else
        local csv = require("datasys.csv")
        return csv.get_dungeon_contains_id(className, id)
    end
    return flag
end

return M  
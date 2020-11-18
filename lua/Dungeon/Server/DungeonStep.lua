local dungeonDefine = require("Dungeon.DungeonDefine")
local dungeonStruct = require("Dungeon.DungeonStruct")
local dungeonUtils = require("Dungeon.DungeonUtils")

--迷宫操作步骤类
local M= {}

local stepList = {}

function M.OnNotifycation(self,notificationType,data)
    local step = dungeonStruct.CreatStep(notificationType)
    step.data = dungeonUtils.copyTable(data)
    table.insert(self.stepList,step)
end

function M.GetStepList(self)
    return self.stepList
end

function M.ClearStepList(self)
    self.stepList = {}
end

function M.Init(self)
    self:ClearStepList()
end

function M.Dispose(self)
    self:ClearStepList()
end

function M.new()
    local t = {
        stepList = {},
    }
    return setmetatable(t, {__index = M})
end


  
return M  
local dungeonServerDataModel = require("Dungeon.Server.DungeonData")
local dungeonDefine = require("Dungeon.DungeonDefine")

local M = {}

function M.ActiveDragonBall(self,eventId,red,yellow,blue)
	local data = {}
	local e,isSuccess,index = self.dungeonServerData.dungeonLogic:ActiveDragonBall(eventId,red,yellow,blue)
	data.paramBool1 = isSuccess
	data.paramInt1 = index
	return e,data
end

function M.UseItem(self,id)
	local e = self.dungeonServerData.dungeonLogic:UseItem(id)
	local data = {item=self.dungeonServerData:GetItem(id)}
	return e,data
end

function M.TestToTier(self,Layer)
	local data = {}
	data.difficultyLevel,data.mazeTier,data.paramBool1 = self.dungeonServerData:TestToTier(Layer)
	return data
end

function M.GoNextTier(self)
	local e = self.dungeonServerData.dungeonLogic:GoNextTier()
	local data = {}
	if e == dungeonDefine.ProtocolErrorType.None then
		data.difficultyLevel,data.mazeTier,data.paramBool1 = self.dungeonServerData:GetNextTier()
	end
	return e,data
end

function M.ChoiceEvent(self,id,index)
	local data = {}
	local e,isSuccess,stuffList = self.dungeonServerData.dungeonLogic:ChoiceEvent(id,index)
	data.paramBool1 = isSuccess
	data.stuffList = stuffList
	return e,data
end

function M.CheckIsItem(self,x,y)
	-- local item = self.dungeonServerData.dungeonLogic:CheckIsItem(x,y)
	-- local data = {item = item}
	-- if item ~= nil then
	-- 		data.maze = self.dungeonServerData:GetMaze()
	-- end
	return self.dungeonServerData.dungeonLogic:CheckIsItem(x,y)
end

function M.OperateGrid(self,x,y,playerX,playerY)
	local data = {}
	data.paramInt1 = self.dungeonServerData.dungeonLogic:OperateGrid(x,y,playerX,playerY)
	return data
end

function M.ClickGrid(self,x,y)
	local data = {path=self.dungeonServerData.dungeonLogic:ClickGrid(x,y)}
	return data
end

function M.GetDungeonLogic(self)
	return self.dungeonServerData.dungeonLogic
end

function M.GetDungeonData(self)
	return self.dungeonServerData
end

function M.CreateMaze(self)
	return self.dungeonServerData:Create()
end

function M.SaveData(self)
	local data = self.dungeonServerData:SaveData()
	--local baseData = self.dungeonServerData:SaveBaseData()
	return data
end

function M.SetData(self,data)
	self.dungeonServerData:SetData(data)
end

function M.CreateData(self,list,dungeonType,difficultyLevel)
	self.dungeonServerData:Dispose()
	self.dungeonServerData:CreateHeroDatas(list)
	self.dungeonServerData:CreateDungeon(dungeonType,difficultyLevel)
	self:CreateMaze()
end

function M.Init(self,openLayer,crossLayer)
	self.dungeonServerData = dungeonServerDataModel.new()
	self.dungeonServerData:Init(openLayer,crossLayer)
end

function M.DisposeData(self)
	self.dungeonServerData:Dispose()
end

function M.new()
    local t = {
    	dungeonServerData = nil,
    }
    return setmetatable(t, {__index = M})
end
  
return M  
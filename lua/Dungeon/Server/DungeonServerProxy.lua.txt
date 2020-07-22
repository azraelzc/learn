local dungeonManagerModel = require("Dungeon.Server.DungeonManager")
local dungeonDefine = require("Dungeon.DungeonDefine")
local dungeonStruct = require("Dungeon.DungeonStruct")
local dungeonUtils = require("Dungeon.DungeonUtils")

local DEBUG = false

local M = {}

function M.GetDifficultyLevel(self)
	return self.dungeonManager:GetDungeonData().difficultyLevel
end

function M.GetCrossMapId(self)
	return self.dungeonManager:GetDungeonData():GetCrossMapId()
end

function M.SetData(self,dataJson)
	self.dungeonManager:SetData(dataJson)
end

function M.Reset(self)
	self.dungeonManager:DisposeData()
end

function M.ReloadMap(self)
	self.dungeonManager:GetDungeonData():ReloadMap()
end

function M.CreateData(self,list,dungeonType,difficultyLevel)
	self.dungeonManager:CreateData(list,dungeonType,difficultyLevel)
end

function M.CheckHeros(self)
	local retIds = {}
	local heroDatas = self.dungeonManager:GetDungeonData().heroDatas
	if heroDatas ~= nil then
		for i=1,#heroDatas do
			table.insert(retIds,heroDatas[i].id)
		end
	end
	return retIds
end

function M.SetLegalHeros(self,list)
	self.dungeonManager:GetDungeonData():SetLegalHeroDatas(list)
end

function M.SaveData(self)
	local data = self.dungeonManager:SaveData()
	if not ISCLIENT then
		local t = data.maze
		data.maze = {}
		for i=1,#t do
			data.maze[i] = {}
			data.maze[i].list = {}
			for j=1,#t[i] do
				data.maze[i].list[j] = t[i][j]
			end
		end
	end
	return data
end

--[[
记录req和resp结构
req{
	protocolType 			int
	id 						int 
	index 					int
	x						int 
	y                       int 
	paramInt1  				int
	paramInt2				int
	paramInt3				int
	effect					Effect
	fightheroDatas
	startData
	randomSeed				long
	hashCode				
}
resp{
	protocolType  			int 	dungeonDefine.ProtocolType
	error  					int 	dungeonDefine.ProtocolErrorType 
	data {
		dungeonType         	int     dungeonDefine.DungeonType
	    difficultyLevel     	int     dungeonDefine.DifficultyLevelType
	    mazeTier            	int     迷宫层数
	    maze                	Grid**  格子Grid的二维数组
	    keyNumber           	int     
	    myKeyNumber         	int  
	    bag                 	Item*   
	    effectList          	Effect*   
	    effectIndex         	int
	    playerPoint         	Point
	    roundNumber         	int
	    battleRoundNumber   	int
		heroDatas				Hero* 	    DungeonStruct的Hero数组 
		paramBool1				bool    	传递可有可无的bool
		paramInt1 				int     	传递可有可无的int或枚举
		item                    Item		DungeonStruct的Item 
		stuff                   Stuff		DungeonStruct的Stuff
		stuffList               Stuff*		DungeonStruct的Stuff
		path 					Point*	
		battleGameData			BattleGameData		
		relic {	
			x					int
			y					int
			ids					int*
		}		
	}
	hashCode
	steps 					Step*	DungeonStruct的Step   	
}
]]

function M.Request(self,req)
	local t = req
	local serverError = nil
	self.dungeonManager:GetDungeonLogic():ClearSteps()
	local resp = {protocolType = t.protocolType,error=dungeonDefine.ProtocolErrorType.None,data={}}
	if t.protocolType == dungeonDefine.ProtocolType.CreateMaze then
		resp.data = self.dungeonManager:CreateMaze()
	elseif t.protocolType == dungeonDefine.ProtocolType.OperateGrid then
		resp.data = self.dungeonManager:OperateGrid(t.x,t.y,t.paramInt1,t.paramInt2)
	elseif t.protocolType == dungeonDefine.ProtocolType.GetItem then
		resp.error = self.dungeonManager:CheckIsItem(t.x,t.y)
	elseif t.protocolType == dungeonDefine.ProtocolType.ChoiceEvent then
		resp.error,resp.data = self.dungeonManager:ChoiceEvent(t.id,t.index)
	elseif t.protocolType == dungeonDefine.ProtocolType.GetRelics then
		resp.error,resp.data.relic = self.dungeonManager:GetDungeonLogic():GetRelics(t.id)
	elseif t.protocolType == dungeonDefine.ProtocolType.ChoiceRelic then
		resp.error = self.dungeonManager:GetDungeonLogic():ChoiceRelic(t.id)
	elseif t.protocolType == dungeonDefine.ProtocolType.GoNextTier then
		resp.error,resp.data = self.dungeonManager:GoNextTier()
	elseif t.protocolType == dungeonDefine.ProtocolType.UseItem then
		resp.error,resp.data = self.dungeonManager:UseItem(t.id)
	elseif t.protocolType == dungeonDefine.ProtocolType.UseDragonBall then
		resp.error,resp.data = self.dungeonManager:ActiveDragonBall(t.id,t.paramInt1,t.paramInt2,t.paramInt3)
	elseif t.protocolType == dungeonDefine.ProtocolType.TargetEffect then
		self.dungeonManager:GetDungeonLogic():TargetEffect(t.effect,t.x,t.y,t.paramInt1==1)
	elseif t.protocolType == dungeonDefine.ProtocolType.StartBattle then
		if S_DungeonLocal then
			local data = self.dungeonManager:GetDungeonLogic():StartBattle(t.x,t.y,t.fightheroDatas)
		else
			if self.battleServer ~= nil then
				local data = self.dungeonManager:GetDungeonLogic():StartBattle(t.x,t.y,t.fightheroDatas)
				resp.data.battleGameData = self.battleServer.startBattle(t.fightheroDatas, data.enemy,data.rules, data.hpLost, t.hashCode)
			else

			end
		end
	elseif t.protocolType == dungeonDefine.ProtocolType.EndBattle then
		if S_DungeonLocal then
			self.dungeonManager:GetDungeonLogic():EndBattle(true,nil,nil)
		else
			if self.battleServer ~= nil then
				local data = self.dungeonManager:GetDungeonLogic():GetBattleData(t.fightheroDatas)
				local battleResult,enemy,hpLost,hashCode,rewards = self.battleServer.endBattle(t.fightheroDatas, data.enemy,data.rules, data.hpLost,t.startData,t.hashCode)
				resp.hashCode = hashCode
				resp.rewards = rewards
				if type(battleResult) == "table" then
					serverError = battleResult
				else
					self.dungeonManager:GetDungeonLogic():EndBattle(battleResult, enemy, hpLost)
				end
			else

			end
		end
	elseif t.protocolType == dungeonDefine.ProtocolType.AdventurerSquadLevelup then
		resp.error = self.dungeonManager:GetDungeonLogic():AdventurerSquadLevelup(t.id,t.index)
	elseif t.protocolType == dungeonDefine.ProtocolType.AdventurerSquadActive then
		resp.error = self.dungeonManager:GetDungeonLogic():AdventurerSquadActive(t.id,t.index)
	elseif t.protocolType == dungeonDefine.ProtocolType.GlacierKingActive then
		resp.error = self.dungeonManager:GetDungeonLogic():GlacierKingActive(t.x,t.y,t.id)
	elseif t.protocolType == dungeonDefine.ProtocolType.DoctorOwlAnswer then
		resp.error = self.dungeonManager:GetDungeonLogic():DoctorOwlAnswer(t.x,t.y,t.index)
	end

	if DEBUG then
		if t.protocolType == dungeonDefine.ProtocolType.testAddStuff then
			self.dungeonManager:GetDungeonLogic():TestAddStuff(t.id)
		elseif t.protocolType == dungeonDefine.ProtocolType.testToTier then
			resp.data = self.dungeonManager:TestToTier(t.index)
		elseif t.protocolType == dungeonDefine.ProtocolType.testRemoveEffect then
			self.dungeonManager:GetDungeonLogic():TestRemoveBuffById(t.id)
		end
	end

	resp.steps = self.dungeonManager:GetDungeonLogic():GetSteps()
	if not ISCLIENT then
		resp = dungeonStruct.TransformResponseToServer(resp)
	end
	--print("===req==",dungeonUtils.PairTabMsg(t))
	--print("===resp==",dungeonUtils.PairTabMsg(resp))
	return serverError,resp
end

function M.Init(self, battleServer ,openLayer, crossLayer ,isDebug)
    self.dungeonManager = dungeonManagerModel.new()
    self.dungeonManager:Init(openLayer,crossLayer)
    self.battleServer = battleServer
    DEBUG = isDebug
end

function M.new()
    local t = {
    	dungeonManager = nil,
    }
    return setmetatable(t, {__index = M})
end
  
return M  
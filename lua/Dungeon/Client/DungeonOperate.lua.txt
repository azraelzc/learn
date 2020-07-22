local dungeonDefine = require("Dungeon.DungeonDefine")
local astar = require("Dungeon.AStar")
local Utils = require("Utils")
local json = require("dkjson")
local ERId = require("ERId")
local dungeonUtils = require("Dungeon.DungeonUtils")

local M = {}

local fightEnemyPos 

--test code start
function M.testAddStuff(libId, cb)
    local req = {}
    req.protocolType = dungeonDefine.ProtocolType.testAddStuff
    req.id = libId
    S_DungeonRequest.Request(req,function(resp)
        if resp.error == dungeonDefine.ProtocolErrorType.None then
            if cb ~= nil then
                cb()
            end
        end
    end)
end

function M.testRemoveEffect(effectId, cb)
    local req = {}
    req.protocolType = dungeonDefine.ProtocolType.testRemoveEffect
    req.id = effectId
    S_DungeonRequest.Request(req,function(resp)
        if resp.error == dungeonDefine.ProtocolErrorType.None then
            if cb ~= nil then
                cb()
            end
        end
    end)
end

function M.testToTier(layer, cb)
    local req = {}
    req.protocolType = dungeonDefine.ProtocolType.testToTier
    req.index = layer
    S_DungeonRequest.Request(req,function(resp)
        if resp.error == dungeonDefine.ProtocolErrorType.None then
            if resp.data.mazeTier > 0 then
                S_DungeonData:SetMaxLayer(resp.data.mazeTier)
                S_DungeonData:SetCrossLayer(resp.data.mazeTier-1)
                M:CreateMaze()
            else
                local view = CS.Joywinds.ViewManager.Instance:CreateLuaView("Dungeon.ViewDungeonOver")
                view:Show()
            end
            if cb ~= nil then
                cb()
            end
        end
    end)
end
--test code end

function M.EmptyRequest(self)
    local req = {}
    req.protocolType = dungeonDefine.ProtocolType.Empty
    S_DungeonRequest.Request(req,function(resp)
        if resp.error == dungeonDefine.ProtocolErrorType.None then
            if cb ~= nil then
                cb()
            end
        end
    end)
end

--处理物品
function M.GetItem(self,x,y)
	local req = {}
    req.protocolType = dungeonDefine.ProtocolType.GetItem
    req.x = x
    req.y = y
	S_DungeonRequest.Request(req,function(resp)
        if resp.error == dungeonDefine.ProtocolErrorType.None then
        	
        end
    end)
end

function M.EnterDoor(self, OKCB,cancelCB)
    local view = CS.Joywinds.ViewManager.Instance:CreateLuaView("Dungeon.ViewDungeonExit")
    view:Show(function()
        local req = {}
        req.protocolType = dungeonDefine.ProtocolType.GoNextTier
        S_DungeonRequest.Request(req,function(resp)
            if resp.error == dungeonDefine.ProtocolErrorType.None then
                if OKCB ~= nil then
                    OKCB(resp)
                end
            end
        end)
    end,
    function()
        if cancelCB ~= nil then
            cancelCB()
        end
    end)
end

function M.IsDoor(self,x,y)
    if S_DungeonData:GetGrid(x,y).gridType == dungeonDefine.MazeGridType.Exit then
        return true
    end
    return false
end

function M.CheckIsItem(self,x,y)
	local c = S_DungeonData:GetGrid(x,y)
	if dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Item,true) then
		return true
	end
	return false
end

local function GetRelics(self,eventId)
	local req = {}
    req.protocolType = dungeonDefine.ProtocolType.GetRelics
    req.id = eventId
	S_DungeonRequest.Request(req,function(resp)
        if resp.error == dungeonDefine.ProtocolErrorType.None then
        	local view = CS.Joywinds.ViewManager.Instance:CreateLuaView("Dungeon.ViewDungeonRelicChoice")
			view:Show(resp.data.relic.ids)
        end
    end)
end

--effect选择目标，effect，特效table，x,y选择的坐标，cancel,是否取消了
function M.ChoiseTarget(self, effect, x, y, cancel, callback)
    S_DungeonData:SetDoStep(true)
    local delay = CS.JumpCSV.DungeonEffectCsvData.DelayFromArray(effect.id,effect.level-1)/1000
    Utils.DelayCall(delay, function()
        S_DungeonData:SetDoStep(false)
        local req = {}
        req.protocolType = dungeonDefine.ProtocolType.TargetEffect
        req.effect = effect
        req.x = x
        req.y = y
        if cancel then
            req.paramInt1 = 1
        else
            req.paramInt1 = 0
        end
        S_DungeonRequest.Request(req,function(resp)
            
        end)
    end)
end 

function M.OperateEvent(self,x,y)
	local c = S_DungeonData:GetGrid(x,y)
	local eventType = CS.JumpCSV.DungeonEventCsvData.EventType(c.stuff.id)
	local t = dungeonDefine.EventType[eventType]
	if t == dungeonDefine.EventType.Common then
		local view = CS.Joywinds.ViewManager.Instance:CreateLuaView("Dungeon.ViewDungeonEventChoice")
		view:Show(c.stuff.id)
	elseif t == dungeonDefine.EventType.Relic then
		GetRelics(self,c.stuff.id)
	elseif t == dungeonDefine.EventType.DragonBall then
		local view = CS.Joywinds.ViewManager.Instance:CreateLuaView("Dungeon.ViewDungeonEventDragonBall")
        view:Show(c.stuff.id)
    elseif t == dungeonDefine.EventType.AdventurerSquad then
        local view = CS.Joywinds.ViewManager.Instance:CreateLuaView("Dungeon.ViewDungeonAdventurerSquad")
        view:Show(c.stuff.id)
    elseif t == dungeonDefine.EventType.GlacierKingSleep then
        local view = CS.Joywinds.ViewManager.Instance:CreateLuaView("Dungeon.ViewDungeonGlacierKing")
        view:Show(x,y,c.stuff.id,false)
    elseif t == dungeonDefine.EventType.GlacierKingAnger then
        local view = CS.Joywinds.ViewManager.Instance:CreateLuaView("Dungeon.ViewDungeonGlacierKing")
        view:Show(x,y,c.stuff.id,true)
    elseif t == dungeonDefine.EventType.DoctorOwl then
        local view = CS.Joywinds.ViewManager.Instance:CreateLuaView("Dungeon.ViewDungeonDoctorOwl")
        view:Show(x,y,c.stuff.id)
	end
end

local function showDungeonUI(self, isShow, afterStartTween, isFromBattle)
    if isShow then
        local v = CS.Joywinds.ViewManager.Instance:CreateLuaView("Dungeon.ViewDungeonHud")
        CS.HomeHUD.Instance:HideOnOpenView(v,true)
        S_UGUIManager:ShowUGUI(true)
        v:afterStartTween("+", function() 
            if afterStartTween then
                afterStartTween() 
            end
            Utils.DelayCall(0.68, function() S_EventManager:Fire("dungeonActive",isShow) end)
        end)
        v:Show(true)
    else
        local v = CS.Joywinds.ViewManager.Instance:GetLuaView("Dungeon.ViewDungeonHud")
        if v ~= nil then
            v:Execution("UnregisterEvents")
        end
        Utils.DelayCall(0.68, function() S_EventManager:Fire("dungeonActive",isShow) end)
    end
end

function M.OnReturnFromBattle(cb, afterStartTween, isFromBattle)
    showDungeonUI(M, true, afterStartTween, isFromBattle)
    if cb ~= nil then
        cb()
    end
end

function M.EndServerBattle(fightheroDatas, startData, hashCode, cb)
    local req = {}
    req.protocolType = dungeonDefine.ProtocolType.EndBattle
    req.fightheroDatas = fightheroDatas
    req.startData = startData
    req.hashCode = hashCode
    S_DungeonRequest.Request(req,function(resp,serverError)
        if resp.error == dungeonDefine.ProtocolErrorType.None then
            if cb ~= nil then
                cb(resp.hashCode, resp.rewards, serverError)
            end
        end
    end)
end

function M.StartServerBattle(x,y,fightheroDatas,hashCode,cb)
    local req = {}
    req.protocolType = dungeonDefine.ProtocolType.StartBattle
    req.fightheroDatas = fightheroDatas
    req.hashCode = hashCode
    req.x = x
    req.y = y
    S_DungeonRequest.Request(req,function(resp,serverError)
        if resp.error == dungeonDefine.ProtocolErrorType.None then
            cb(resp.data.battleGameData, serverError)
        end
    end)
end

local function startClientBattle(self,x,y,monsterData)
    showDungeonUI(self,false)
    local battleData = S_DungeonData:GetBattleData(monsterData)
    battleData.fightEnemyCoord = {}
    battleData.fightEnemyCoord.x = x
    battleData.fightEnemyCoord.y = y
    battleData.dungeonType = S_DungeonData:GetDungeonType()
    local battleDataJson = json.encode(battleData)
    --print("===startClientBattle====",battleDataJson)

    local startBattleData = CS.Joywinds.TinyEmpire.Battle.Core.StartBattleInfo();
    CS.Joywinds.Data.GameData.Instance:UpdateDungeonBattleData(battleDataJson);
    if battleData.dungeonType == dungeonDefine.DungeonType.Seabed then
        startBattleData.LevelId = ERId.LEVEL_DUNGEON_BATTLE_SEABED;        
    elseif battleData.dungeonType == dungeonDefine.DungeonType.Desert then
        startBattleData.LevelId = ERId.LEVEL_DUNGEON_BATTLE_DESERT;            
    elseif battleData.dungeonType == dungeonDefine.DungeonType.Glacier then
        startBattleData.LevelId = ERId.LEVEL_DUNGEON_BATTLE_GLACIER;
    else
        print("=======can not find dungeon type =======")
        startBattleData.LevelId = ERId.None;        
    end
    startBattleData.LevelType = CS.RO.Battle.LevelData.EType.Dungeon;
    CS.Joywinds.TinyEmpire.Battle.Core.BattleManagerNew.StartBattleInfo = startBattleData;
    CS.GameLoadingManager.LoadBattleAtHome(CS.JumpCSV.MapLevelCsvData.BattleScene(startBattleData.LevelId));
end

function M.FightMonster(self,x,y)
    local c = S_DungeonData:GetGrid(x,y)
    if S_DungeonLocal then
        self.StartServerBattle(x,y,nil,nil,function()
            self.EndServerBattle(nil, nil, nil, nil, nil, nil,function()
                self.OnReturnFromBattle()
            end)
        end)
    else
        startClientBattle(self,x,y,c.stuff.monsterData)
    end
end

function M.OperateGrid(self,x,y,playerX,playerY)
	local req = {}
    req.protocolType = dungeonDefine.ProtocolType.OperateGrid
    req.x = x
    req.y = y
    req.paramInt1 = playerX
    req.paramInt2 = playerY
	S_DungeonRequest.Request(req,function(resp)
        if resp.error == dungeonDefine.ProtocolErrorType.None then
        	local operateType = resp.data.paramInt1
        	if operateType == dungeonDefine.OperateGridType.Event then
        		--self:OperateEvent(x,y)
        	elseif operateType == dungeonDefine.OperateGridType.Monster then
                local view = CS.Joywinds.ViewManager.Instance:CreateLuaView("Dungeon.ViewDungeonEnemyInfo")
                view:Show(x,y,true)
        	elseif operateType == dungeonDefine.OperateGridType.Open then

        	end
        end
    end)
end	

function M.StopMove(self,x,y)
    S_DungeonData:SetHeroMazePos(x,y)
end

function M.ClickGrid(self,x,y)
    local path = astar.Seek(S_DungeonData:GetMaze(),S_DungeonData:GetHeroMazePos().x,S_DungeonData:GetHeroMazePos().y,x,y)
    S_EventManager:Fire("dungeonOnMove",{path=path})
end

function M.CreateMaze(self)
    S_UGUIManager.ShowDungeonLoading(function ()
        local req = {}
        req.protocolType = dungeonDefine.ProtocolType.CreateMaze
        S_DungeonRequest.Request(req,function(resp)
            if resp.error == dungeonDefine.ProtocolErrorType.None then
                S_DungeonData:Clear()
                S_DungeonData:Init(resp.data)
                S_EventManager:Fire("dungeonHudRefreshTitle")
                S_EventManager:Fire("dungeonOnCreat")
            end
        end)
    end)
end

function M.DungeonGet(self)
    local req = {}
    req.dungeonType = S_DungeonData:GetDungeonType()
    S_DungeonRequest.RequestDungeonGet(req,function(resp)
        if resp.error == dungeonDefine.ProtocolErrorType.None  then
            S_DungeonData:Clear()
            S_DungeonData:Init(resp.data)
            S_DungeonData:SetloadCount(resp.loadCount)
            S_EventManager:Fire("dungeonHudRefreshTitle")
            S_EventManager:Fire("dungeonOnCreat") 
        end
    end)
end

function M.CloseEntrance(self)
    local v = CS.Joywinds.ViewManager.Instance:GetLuaView("Dungeon.ViewDungeonEntrance")
    if v ~= nil then
        v.LuaObject.luaView:Close()
    end
end

function M.DungeonCreate(self,difficultyLevel)
    local req = {}
    req.dungeonType = S_DungeonData:GetDungeonType()
    req.difficultyLevel = difficultyLevel
    S_DungeonRequest.RequestDungeonCreate(req,function(resp)
        if resp.error == dungeonDefine.ProtocolErrorType.None  then
            S_DungeonData:Clear()
            if #resp.data.maze > 0 then
                S_EventManager:Fire("dungeonEntranceShowOut",{cb=function()
                    S_UGUIManager.ShowDungeonLoading(function ()
                        self:CloseEntrance()
                        local viewDungeonMap = S_UGUIManager:Create(S_UGUIDefine.UI.DungeonMap)
                        viewDungeonMap:Create()
                        S_DungeonData:Init(resp.data)
                        S_EventManager:Fire("dungeonHudRefreshTitle")
                        S_EventManager:Fire("dungeonOnCreat")    
                    end)     
                end})
            else
                local level = 0
                if difficultyLevel == dungeonDefine.DifficultyLevelType.Normal then
                    level = CS.JumpCSV.DungeonParamCsvData.ConditionParam1FromArray(ERId.DUNGEON_PARAM_NORMALENTER,0)
                else
                    level = CS.JumpCSV.DungeonParamCsvData.ConditionParam1FromArray(ERId.DUNGEON_PARAM_HARDENTER,0)
                end
                local str = string.gsub(CS.Loc.Str(ERId.LOC_DUNGEON_DUNGEONEFFECT_LIMIT),"{0}",level) 
                CS.Joywinds.ViewManager.Instance:RedMessage(str)
                self:DungeonReset(true)
            end 
        end
    end)
end

function M.DungeonReset(self,notBackStart)
    local req = {}
    req.dungeonType = S_DungeonData:GetDungeonType()
    if notBackStart then
        S_DungeonRequest.RequestDungeonReset(req,function(resp)
            if resp.error == dungeonDefine.ProtocolErrorType.None  then
                S_DungeonData:Clear()
            end
        end)
    else
        
        S_DungeonRequest.RequestDungeonReset(req,function(resp)
            if resp.error == dungeonDefine.ProtocolErrorType.None  then
                S_DungeonData:Dispose()
                local v = CS.Joywinds.ViewManager.Instance:GetLuaView("Dungeon.ViewDungeonHud")
                if v ~= nil then
                    v:Execution("CloseHud")
                end
                -- local start = CS.Joywinds.ViewManager.Instance:CreateLuaView("Dungeon.ViewDungeonStart")
                -- CS.HomeHUD.Instance:HideOnOpenView(start, true)
                -- start:Show()
            end
        end)
    end
end

function M.DungeonLoad(self)
    if S_DungeonData:GetReloadCount() > 0 then
        if S_DungeonDataManager:ReloadToTier() > 0 then
            S_UGUIManager.ShowDungeonLoading(function()
                local req = {}
                req.dungeonType = S_DungeonData:GetDungeonType()
                S_DungeonRequest.RequestDungeonLoad(req,function(resp)
                    if resp.error == dungeonDefine.ProtocolErrorType.None then
                        S_DungeonData:Clear()
                        S_DungeonData:Init(resp.data)
                        S_DungeonData:SetloadCount(resp.loadCount)
                        S_EventManager:Fire("dungeonHudRefreshTitle")
                        S_EventManager:Fire("dungeonOnCreat") 
                    end
                end)
            end)
        else
            self:DungeonReset()
        end
    else
        CS.Joywinds.ViewManager.Instance:RedMessage(CS.Loc.Str(ERId.LOC_DUNGEON_RESET_TIPS_2))
    end
end

function M.Dispose(self)
	S_DungeonData:Dispose()
end

return M
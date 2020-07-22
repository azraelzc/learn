local csv = require("Dungeon.LuaCallCsvData")
local dungeonDefine = require("Dungeon.DungeonDefine")
local dungeonUtils = require("Dungeon.DungeonUtils")
local dungeonGenerate = require("Dungeon.Server.DungeonGenerate")
local dungeonLogicModel = require("Dungeon.Server.DungeonLogic")
local dungeonEffectManagerModel = require("Dungeon.Server.DungeonEffectManager")
local dungeonStruct = require("Dungeon.DungeonStruct")

--迷宫数据类
local M = {}

function M.AddUnitHP(self,x,y,unitData,heroHp,petHp)
    --print("=====AddUnitHP====",x,y,heroHp,dungeonUtils.PairTabMsg(unitData))
    unitData.HeroHp = unitData.HeroHp + heroHp
    if unitData.HeroHp < 0 then
        unitData.HeroHp = 0
    elseif unitData.HeroHp > 10000 then
        unitData.HeroHp = 10000
    end
    unitData.totalHp = unitData.HeroHp
    if unitData.eliteId == nil or unitData.eliteId == 0 then
        for i=1,#unitData.PetHp do
            if petHp ~= nil then
                unitData.PetHp[i] = unitData.PetHp[i] + petHp[i]
                if unitData.PetHp[i] < 0 then
                    unitData.PetHp[i] = 0
                elseif unitData.PetHp[i] > 10000 then
                    unitData.PetHp[i] = 10000
                end
            end
            unitData.totalHp = unitData.totalHp + unitData.PetHp[i]
        end
    end
    --判定下单位team是否死亡，迷宫单位死了要删掉
    if unitData.totalHp == 0 and unitData.generateId ~= nil then
        local c = self.maze[x][y]
        local monsters = c.stuff.monsterData.monsters
        local teamHP = 0
        for i=1,#monsters do
            local d = monsters[i]
            teamHP = teamHP + d.HeroHp
            for j=1,#d.PetHp do
                teamHP = teamHP + d.PetHp[j]
            end
            if teamHP > 0 then
                break
            end
        end
        if teamHP == 0 then
            self.dungeonLogic:OnMazeUnitDead(x,y)
        end
    end
    --print("=====AddUnitHP end====",dungeonUtils.PairTabMsg(unitData))
end

function M.GetHeroDatas(self)
    return self.heroDatas
end

function M.GetItems(self)
    return self.bag
end

function M.RemoveItem(self,id)
    for i=1,#self.bag do
        local b = self.bag[i]
        if b.id == id then
            table.remove(self.bag,i)
            break
        end
    end
end

function M.UseItem(self,id,useNum)
    useNum = useNum or 1
    local item = self:GetItem(id)
    if item ~= nil then
        item.count = item.count - useNum
        if item.count == 0 then
            self:RemoveItem(id)
        end
    end
    return item
end

function M.GetItem(self,id)
    local item = nil
    for i=1,#self.bag do
        local b = self.bag[i]
        if b.id == id then
            item = b
            break
        end
    end
    return item
end

function M.AddItem(self,id,number,followId,index)
    local item = self:GetItem(id)
    if item == nil then
        item = dungeonStruct.CreatItem(id,number,followId,index)
        table.insert(self.bag,item)
    else
        item.count = item.count + number
    end
    return item
end

function M.AddCacheEffect(self,id,level)
    level = level or 1
    local effect
    for i=1,#self.cacheEffectList do
        local e = self.cacheEffectList[i]
        if e.id == id and e.level == level then
            effect = e
            break
        end
    end
    if effect == nil  then
        effect = dungeonStruct.CreatEffect(id,0,level)
        table.insert(self.cacheEffectList,effect)
    else
        effect.overlay = effect.overlay + 1
    end
    return effect
end

function M.RemoveEffect(self,index)
    for i=1,#self.effectList do
        if self.effectList[i].index == index then
            table.remove(self.effectList,i)
            break
        end
    end
end

function M.GetEffects(self)
    return self.effectList
end

function M.LevelupEffect(self,effect)
    local level = effect.level + 1
    local effectRoundTypeArray = csv.CallCsvData("DungeonEffectCsvData","EffectRoundType","EffectRoundTypeArray",effect.id)
    if #effectRoundTypeArray >= level then
        effect.roundType = dungeonDefine.EffectRoundType[effectRoundTypeArray[level]]
        effect.triggerRound = csv.CallCsvData("DungeonEffectCsvData","TriggerRound","TriggerRoundFromArray",effect.id,level)
        if effect.triggerRound < effect.triggerCount then
            effect.triggerCount = effect.triggerRound
        end
        effect.level = level
    end 
end

function M.AddEffect(self,id,level)
    level = level or 1
    self.effectIndex = self.effectIndex + 1
    local e = dungeonStruct.CreatEffect(id,self.effectIndex,level)
    table.insert(self.effectList,e)
    return e
end

function M.AddBattleRoundNumber(self)
    self.battleRoundNumber = self.battleRoundNumber + 1
end

function M.AddRoundNumber(self)
    self.roundNumber = self.roundNumber + 1
end

function M.CanOpenDoor(self)
    return self.keyNumber <= self.myKeyNumber
end

function M.GetKey(self)
    self.myKeyNumber = self.myKeyNumber + 1
end

function M.GetMyKeyNumber(self)
    return self.myKeyNumber
end

function M.GetTotalKeyNumber(self)
    return self.keyNumber
end

function M.IsHeroPos(self,x,y)
    if self.playerPoint ~= nil and self.playerPoint.x == x and self.playerPoint.y==y then
        return true
    end
    return false
end

function M.SetHeroMazePos(self,x,y)
    self.playerPoint = {x=x,y=y}
end

local function getInitPlayerPosition(self)
    local pos
    for i=1,#self.maze do
        for j=1,#self.maze[i] do
            if self.maze[i][j].gridType == dungeonDefine.MazeGridType.Entrance then
                pos = {x=i,y=j}
                break
            end
        end
    end
    return pos
end

function M.GetGrid(self,x,y)
    local grid = nil
    if self.maze[x] ~= nil and self.maze[x][y] ~= nil then
        grid = self.maze[x][y]
    end
    return grid
end

function M.GetMaze(self)
    return self.maze
end


function M.GetMazeLength(self)
    return #self.maze
end

function M.CreateHeroDatas(self,list)
    self.heroDatas = {}
    for i=1,#list do
        table.insert(self.heroDatas,dungeonStruct.CreatHero(list[i]))
    end
end

function M.SetLegalHeroDatas(self,list)
    if self.heroDatas == nil then
        self:CreateHeroDatas(list)
    else
        local removeIds = {}
        for i=1,#self.heroDatas do
            local has = false
            for j=1,#list do
                if self.heroDatas[i].id == list[j] then
                    has = true
                    table.remove(list,j)
                    break
                end
            end
            if not has then
                table.insert(removeIds,self.heroDatas[i].id)
            end
        end  
        for i=1,#removeIds do
            for j=1,#self.heroDatas do
                if self.heroDatas[j].id == removeIds[i] then
                    table.remove(self.heroDatas,j)
                    break
                end
            end
        end  
    end
end

function M.SetData(self,data)
    self:Clear(self)
    self.heroDatas = data.heroDatas
    self.dungeonType = data.dungeonType
    self.difficultyLevel = data.difficultyLevel
    self.mazeTier = data.mazeTier
    local mapId = 0
    if self.mazeTier ~= nil and self.mazeTier ~= 0 then
        mapId = dungeonUtils.LayerToMapId(self.dungeonType,self.mazeTier)
        self.maze = {}
        for i=1,#data.maze do
            self.maze[i] = {}
            for j=1,#data.maze[i].list do
                self.maze[i][j] = data.maze[i].list[j]
            end
        end
        self.keyNumber = data.keyNumber
        self.myKeyNumber = data.myKeyNumber
        self.bag = data.bag
        self.effectList = data.effectList
        self.effectIndex = data.effectIndex
        self.cacheEffectList = data.cacheEffectList
        self.playerPoint = data.playerPoint
        self.roundNumber = data.roundNumber
        self.battleRoundNumber = data.battleRoundNumber
        self.curentRelics = data.curentRelics
        self.adventurerSquads = data.adventurerSquads
    end
    self.dungeon:CreateWorld(mapId)
end

function M.SaveData(self)
    local data = {}
    data.dungeonType = self.dungeonType
    data.difficultyLevel = self.difficultyLevel
    data.mazeTier = self.mazeTier
    data.maze = self.maze
    data.keyNumber = self.keyNumber
    data.myKeyNumber = self.myKeyNumber
    data.bag = self.bag
    data.effectList = self.effectList
    data.effectIndex = self.effectIndex
    data.cacheEffectList = self.cacheEffectList
    data.playerPoint = self.playerPoint
    data.heroDatas = self.heroDatas
    data.roundNumber = self.roundNumber
    data.battleRoundNumber = self.battleRoundNumber
    data.curentRelics = self.curentRelics
    data.adventurerSquads = self.adventurerSquads
    return data
end

local function createMaze(self)
    if #self.heroDatas > 0 then
        local mapId = dungeonUtils.LayerToMapId(self.dungeonType,self.mazeTier)
        self.maze,self.keyNumber = self.dungeon:Create(mapId)
        local pos = getInitPlayerPosition(self)
        self:SetHeroMazePos(pos.x,pos.y)
        self.dungeonLogic:OperateGrid(pos.x,pos.y,nil,nil,true)
        --冒险者小队如果激活要把effect状态都加上
        local squadData
        for i=1,#self.adventurerSquads do
            local as = self.adventurerSquads[i] 
            if as.isActive then
                squadData = as
                break
            end
        end
        if squadData ~= nil then
            for i=1,#self.maze do
                for j=1,#self.maze do
                    local c = self.maze[i][j]
                    if dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Event,true) then
                        local t = dungeonDefine.EventType[csv.CallCsvData("DungeonEventCsvData","EventType","EventType",c.stuff.id)]
                        if t == dungeonDefine.EventType.AdventurerSquad then
                            self.dungeonLogic:AdventurerSquadActiveEffects(i,j,c,nil,squadData,c.stuff.id)
                        end
                    end
                end
            end
        end
        self.dungeonLogic:Create(mapId)
    end
end

function M.Create(self)
    if self.mazeTier == 0 or self:CanOpenDoor() then
        self:Clear(self)
        --因为服务器要保存当前层数据，所以层数数据要再创建时候修改
        self.mazeTier = self.mazeTier + 1
        createMaze(self)
    end
    return self:SaveData()
end

function M.ReloadMap(self)
    self.myKeyNumber = 999
    self.mazeTier = self.mazeTier - 1
    self:Create()
end

function M.GetMazeData(self)
    return self.mazeTier,self.maze,self.keyNumber,self.playerPoint,self.heroDatas
end

function M.CreateDungeon(self,dungeonType,difficultyLevel)
    self.dungeonType = dungeonType
    self.difficultyLevel = difficultyLevel
    local layers = csv.CallCsvData("DungeonThemeCsvData","Layer","LayerArray",self.dungeonType)
    for i=1,#layers do
        if csv.CallCsvData("DungeonThemeCsvData","DifficultyChart","DifficultyChartFromArray",self.dungeonType,i) == self.difficultyLevel then
            self.mazeTier = i-1
            break
        end
    end
    self.adventurerSquads = dungeonStruct.CreatAdventurerSquads()
end

function M.HasNextLayer(self,layer)
    local layers = csv.CallCsvData("DungeonThemeCsvData","Layer","LayerArray",self.dungeonType)
    local has = #layers >= layer
    if has then
        local diff = csv.CallCsvData("DungeonThemeCsvData","DifficultyChart","DifficultyChartFromArray",self.dungeonType,layer)
        has = self.difficultyLevel == diff
    end
    return has
end

function M.IsOpenTier(self,layer)
    local isOpen = true
    if csv.CallCsvData("DungeonThemeCsvData","Main","Main",self.dungeonType) == 1 then
        local layers = csv.CallCsvData("DungeonThemeCsvData","Layer","LayerArray",self.dungeonType)
        if layer <= #layers then
            isOpen = layer <= self.openLayer
        end
    end
    return isOpen
end

function M.GetNextTier(self)
    if self.crossTier < self.mazeTier then
        self.crossTier = self.mazeTier
    end
    local layer = self.mazeTier + 1
    local isOpen = self:IsOpenTier(layer)
    if isOpen then
        if not self:HasNextLayer(layer) then
            layer = 0
        end
    else
        layer = self.mazeTier
    end
    return self.difficultyLevel,layer,isOpen
end

function M.TestToTier(self,layer)
    if self.dungeonType ~= dungeonDefine.DungeonType.None then
        self.myKeyNumber = 999
        local layers = csv.CallCsvData("DungeonThemeCsvData","Layer","LayerArray",self.dungeonType)
        if #layers >= layer then
            self.mazeTier = layers[layer]-1
            if self.crossTier < self.mazeTier then
                self.crossTier = self.mazeTier 
            end
            self.difficultyLevel = csv.CallCsvData("DungeonThemeCsvData","DifficultyChart","DifficultyChartFromArray",self.dungeonType,layer)
        else
            self.mazeTier = 0
        end
    end
    return self.difficultyLevel,self.mazeTier,true
end

function M.GetCrossMapId(self)
    return self.mazeTier,self.crossTier
end

function M.SetServerMapData(self,difficultyLevel,mazeTier,maze,keyNumber,playerPoint)
    self.difficultyLevel = difficultyLevel
    self.mazeTier = mazeTier
    self.maze = maze
    self.keyNumber = keyNumber
    self.playerPoint = playerPoint
end

function M.Init(self,openLayer,crossLayer)
    self.dungeon = dungeonGenerate.new()
    self.dungeonLogic = dungeonLogicModel.new()
    self.dungeonLogic:Init(self)
    self.dungeonEffectManager = dungeonEffectManagerModel.new()
    self.dungeonEffectManager:Init(self)
    self.openLayer = openLayer
    self.crossTier = crossLayer
end

function M.Clear(self)
    self.maze = {}
    self.myKeyNumber = 0
    self.keyNumber = 0
    self.playerPoint = nil
    self.roundNumber = 0        
    self.battleRoundNumber = 0  
    self.dungeonLogic:Clear()
end

function M.Dispose(self)
    self.dungeonType = dungeonDefine.DungeonType.None
    self.difficultyLevel = dungeonDefine.DifficultyLevelType.None
    self.mazeTier = 0
    self.crossTier = 0
    self.heroDatas = nil
    self.bag = {}
    self.effectList = {}
    self.effectIndex = 0
    self.adventurerSquads = nil
    self.cacheEffectList = {}
    self:Clear()
end

function M.new()
    local t = {

    }
    
    return setmetatable(t, {__index = M})
end
  
return M  
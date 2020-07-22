local dungeonDefine = require("Dungeon.DungeonDefine")
local dungeonUtils = require("Dungeon.DungeonUtils")
local ERId = require("ERId")

--迷宫数据类
local M= {}

function M.GetAdventurerSquads(self)
    return self.adventurerSquads
end

function M.SetAdventurerSquads(self,squads)
    self.adventurerSquads = squads
end

--获取剩余load次数
function M.GetReloadCount(self)
    local totolLoadCount = self:GetTotalLoadCount()
    return totolLoadCount - self.loadCount
end

function M.GetTotalLoadCount(self)
    local totolLoadCount = 0
    local hasTwoCard = CS.Joywinds.Data.GameData.Instance:HasSuperMonthCard() and CS.Joywinds.Data.GameData.Instance:HasMonthCard()
    if self.difficultyLevel == dungeonDefine.DifficultyLevelType.Normal then
        totolLoadCount = CS.JumpCSV.DungeonParamCsvData.ConditionParam1FromArray(ERId.DUNGEON_PARAM_ELITE_RESET_NORMAL,0)
        if hasTwoCard then
            totolLoadCount = totolLoadCount + CS.JumpCSV.DungeonParamCsvData.ConditionParam1FromArray(ERId.DUNGEON_PARAM_ELITE_RESET_VIP_NORMAL,0)
        end
    else
        totolLoadCount = CS.JumpCSV.DungeonParamCsvData.ConditionParam1FromArray(ERId.DUNGEON_PARAM_ELITE_RESET_NORMAL,0)
        if hasTwoCard then
            totolLoadCount = totolLoadCount + CS.JumpCSV.DungeonParamCsvData.ConditionParam1FromArray(ERId.DUNGEON_PARAM_ELITE_RESET_VIP_NORMAL,0)
        end
    end
    return totolLoadCount
end

function M.GetloadCount(self)
    return self.loadCount
end

function M.SetloadCount(self,count)
    self.loadCount = count
end

function M.SetBattleRoundNumber(self,num)
    self.battleRoundNumber = num
end

function M.GetBattleRoundNumber(self)
    return self.battleRoundNumber
end

function M.SetRoundNumber(self,num)
    self.roundNumber = num
end

function M.GetRoundNumber(self)
    return self.roundNumber
end

function M.SetDungeonType(self,t)
    self.dungeonType = t
end

function M.GetDungeonType(self)
    return self.dungeonType
end

function M.SetDifficultyLevel(self,t)
    self.difficultyLevel = t
end

function M.GetDifficultyLevel(self)
    return self.difficultyLevel
end

function M.GetLastThemeId()
    return CS.Joywinds.Data.GameData.Instance.RecordInfo.dungeonId
end

function M.GetLastThemeIsMain()
    return CS.Joywinds.Data.GameData.Instance.RecordInfo.dungeonIsMain
end

function M.GetBattleData(self,monsterData)
    local ret = {}
    ret.availableHeroes = {}
    ret.heroesLostHpData = {}
    local hasLostHp = false
    ret.fightHeroes = {}
    for i=1,#self.heroDatas do
        local h = self.heroDatas[i]
        table.insert(ret.availableHeroes,h.id)
        local hpLost = {}
        if h.position ~= -1 then
            local fh = {}
            fh.HeroId = h.id
            fh.Pos = h.position
            table.insert(ret.fightHeroes,fh)
        end
        if h.totalHp ~= 50000 then
            hasLostHp = true
            hpLost.HeroHpPercentage = math.floor(h.HeroHp)
            hpLost.PetHpPercentage = {}
            for j=1,#h.PetHp do
                table.insert(hpLost.PetHpPercentage,math.floor(h.PetHp[j]))
            end
            ret.heroesLostHpData[tostring(h.id)] = hpLost
        end
    end

    if not hasLostHp then
        ret.heroesLostHpData = nil
    end

    ret.enemy = {}
    for i=1,#monsterData.monsters do
        local m = monsterData.monsters[i]
        local d = {}
        d.Id = m.generateId
        d.HeroType = m.id
        d.EliteId = m.eliteId
        d.HeroLevel = m.level
        d.HeroStar = m.star
        d.HeroHpFactor = m.hpRate
        d.HeroAttackFactor = m.attackRate
        d.CharacterHpFactor = m.scrollHpRate
        d.CharacterAttackFactor = m.scrollAttackRate
        d.ScrollStar = m.scrollStar
        d.ScrollType = m.scrollId
        d.Position = m.position
        d.lostData = {}
        d.lostData.HeroHpPercentage = m.HeroHp
        d.lostData.PetHpPercentage = {}
        for j=1,#m.PetHp do
            table.insert(d.lostData.PetHpPercentage,m.PetHp[j])
        end
        table.insert(ret.enemy,d)
    end
    return ret
end

function M.SetOneHeroHPData(self,id,unitHPData)
    for i=1,#self.heroDatas do
        if self.heroDatas[i].id == id then
            local heroData = self.heroDatas[i]
            heroData.HeroHp = unitHPData.HeroHp
            heroData.PetHp = unitHPData.PetHp
            heroData.totalHp = heroData.HeroHp
            for i=1,#heroData.PetHp do
               heroData.totalHp = heroData.totalHp + heroData.PetHp[i]
            end
            break
        end
    end
end

function M.SetHeroDatas(self,datas)
    self.heroDatas = datas
end

function M.GetHeroDatas(self)
    return self.heroDatas
end

function M.GetItems(self)
    table.sort(self.bag, function(x, y) return x.id > y.id end)
    return self.bag
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

function M.RemoveItem(self,id)
    for i=1,#self.bag do
        local b = self.bag[i]
        if b.id == id then
            table.remove(self.bag,i)
            break
        end
    end
end

-- 服务端返回数据直接替换客户端当前道具数据，如果数量为零，也不再加入
function M.SetItem(self,newItem)
    local item = self:GetItem(newItem.id)
    local oldItem = item
    if item then
        M.RemoveItem(self, newItem.id)
    end
    item = newItem
    if item.count > 0 then
        table.insert(self.bag,item)
    end
    S_EventManager:Fire("dungeonOnUseItem", {oldData = oldItem, newData = item})
end

function M.UseItem(self,newItem)
    local item = self:GetItem(newItem.id)
    if item ~= nil then
        item.count = item.count - 1
        if item.count == 0 then
            self:RemoveItem(id)
        end
    end
end

function M.GetPlayerMoveState(self)
    if self.isPlayerMoving ~= nil then
        return self.isPlayerMoving
    else
        return false
    end
end

function M.SetPlayerMoveState(self, moving)
    self.isPlayerMoving = moving
end

function M.GetDoStep(self)
    if self.doStep ~= nil then
        return self.doStep
    else
        return false
    end
end

function M.SetDoStep(self,doStep)
    self.doStep = doStep
end

function M.AddCacheEffect(self,effect)
    for i=1,#self.cacheEffectList do
        if self.cacheEffectList[i].id == effect.id then
            self.cacheEffectList[i] = effect
            return
        end
    end
    table.insert(self.cacheEffectList,effect)
end

function M.GetEffects(self)
    return self.effectList
end

function M.RemoveEffect(self,effect)
    for i=1,#self.effectList do
        if self.effectList[i].index == effect.index then
            table.remove(self.effectList,i)
            break
        end
    end
end

function M.SetEffect(self,effect)
    for i=1,#self.effectList do
        if self.effectList[i].index == effect.index then
            self.effectList[i] = effect
            break
        end
    end
end

function M.AddEffect(self,effect)
    table.insert(self.effectList,effect)
    S_EventManager:Fire("dungeonHudAddEffect", {effect = effect})
end

function M.MonsterHasBuffType(self,x,y,buffType)
    local flag = false
    local c = self.maze[x][y]
    if dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Monster,true) then
        local effects = c.stuff.effects
        for i=1,#effects do
            local e = effects[i]
            local curBuffType = dungeonDefine.EffectBuffType[CS.JumpCSV.DungeonEffectCsvData.BuffTypeFromArray(e.id,e.level-1)]
            if curBuffType == buffType then
                flag = true
                break
            end
        end
    end
    return flag
end

function M.AddStuffEffect(self,x,y,effect)
    local c = self.maze[x][y]
    if dungeonDefine:IsStuff(c,true) then
        local effects = c.stuff.effects
        table.insert(effects,effect)
    end
end

function M.RemoveStuffEffect(self,x,y,effect)
    local c = self.maze[x][y]
    if dungeonDefine:IsStuff(c,true) then
        local effects = c.stuff.effects
        for i=1,#effects do
            if effects[i].index == effect.index then
                table.remove(effects,i)
                break
            end 
        end
    end
end

function M.MapLength(self)
    return #self.maze
end

function M.CanOpenDoor(self)
    return self.keyNumber <= self.myKeyNumber
end

function M.GetDoorPos(self)
    local pos = {}
    for i=1,#self.maze do
        for j=1,#self.maze[i] do
            local c = self.maze[i][j]
            if c.gridType == dungeonDefine.MazeGridType.Exit then
                pos.x = i
                pos.y = j
                break
            end
        end
    end
    return pos
end

function M.SetMyKeyNumber(self,num)
    self.myKeyNumber = num
end

function M.IsHeroPos(self,x,y)
    if self.playerPoint ~= nil and self.playerPoint.x == x and self.playerPoint.y==y then
        return true
    end
    return false
end

--获取玩家位置
function M.GetHeroMazePos(self)
    return self.playerPoint
end

function M.SetHeroMazePos(self,x,y)
    self.playerPoint = {x=x,y=y}
end

function M.GetGrid(self,x,y)
    local grid = nil
    if self.maze[x] ~= nil and self.maze[x][y] ~= nil then
        grid = self.maze[x][y]
    end
    return grid
end

function M.SetGridStuffEffect(self,x,y,effect)
    if self.maze[x] ~= nil and self.maze[x][y] ~= nil then
        local c = self.maze[x][y]
        if dungeonDefine:IsStuff(c,true) then
            local effects = c.stuff.effects
            for i=1,#effects do
                if effects[i].index == effect.index then
                    effects[i] = effect
                    break
                end
            end
        end
    end
end

function M.SetGridMonsterDataHPData(self,x,y,generateId,unitHPData)
    if self.maze[x] ~= nil and self.maze[x][y] ~= nil then
        local c = self.maze[x][y]
        if dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Monster,true) then
            local monsters = c.stuff.monsterData.monsters
            for i=1,#monsters do
                if monsters[i].generateId == generateId then
                    local m = monsters[i]
                    m.HeroHp = unitHPData.HeroHp
                    m.PetHp = unitHPData.PetHp
                    m.totalHp = m.HeroHp
                    for i=1,#m.PetHp do
                       m.totalHp = m.totalHp + m.PetHp[i]
                    end
                end
            end
        end
    end
end

function M.SetGrid(self,x,y,gridClass)
    if self.maze[x] ~= nil and self.maze[x][y] ~= nil then
      self.maze[x][y] = gridClass
    end
end

function M.GetMaze(self)
    return self.maze
end

function M.GetMazeTier(self)
    return self.mazeTier
end

function M.GetMapId(self)
    return dungeonUtils.LayerToMapId(self.dungeonType,self.mazeTier)
end

function M.SetBaseData(self,data)
    self.mazeTier = data.mazeTier
    self.difficultyLevel = data.difficultyLevel
    self.dungeonType = data.dungeonType
end


function M.GetMaxData(self)
    local maxDifficultyLevel = dungeonDefine.DifficultyLevelType.Normal
    local layers = CS.JumpCSV.DungeonThemeCsvData.LayerArray(self.dungeonType)
    local maxTier = 0
    if layers.Length < self.maxLayer then
        self.maxLayer = layers[layers.Length-1]
    end
    if self.maxLayer > 0 then
        local maxMapId = CS.JumpCSV.DungeonThemeCsvData.MapFromArray(self.dungeonType,self.maxLayer-1)
        maxTier = math.fmod(maxMapId,self.dungeonType*10000)
        if maxTier > 1000 then
            maxDifficultyLevel = dungeonDefine.DifficultyLevelType.Hell
            maxTier = maxTier - 1000
        end
    end
    return maxDifficultyLevel,maxTier
end

function M.GetOpenData(self)
    local openDifficultyLevel = dungeonDefine.DifficultyLevelType.None
    local crossDifficultyLevel = dungeonDefine.DifficultyLevelType.None
    local difficultyLayer = 0
    local layers = CS.JumpCSV.DungeonThemeCsvData.LayerArray(self.dungeonType)
    for i=0,layers.Length - 1 do
        if CS.JumpCSV.DungeonThemeCsvData.DifficultyChartFromArray(self.dungeonType,i) == dungeonDefine.DifficultyLevelType.Hell then
            difficultyLayer = layers[i]
            break
        end
    end
    if self.openLayer > 0 then
        if layers.Length > self.openLayer then
            openDifficultyLevel = CS.JumpCSV.DungeonThemeCsvData.DifficultyChartFromArray(self.dungeonType,self.openLayer-1)
        else
            openDifficultyLevel = dungeonDefine.DifficultyLevelType.Hell
        end
    end
    if layers.Length > self.crossLayer + 1 then
        crossDifficultyLevel = CS.JumpCSV.DungeonThemeCsvData.DifficultyChartFromArray(self.dungeonType,self.crossLayer)
    else
        crossDifficultyLevel = dungeonDefine.DifficultyLevelType.Hell
    end
    return openDifficultyLevel,crossDifficultyLevel,self.openLayer,self.crossLayer,difficultyLayer
end

function M.GetBoxInfo(self)
    return self.boxInfo
end

function M.SetBoxInfo(self,info)
    self.boxInfo = info
end

function M.GetReceivedTour(self)
    return self.rLayer 
end

function M.SetReceivedTour(self,receivedLayer)
    self.rLayer = receivedLayer
end

function M.GetReceivedTour2(self)
    return self.rLayer2 
end

function M.SetReceivedTour2(self,receivedLayer2)
    self.rLayer2 = receivedLayer2
end

function M.GetMaxLayer(self)
    return self.maxLayer
end

function M.SetMaxLayer(self,layer)
    if self.maxLayer < layer then
        self.maxLayer = layer
    end 
end

function M.SetCrossLayer(self,layer)
    if self.crossLayer < layer then
        self.crossLayer = layer
    end 
end

function M.GetCrossLayer(self)
    return self.crossLayer
end

function M.GetOpenLayer(self)
    return self.openLayer
end

function M.SetOpenLayer(self,layer)
    self.openLayer = layer
end

function M.GetStartTime(self)
    return self.startTime
end

function M.SetStartTime(self,time)
    self.startTime = time
end

function M.Init(self,data)
    self.dungeonType = data.dungeonType
    self.difficultyLevel = data.difficultyLevel
    self.mazeTier = data.mazeTier
    self.maze = data.maze
    self.keyNumber = data.keyNumber
    self.myKeyNumber = data.myKeyNumber
    self.bag = data.bag
    self.effectList = data.effectList
    self.cacheEffectList = data.cacheEffectList
    self.playerPoint = data.playerPoint
    self.heroDatas = data.heroDatas
    self.roundNumber = data.roundNumber
    self.battleRoundNumber = data.battleRoundNumber
    self.adventurerSquads = data.adventurerSquads
end

function M.Clear(self)
    self.mazeTier = 0
    self.myKeyNumber = 0
    self.keyNumber = 0
    self.roundNumber = 0
    self.battleRoundNumber = 0
    self.effectList = {}
    self.bag = {}
    self.maze = {}
    self.playerPoint = nil
end

function M.Dispose(self)
    self.dungeonType = dungeonDefine.DungeonType.None
    self.difficultyLevel= dungeonDefine.DifficultyLevelType.None
    self.maxLayer = 0
    self.crossLayer = 0
    self.loadCount = 0
    self.heroDatas = nil
    self.adventurerSquads = nil
    self:Clear()
end
  
return M  
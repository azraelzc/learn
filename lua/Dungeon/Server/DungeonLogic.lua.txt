local csv = require("Dungeon.LuaCallCsvData")
local astar = require("Dungeon.AStar")
local dungeonDefine = require("Dungeon.DungeonDefine")
local dungeonStepModel = require("Dungeon.Server.DungeonStep")
local dungeonStruct = require("Dungeon.DungeonStruct")
local dungeonUtils = require("Dungeon.DungeonUtils")

local M = {}

local function isNearPlayer(self,x,y)
	local dis = math.abs(self.dungeonServerData.playerPoint.x-x)+math.abs(self.dungeonServerData.playerPoint.y-y)
	return dis==1	
end

--当开出怪物时候要封锁周围8格
local function openMonsterGrid(self,x,y)
	local maze = self.dungeonServerData:GetMaze()
	for i=x-1,x+1 do
		for j=y-1,y+1 do
			if (i~=x or j~=y) and maze[i] ~= nil and maze[i][j] ~= nil then
				local c = maze[i][j]
				if not c.isOpen then
					c.isBan = true
					self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.BanGrid,{x=i,y=j,gridClass=c})
				end
			end
		end
	end
end

--寻路过去看能否到达
local function checkNearPlayer(self,x,y)
	local flag = false
	if  math.abs(self.dungeonServerData.playerPoint.x-x)+math.abs(self.dungeonServerData.playerPoint.y-y) == 1 then
		flag = true
	end
	return flag
end

local function removeStuff(self,x,y)
	local c = self.dungeonServerData:GetGrid(x,y)
	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.RemoveStuff,{x=x,y=y,stuff=c.stuff})
	c.gridType = dungeonDefine.MazeGridType.None
	c.stuff = nil
	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.RefreshGrid,{x=x,y=y,gridClass=c})
end

local function showStuff(self,x,y,stuff)
	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.ShowStuff,{x=x,y=y,stuff=stuff})
	if stuff.stuffType == dungeonDefine.StuffType.Monster then
		openMonsterGrid(self,x,y)
	end
end

function M.AddCacheEffect(self,isPlayer,x,y,id,level)
	level = level or 1
	local e = self.dungeonServerData:AddCacheEffect(id,level)
	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.AddCacheEffect,{x=x,y=y,effect=e,isPlayer=isPlayer})
end

function M.RemoveEffect(self,x,y,effect)
	if effect == nil then
		return
	end
	self.dungeonServerData:RemoveEffect(effect.index)
	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.RemoveEffect,{x=x,y=y,effect=effect,isPlayer=true})
end

function M.AddEffect(self,x,y,id,level,overlay)
	level = level or 1
	overlay = overlay or 1
	local effectType = dungeonDefine.EffectType[csv.CallCsvData("DungeonEffectCsvData","EffectType","EffectTypeFromArray",id,level)] 
	if effectType == dungeonDefine.EffectType.DEBUFF and self.dungeonServerData.dungeonEffectManager:IsImmuneDebuff(true) then
		return
	end
	local e = self.dungeonServerData:AddEffect(id,level,overlay)
	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.AddEffect,{x=x,y=y,effect=e,isPlayer=true})
	--如果是0回合就是获得了马上生效
	if e.roundNumber == 0 then
		e.roundNumber = e.roundNumber + 1
		self:DoEffect(e,true,x,y)
	end
end

function M.AddStuffEffect(self,x,y,id,level,overlay)
	--print("=====AddStuffEffect=====",x,y,id,level,overlay)
	level = level or 1
	overlay = overlay or 1
	local grid = self.dungeonServerData:GetGrid(x,y)
	if dungeonDefine:IsStuff(grid,true) then
		local effectType = dungeonDefine.EffectType[csv.CallCsvData("DungeonEffectCsvData","EffectType","EffectTypeFromArray",id,level)] 
		if effectType == dungeonDefine.EffectType.DEBUFF and self.dungeonServerData.dungeonEffectManager:IsImmuneDebuff(false,x,y) then
			return
		end
		local effects = grid.stuff.effects
		local lastEffect = effects[#effects]
		local index = 1
		if lastEffect ~= nil then
			index = lastEffect.index + 1
		end
		local e = dungeonStruct.CreatEffect(id,index,level,overlay)
		table.insert(effects,e)
		self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.AddEffect,{x=x,y=y,effect=e,isPlayer=false})
		--如果是0回合就是获得了马上生效
		if e.roundNumber == 0 then
			e.roundNumber = e.roundNumber + 1
			self:DoEffect(e,false,x,y)
		end
	end
end

function M.RemoveStuffEffect(self,x,y,effect)
	if effect == nil then
		return
	end
	local grid = self.dungeonServerData:GetGrid(x,y)
	if dungeonDefine:IsStuff(grid,true) then
		local effects = grid.stuff.effects
		for i=1,#effects do
			if effects[i].index == effect.index then
				table.remove(effects,i)
				break
			end
		end
		self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.RemoveEffect,{x=x,y=y,effect=effect,isPlayer=false})
	end
end

local function addItem(self,x,y,id,number,followId,index)
	local item = self.dungeonServerData:AddItem(id,number,followId,index)
	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.GetItem,{x=x,y=y,item=item})
end

function M.TestAddStuff(self,id)
	local stuffs = self.dungeonServerData.dungeon:GetStuffsFromLibId(id,1)
	for j=1,#stuffs do
		local stuff = stuffs[j]
		if stuff.stuffType == dungeonDefine.StuffType.Monster or stuff.stuffType == dungeonDefine.StuffType.Event then
			
		else
			if stuff.stuffType == dungeonDefine.StuffType.Item then
				addItem(self,self.dungeonServerData.playerPoint.x,self.dungeonServerData.playerPoint.y,stuff.id,stuff.number,stuff.followId,stuff.index)
			elseif stuff.stuffType == dungeonDefine.StuffType.Effect then
				self:AddEffect(self.dungeonServerData.playerPoint.x,self.dungeonServerData.playerPoint.y,stuff.id)
			end
		end
	end
end

function M.TestRemoveBuffById(self,id)
	local effects = self.dungeonServerData:GetEffects()
	for i=1,#effects do
        local e = effects[i]
        if e.id == id then
        	if self.removeEffectList == nil then
				self.removeEffectList = {}
			end
			table.insert(self.removeEffectList,{x=self.dungeonServerData.playerPoint.x,y=self.dungeonServerData.playerPoint.y,effect=e})
        end
    end
    if self.removeEffectList ~= nil then
    	for i=1,#self.removeEffectList do
    		local re = self.removeEffectList[i]
    		self:RemoveEffect(re.x,re.y,re.effect)
    	end
    	self.removeEffectList = nil
    end
end

local function doRound(self,roundType)
	self.lockPlayerEffect = true
	--自身buff效果
	local effects = self.dungeonServerData:GetEffects()
	for i=1,#effects do
        local e = effects[i]
        if e.roundType == roundType then
        	self:DoEffect(e,true,self.dungeonServerData.playerPoint.x,self.dungeonServerData.playerPoint.y)
        end
    end
    self.lockPlayerEffect = false

    --玩家effect执行完后再删除需要删除的effect
    if self.removeEffectList ~= nil then
    	for i=1,#self.removeEffectList do
    		local re = self.removeEffectList[i]
    		self:RemoveEffect(re.x,re.y,re.effect)
    	end
    	self.removeEffectList = nil
    end

    --迷宫里东西buff效果
    local maze = self.dungeonServerData:GetMaze()
    for i=1,#maze do
    	for j=1,#maze[i] do
    		local c = maze[i][j]
    		if dungeonDefine:IsStuff(c,true) then
    			local monsterEffects = c.stuff.effects
    			if #monsterEffects > 0 then
    				self.lockStuffEffect = {x=i,y=j}
    				for a=1,#monsterEffects do
	    				local e = monsterEffects[a]
	    				if e.roundType == roundType then
				        	self:DoEffect(e,false,i,j)
				        end
	    			end
	    			self.lockStuffEffect = nil
	    			--effect执行完后再删除需要删除的effect
				    if self.removeEffectList ~= nil then
				    	for b=1,#self.removeEffectList do
				    		local re = self.removeEffectList[b]
				    		self:RemoveStuffEffect(i,j,re.effect)
				    	end
				    	self.removeEffectList = nil
				    end
    			end
    		end
    	end
    end
end

--打开格子一回合
local function onRound(self)
	self.dungeonServerData:AddRoundNumber()
	doRound(self,dungeonDefine.EffectRoundType.Grid)
	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.OnRound,{x=self.dungeonServerData.playerPoint.x,y=self.dungeonServerData.playerPoint.y,paraInt1=self.dungeonServerData.roundNumber})
end

--战斗一回合
local function onBattleRound(self)
	self.dungeonServerData:AddBattleRoundNumber()
	doRound(self,dungeonDefine.EffectRoundType.Battle)
	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.OnBattleRound,{x=self.dungeonServerData.playerPoint.x,y=self.dungeonServerData.playerPoint.y,paraInt1=self.dungeonServerData.battleRoundNumber})
end

--buff生效,isPlayer是否是玩家的effect
function M.DoEffect(self,effect,isPlayer,x,y)
	--print("====DoEffect====",isPlayer,x,y,dungeonUtils.PairTabMsg(effect))
	local buffType = dungeonDefine.EffectBuffType[csv.CallCsvData("DungeonEffectCsvData","BuffType","BuffTypeFromArray",effect.id,effect.level)]
	if (buffType == dungeonDefine.EffectBuffType.SealPassiveness or not self.dungeonServerData.dungeonEffectManager:IsSealPassiveness(isPlayer,x,y)) then
		effect.triggerCount = effect.triggerCount - 1
		if effect.triggerCount <= 0 then
			local effectBattle = csv.CallCsvData("DungeonEffectCsvData","EffectBattle","EffectBattleFromArray",effect.id,effect.level)
			if not effectBattle then
				self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.DoEffect,{x=x,y=y,effect=effect,isPlayer=isPlayer})
			end
			effect.triggerCount = effect.triggerRound
			if not effectBattle then
				self.dungeonServerData.dungeonEffectManager:DoEffect(effect,isPlayer,x,y)
			end
			if not isPlayer then
				self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.StuffAttack,{x=x,y=y,effect=effect})
			end
			effect.roundNumber = effect.roundNumber - 1
			if effect.roundNumber == 0 then
				if isPlayer then
					if self.lockPlayerEffect then
						if self.removeEffectList == nil then
							self.removeEffectList = {}
						end
						table.insert(self.removeEffectList,{x=x,y=y,effect=effect})
					else
						self:RemoveEffect(x,y,effect)
					end
				else
					if self.lockStuffEffect ~= nil and self.lockStuffEffect.x == x and self.lockStuffEffect.y == y then
						if self.removeEffectList == nil then
							self.removeEffectList = {}
						end
						table.insert(self.removeEffectList,{x=x,y=y,effect=effect})
					else
						self:RemoveStuffEffect(x,y,effect)
					end
				end
			end
		end
		self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.RefreshEffect,{x=x,y=y,effect=effect,isPlayer=isPlayer})
	end
end

--当去掉ban格子得时候要判断还有怪物在格子附近没
local function checkSurroundHasMonster(self,x,y)
	local maze = self.dungeonServerData:GetMaze()
	local flag = false
	for i=x-1,x+1 do
		for j=y-1,y+1 do
			if (i~=x or j~=y) and maze[i] ~= nil and maze[i][j] ~= nil then
				local c = maze[i][j]
				if dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Monster,true) then
					flag = true
					break
				end
			end
		end
	end
	return flag
end

--怪物死了解除封锁
local function removeMonsterBan(self,x,y)
	local maze = self.dungeonServerData:GetMaze()
	for i=x-1,x+1 do
		for j=y-1,y+1 do
			if (i~=x or j~=y) and maze[i] ~= nil and maze[i][j] ~= nil then
				local c = maze[i][j]
				if not c.isOpen then
					if not checkSurroundHasMonster(self,i,j) then
						c.isBan = false
						self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.RemoveBanGrid,{x=i,y=j,gridClass=c})
					end
				end
			end
		end
	end
end

local function searchCross(self,x,y)
	if searchMaze[x] ~= nil and searchMaze[x][y] then
		return
	end
	if searchMaze[x] == nil then
		searchMaze[x] = {}
	end
	searchMaze[x][y] = true
    local c = self.dungeonServerData:GetGrid(x,y)
    if not c.isOpen or c.isBan or c.gridType == dungeonDefine.MazeGridType.Block then
        return
    end
    local maze = self.dungeonServerData:GetMaze()
    --up
    if y < #maze then
        local a = y+1
        local c1 = maze[x][a]
        if c1.isMist then
        	c1.isMist = false
        	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.RemoveMistGrid,{x=x,y=a,gridClass=c1})
        end
        if c1.isOpen then
        	searchCross(self,x,a)
        end
    end

    --down
    if y > 1 then
        local a = y-1
        local c1 = maze[x][a]
        if c1.isMist then
        	c1.isMist = false
        	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.RemoveMistGrid,{x=x,y=a,gridClass=c1})
        end
        if c1.isOpen then
        	searchCross(self,x,a)
        end
    end

    --left
    if x > 1 then
        local a = x-1
        local c1 = maze[a][y]
        if c1.isMist then
        	c1.isMist = false
        	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.RemoveMistGrid,{x=a,y=y,gridClass=c1})
        end
        if c1.isOpen then
        	searchCross(self,a,y)
        end
    end

    --right
    if x < #maze then
        local a = x+1
        local c1 = maze[a][y]
        if c1.isMist then
        	c1.isMist = false
        	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.RemoveMistGrid,{x=a,y=y,gridClass=c1})
        end
        if c1.isOpen then
        	searchCross(self,a,y)
        end
    end
end 

--当消灭怪物或触发完事件后把通路的迷雾都去掉
local function OpenAllCrossMist(self)
	searchMaze = {}
    searchCross(self,self.dungeonServerData.playerPoint.x,self.dungeonServerData.playerPoint.y)
end

--使用物品
function M.TargetEffect(self,effect,x,y,cancel)
	if effect == nil then
		return
	end
	if cancel then
		self:RemoveEffect(self.dungeonServerData.playerPoint.x,self.dungeonServerData.playerPoint.y,effect)
	else
		self:RemoveEffect(x,y,effect)
		self.dungeonServerData.dungeonEffectManager:DoTargetEffect(effect,x,y)
	end
end

--使用物品
function M.UseItem(self,id)
	if self.dungeonServerData.dungeonEffectManager:IsSealItem() then
		return dungeonDefine.ProtocolErrorType.UseItemSeal
	end
	local item = self.dungeonServerData:UseItem(id)
	if item ~= nil then
		doRound(self,dungeonDefine.EffectRoundType.Item)
		self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.UseItem,{x=self.dungeonServerData.playerPoint.x,y=self.dungeonServerData.playerPoint.y,item=item})
		if item.followId ~= 0 then
			local stuffs = self.dungeonServerData.dungeon:GetStuffsFromLibId(item.followId,item.index)
			for j=1,#stuffs do
				local stuff = stuffs[j]
				if stuff.stuffType == dungeonDefine.StuffType.Monster or stuff.stuffType == dungeonDefine.StuffType.Event then
					c.gridType = dungeonDefine.MazeGridType.Stuff
					c.stuff = stuff
					table.insert(list,stuff)
					showStuff(self,self.dungeonServerData.playerPoint.x,self.dungeonServerData.playerPoint.y,c.stuff)
				else
					if stuff.stuffType == dungeonDefine.StuffType.Item then
						addItem(self,self.dungeonServerData.playerPoint.x,self.dungeonServerData.playerPoint.y,stuff.id,stuff.number,stuff.followId,stuff.index)
					elseif stuff.stuffType == dungeonDefine.StuffType.Effect then
						self:AddEffect(self.dungeonServerData.playerPoint.x,self.dungeonServerData.playerPoint.y,stuff.id)
					end
				end
			end
		end
		return dungeonDefine.ProtocolErrorType.None
	end
	return dungeonDefine.ProtocolErrorType.UseItemError
end

--当迷宫单位死亡死亡
function M.OnMazeUnitDead(self,x,y)
	local grid = self.dungeonServerData:GetGrid(x,y)
	if not dungeonDefine:IsStuffType(grid,dungeonDefine.StuffType.Monster,true) then
		return
	end
	if grid.stuff.monsterData.isEnemy then
		doRound(self,dungeonDefine.EffectRoundType.EnemyDead)
	else
		doRound(self,dungeonDefine.EffectRoundType.AllyDead)
	end

	--自己死亡的效果
	local monsterEffects = grid.stuff.effects
	for a=1,#monsterEffects do
		local e = monsterEffects[a]
		if e.roundType == dungeonDefine.EffectRoundType.SelfDead then
        	self:DoEffect(e,false,x,y)
        end
	end

    --处理死亡单位
	if grid.stuff.monsterData.isKeyMonster then
		self.dungeonServerData:GetKey()
		self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.GetKey,{x=x,y=y,paraInt1=self.dungeonServerData:GetMyKeyNumber()})
	end
	local followStuffs = self.dungeonServerData.dungeon:GetStuffsFromLibId(grid.stuff.followId,grid.stuff.index)
	removeStuff(self,x,y)
	--处理怪物掉落
	for i=1,#followStuffs do
		local followStuff = followStuffs[i]
		if followStuff.stuffType == dungeonDefine.StuffType.Monster or followStuff.stuffType == dungeonDefine.StuffType.Event then
			grid.gridType = dungeonDefine.MazeGridType.Stuff
			grid.stuff = followStuff
			showStuff(self,x,y,grid.stuff)
		else
			if followStuff.stuffType == dungeonDefine.StuffType.Item then
				addItem(self,x,y,followStuff.id,followStuff.number,followStuff.followId,followStuff.index)
			elseif followStuff.stuffType == dungeonDefine.StuffType.Effect then
				self:AddEffect(x,y,followStuff.id)
			end
		end
	end
	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.RefreshGrid,{x=x,y=y,gridClass=grid})
	removeMonsterBan(self,x,y)
	OpenAllCrossMist(self)
end

local function createRule(self,e,isPlayer,isSelf)
	local rule = {}
	rule.ruleWarpper = csv.CallCsvData("DungeonEffectCsvData","BuffType","BuffTypeFromArray",e.id,e.level)
	local paraIntArray = csv.CallCsvData("DungeonEffectCsvData","EffectPara1","EffectPara1Array",e.id)
	if #paraIntArray >= e.level then
		rule.factor = math.floor(paraIntArray[e.level]/10) * e.overlay
	end
	local paraStrArray = csv.CallCsvData("DungeonEffectCsvData","ParaStr","ParaStrArray",e.id)
	if #paraStrArray >= e.level then
		rule.artifact = paraStrArray[e.level]
	end
	local targetTeam = dungeonDefine.EffectTargetTeamType[csv.CallCsvData("DungeonEffectCsvData","TargetTeam","TargetTeamFromArray",e.id,e.level)]

	if isPlayer then
		if targetTeam == dungeonDefine.EffectTargetTeamType.Self 
		or targetTeam == dungeonDefine.EffectTargetTeamType.Player 
		or targetTeam == dungeonDefine.EffectTargetTeamType.Friendly then
			rule.side = "Player"
		elseif targetTeam == dungeonDefine.EffectTargetTeamType.Enemy 
			or targetTeam == dungeonDefine.EffectTargetTeamType.EnemyAlly then
			rule.side = "Ai"
		end
	elseif isSelf then
		if targetTeam == dungeonDefine.EffectTargetTeamType.Player
		or targetTeam == dungeonDefine.EffectTargetTeamType.Friendly 
		or targetTeam == dungeonDefine.EffectTargetTeamType.Ally  then
			rule.side = "Player"
		elseif targetTeam == dungeonDefine.EffectTargetTeamType.Self 
		or targetTeam == dungeonDefine.EffectTargetTeamType.Enemy then
			rule.side = "Ai"
		end
	else
		if targetTeam == dungeonDefine.EffectTargetTeamType.Ally 
			or targetTeam == dungeonDefine.EffectTargetTeamType.Friendly
			or targetTeam == dungeonDefine.EffectTargetTeamType.Player then
			rule.side = "Player"
		elseif targetTeam == dungeonDefine.EffectTargetTeamType.Enemy 
			or targetTeam == dungeonDefine.EffectTargetTeamType.EnemyAlly then
			rule.side = "Ai"
		end
	end
	rule.camp = csv.CallCsvData("DungeonEffectCsvData","Camp","CampFromArray",e.id,e.level)
	return rule
end

function M.GetJammingRule(self)
	local rules = {}
	local c = self.dungeonServerData:GetGrid(self.fightMonsterPos.x,self.fightMonsterPos.y)
	if dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Monster,true) then
		local effects = self.dungeonServerData:GetEffects()
		for i=1,#effects do
	        local e = effects[i]
	        local effectBattle = csv.CallCsvData("DungeonEffectCsvData","EffectBattle","EffectBattleFromArray",e.id,e.level)
			if effectBattle then
				local rule = createRule(self,e,true,false)
				if rule.side ~= nil then
					table.insert(rules,rule)
				end
			end
	    end
		effects = c.stuff.effects
		for i=1,#effects do
			local e = effects[i]
	        local effectBattle = csv.CallCsvData("DungeonEffectCsvData","EffectBattle","EffectBattleFromArray",e.id,e.level)
			if effectBattle then
				local rule = createRule(self,e,false,true)
				if rule.side ~= nil then
					table.insert(rules,rule)
				end
			end
		end
		--遍历其他怪
		local maze = self.dungeonServerData:GetMaze()
		for i=1,#maze do
			for j=1,#maze[i] do
				if i ~= self.fightMonsterPos.x or j ~= self.fightMonsterPos.y then
					local grid = maze[i][j]
					if dungeonDefine:IsStuffType(grid,dungeonDefine.StuffType.Monster,true) then
						effects = grid.stuff.effects
						for k=1,#effects do
							local e = effects[k]
					        local effectBattle = csv.CallCsvData("DungeonEffectCsvData","EffectBattle","EffectBattleFromArray",e.id,e.level)
							if effectBattle then
								local rule = createRule(self,e,false,false)
								if rule.side ~= nil then
									table.insert(rules,rule)
								end
							end
						end
					end
				end
			end
		end
	end
	return rules
end

function M.GetEnemy(self)
	local enemy = {}
	local c = self.dungeonServerData:GetGrid(self.fightMonsterPos.x,self.fightMonsterPos.y)
	if dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Monster,true) then
		local monsters = c.stuff.monsterData.monsters
		for i=1,#monsters do
			local m = monsters[i]
	        local d = {}
	        d.id = m.generateId
	        d.heroType = m.id
	        d.eliteId = m.eliteId
	        d.heroLevel = m.level
	        d.heroStar = m.star
	        d.heroHpFactor = m.hpRate
	        d.heroAttackFactor = m.attackRate
	        d.characterHpFactor = m.scrollHpRate
	        d.characterAttackFactor = m.scrollAttackRate
	        d.scrollStar = m.scrollStar
	        d.scrollType = m.scrollId
	        d.position = m.position
	        d.heroHpPercentage  = m.HeroHp
	        d.petHpPercentage  = {}
	        for j=1,#m.PetHp do
	            table.insert(d.petHpPercentage,m.PetHp[j])
	        end
	        table.insert(enemy,d)
		end
	end
	return enemy
end

function M.GetBattleData(self,fightheroDatas)
	local data = {}
	data.enemy = self:GetEnemy()
	data.rules = self:GetJammingRule()
	data.hpLost = {}
	if fightheroDatas ~= nil then
		local heroDatas = self.dungeonServerData.heroDatas
		for i=1,#heroDatas do
			local h = heroDatas[i]
			h.position = -1
			if #data.hpLost < #fightheroDatas then
				for j=1,#fightheroDatas do
					local fh = fightheroDatas[j]
					if  fh.id == h.id then
						h.position = fh.pos
						local hp = {}
						hp.id = h.id
						hp.heroHpPercentage = h.HeroHp
						hp.petHpPercentage = {}
						for k=1,#h.PetHp do
				            table.insert(hp.petHpPercentage,h.PetHp[k])
				        end
	    				table.insert(data.hpLost,hp)
	    				break
					end
				end
			end
		end
	end
	return data
end

function M.StartBattle(self,x,y,fightheroDatas)
	local data = {}
	local c = self.dungeonServerData:GetGrid(x,y)
	if dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Monster,true) then
		self.fightMonsterPos = {}
		self.fightMonsterPos.x = x
		self.fightMonsterPos.y = y
		data = self:GetBattleData(fightheroDatas)
	else
		assert(nil, "start battle error grid is not monster:"..x..","..y)
	end
	return data
end

--处理怪物
function M.EndBattle(self,battleResult, enemy, hpLost)
	if self.fightMonsterPos ~= nil then
		local c = self.dungeonServerData:GetGrid(self.fightMonsterPos.x,self.fightMonsterPos.y)
		local ret = dungeonDefine.ProtocolErrorType.FightMonsterError
		if dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Monster,true) then
			ret = dungeonDefine.ProtocolErrorType.None
			if hpLost ~= nil then
				for i=1,#self.dungeonServerData.heroDatas do
					local h = self.dungeonServerData.heroDatas[i]
					for j=1,#hpLost do
						local hp = hpLost[j]
						if hp.id  == h.id then
							h.totalHp = hp.heroHpPercentage
							h.HeroHp = hp.heroHpPercentage 
							for k=1,#h.PetHp do
					            h.PetHp[k] = hp.petHpPercentage[k]
					            h.totalHp = h.totalHp + hp.petHpPercentage[k]
					        end
							break
						end
					end
				end
			end
			if battleResult then
				local monsters = c.stuff.monsterData.monsters
				for i=1,#monsters do
						local m = monsters[i]
						m.totalHp = 0
						m.HeroHp = 0
						for j=0,#m.PetHp do
				            m.PetHp[j] = 0
				        end
					end
				self:OnMazeUnitDead(self.fightMonsterPos.x,self.fightMonsterPos.y)
			else
				if enemy ~= nil then
					local monsters = c.stuff.monsterData.monsters
					for i=1,#monsters do
						local m = monsters[i]
				        for j=1,#enemy do
				        	local e = enemy[j]
				        	if m.generateId == e.id then
				        		m.totalHp = e.heroHpPercentage
				        		m.HeroHp = e.heroHpPercentage
						        for k=1,#m.PetHp do
						            m.PetHp[k] = e.petHpPercentage[k]
						            m.totalHp = m.totalHp + e.petHpPercentage[k]
						        end
				        		break
				        	end
				        end
					end
				end
				self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.RefreshGrid,{x=self.fightMonsterPos.x,y=self.fightMonsterPos.y,gridClass=c})
			end
			self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.HeroDatasChange,{x=self.dungeonServerData.playerPoint.x,y=self.dungeonServerData.playerPoint.y,heroDatas=self.dungeonServerData.heroDatas})
		end
		onBattleRound(self)
	else

	end
	
	return ret
end

local function clearCurrentEvent(self)
	self.isDoEvent = false
    self.eventList = {}
end

local function removeCurrentEvent(self)
	if #self.eventList > 0 then
		table.remove(self.eventList,1)
	end
	self.isDoEvent = false
	self:DoEvent()
end

local function getCurrentEvent(self)
	return self.eventList[1]
end

local function AddEvent(self,x,y)
	--已经在准备执行列表里面了
	for i=1,#self.eventList do
		local event = self.eventList[i]
		if event.x == x and event.y == y then
			return
		end
	end
	local c = self.dungeonServerData:GetGrid(x,y)
	if dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Event,true) then
		local t = dungeonDefine.EventType[csv.CallCsvData("DungeonEventCsvData","EventType","EventType",c.stuff.id)]
		if t == dungeonDefine.EventType.Common
		or t == dungeonDefine.EventType.Relic then
			table.insert(self.eventList,{id=c.stuff.id,x=x,y=y})
			self:DoEvent()
		else
			self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.DoEvent,{x=x,y=y})
		end
	end
end

--猫头鹰博士答题，index，选择答案，如果为0则是点击的下一题
function M.DoctorOwlAnswer(self,x,y,index)
 	local e = dungeonDefine.ProtocolErrorType.GlacierKingActiveActiveError
	local c = self.dungeonServerData:GetGrid(x,y)
	if checkNearPlayer(self,x,y) and dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Event,true) then
		local t = dungeonDefine.EventType[csv.CallCsvData("DungeonEventCsvData","EventType","EventType",c.stuff.id)]
		if t == dungeonDefine.EventType.DoctorOwl and c.stuff.eventData.questionIndex <= #c.stuff.eventData.choiceDatas then
			e = dungeonDefine.ProtocolErrorType.None
			local choiceData = c.stuff.eventData.choiceDatas[c.stuff.eventData.questionIndex]
			if index == 0  and choiceData.selectIndex > 0 then
				c.stuff.eventData.questionIndex = c.stuff.eventData.questionIndex + 1
			elseif index > 0  and choiceData.selectIndex == 0 then
				choiceData.selectIndex = index
				local questionId = choiceData.id
				local addOverlay = csv.CallCsvData("DungeonEventCsvData","EventPara1","EventPara1FromArray",questionId,index)
				local eventEffects = c.stuff.eventData.effects
				local stuffEffects = c.stuff.effects
				for i=1,#eventEffects do
					local eventEffect = eventEffects[i]
					eventEffect.overlay = eventEffect.overlay + addOverlay
					for j=1,#stuffEffects do
						local stuffEffect = stuffEffects[j]
						if eventEffect.id == stuffEffect.id then
							stuffEffect.overlay = eventEffect.overlay
						end
					end
				end
			end
			self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.RefreshGrid,{x=x,y=y,gridClass=c})
		end
	end
	return e
end

function M.GlacierKingActive(self,x,y,eventId)
	local e = dungeonDefine.ProtocolErrorType.GlacierKingActiveActiveError
	local c = self.dungeonServerData:GetGrid(x,y)
	if checkNearPlayer(self,x,y) and dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Event,true) then
		local t = dungeonDefine.EventType[csv.CallCsvData("DungeonEventCsvData","EventType","EventType",c.stuff.id)]
		if t == dungeonDefine.EventType.GlacierKingSleep then
			e = dungeonDefine.ProtocolErrorType.None
			local stuffIndex = c.stuff.index
			removeStuff(self,x,y)
			local libId = csv.CallCsvData("DungeonEventCsvData","EventSuccessLib","EventSuccessLibFromArray",eventId,1)[1]
			local stuff = self.dungeonServerData.dungeon:GetStuffsFromLibId(libId,stuffIndex)[1]
			c.gridType = dungeonDefine.MazeGridType.Stuff
			c.stuff = stuff
			showStuff(self,x,y,stuff)
			self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.RefreshGrid,{x=x,y=y,gridClass=c})
		end
	end
	return e
end

function M.AdventurerSquadActiveEffects(self,x,y,grid,oldData,newData,eventId)
	--移除老effect
	if oldData ~= nil then
		local mainEffectId = csv.CallCsvData("DungeonEventCsvData","EventSuccessLib","EventSuccessLibFromArray",eventId,oldData.id)[1]
		local libId = csv.CallCsvData("DungeonEventCsvData","EventPara2","EventPara2FromArray",eventId,oldData.id)
		local addEffectIds = csv.CallCsvData("DungeonLibCsvData","Reward","RewardArray",libId)
		local activeEffectIds = {}
		local removeEffects = {}
		for i=1,#oldData.comprehands do
			if oldData.comprehands[i] ~= 0 then
				table.insert(activeEffectIds,addEffectIds[i])
			end
		end
		for i=1,#grid.stuff.effects do
			local e = grid.stuff.effects[i]
			if e.id == mainEffectId then
				table.insert(removeEffects,e)
			else
				for j=1,#addEffectIds do
					local id = addEffectIds[j]
					if id == e.id then
						table.insert(removeEffects,e)
						break
					end
				end
			end
		end
		for i=1,#removeEffects do
			self:RemoveStuffEffect(x,y,removeEffects[i])
		end
	end
	--增加新effect
	if newData ~= nil then
		local mainEffectId = csv.CallCsvData("DungeonEventCsvData","EventSuccessLib","EventSuccessLibFromArray",eventId,newData.id)[1]
		self:AddStuffEffect(x,y,mainEffectId,newData.level)
		local libId = csv.CallCsvData("DungeonEventCsvData","EventPara2","EventPara2FromArray",eventId,newData.id)
		local addEffectIds = csv.CallCsvData("DungeonLibCsvData","Reward","RewardArray",libId)
		local activeEffectIds = {}
		for i=1,#newData.comprehands do
			if newData.comprehands[i] ~= 0 then
				self:AddStuffEffect(x,y,addEffectIds[i])
			end
		end
	end
end

local function doAdventurerSquadActive(self,eventId,squadId)
	local adventurerSquads = self.dungeonServerData.adventurerSquads
	local data = adventurerSquads[squadId]
	local stopData
	for i=1,#adventurerSquads do
		if adventurerSquads[i].isActive then
			stopData = adventurerSquads[i]
			stopData.isActive = false
			break
		end
	end
	data.isActive = true
	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.AdventurerSquadActive,{adventurerSquads=self.dungeonServerData.adventurerSquads})
	local maze = self.dungeonServerData:GetMaze()
    for i=1,#maze do
    	for j=1,#maze[i] do
    		local c = maze[i][j]
    		if dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Event,true) then
    			local t = dungeonDefine.EventType[csv.CallCsvData("DungeonEventCsvData","EventType","EventType",c.stuff.id)]
	    		if t == dungeonDefine.EventType.AdventurerSquad then
	    			self:AdventurerSquadActiveEffects(i,j,c,stopData,data,eventId)
	    			self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.RefreshGrid,{x=i,y=j,gridClass=c})
	    		end
    		end
    	end
    end
end

--冒险小队出战
function M.AdventurerSquadActive(self,eventId,squadId)
	local e = dungeonDefine.ProtocolErrorType.AdventurerSquadActiveError
	local data = self.dungeonServerData.adventurerSquads[squadId]
	local canActive = not data.isActive
	if not data.isActive then
		--先判断资源到位没
		local needActiveItemNum = csv.CallCsvData("DungeonParamCsvData","ConditionParam1","ConditionParam1FromArray",14,1)	
		local items = self.dungeonServerData:GetItems()
		for i=1,#items do
	        local item = items[i]
	        local itemType = dungeonDefine.ItemType[csv.CallCsvData("DungeonItemCsvData","ItemType","ItemType",item.id)] 
	        if itemType == dungeonDefine.ItemType.AttackToken and item.count >= needActiveItemNum then
	        	e = dungeonDefine.ProtocolErrorType.None
	        	doAdventurerSquadActive(self,eventId,squadId)
	        	self.dungeonServerData:UseItem(item.id,levelUpCostItemNum)
	        	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.SetItem,{x=self.dungeonServerData.playerPoint.x,y=self.dungeonServerData.playerPoint.y,item=item})
	        	break
	        end 
	    end
	end
	return e
end

local function doAdventurerSquadLevelup(self,data,eventId)
	data.level = data.level + 1
	--如果出击替换主技能
	if data.isActive then
		local mainEffectId = csv.CallCsvData("DungeonEventCsvData","EventSuccessLib","EventSuccessLibFromArray",eventId,data.id)[1]
		local maze = self.dungeonServerData:GetMaze()
	    for i=1,#maze do
	    	for j=1,#maze[i] do
	    		local c = maze[i][j]
	    		if dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Event,true) then
	    			local t = dungeonDefine.EventType[csv.CallCsvData("DungeonEventCsvData","EventType","EventType",c.stuff.id)]
					if t == dungeonDefine.EventType.AdventurerSquad then
		    			for a=1,#c.stuff.effects do
							local e = c.stuff.effects[a]
							if e.id == mainEffectId then
								self.dungeonServerData:LevelupEffect(e)
								self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.RefreshEffect,{x=i,y=j,effect=e,isPlayer=false})
								self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.RefreshGrid,{x=i,y=j,gridClass=c})
							end
						end
		    		end
	    		end
	    	end
	    end
	end
	--领悟技能
	local comprehands = {}
	for i=1,#data.comprehands do
		if data.comprehands[i] == 0 then
			table.insert(comprehands,i)
		end
	end
	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.AdventurerSquadLevelup,{adventurerSquads=self.dungeonServerData.adventurerSquads})
	if #comprehands > 0 then
		local probability = csv.CallCsvData("DungeonEventCsvData","EventPara1","EventPara1FromArray",eventId,data.id)
		local succ = math.random(1000)
		if true then
		--if succ <= probability then
			local libId = csv.CallCsvData("DungeonEventCsvData","EventPara2","EventPara2FromArray",eventId,data.id)
			local weights = {}
			for i=1,#comprehands do
				local w = csv.CallCsvData("DungeonLibCsvData","Weight","WeightFromArray",libId,comprehands[i])
				table.insert(weights,w)
			end
			local index = dungeonUtils.commonRandom(comprehands,weights)
			data.comprehands[index] = 1
			self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.AdventurerSquadLevelup,{adventurerSquads=self.dungeonServerData.adventurerSquads})
			if data.isActive then
				local maze = self.dungeonServerData:GetMaze()
			    for i=1,#maze do
			    	for j=1,#maze[i] do
			    		local c = maze[i][j]
			    		if dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Event,true) then
			    			local t = dungeonDefine.EventType[csv.CallCsvData("DungeonEventCsvData","EventType","EventType",c.stuff.id)]
	    					if t == dungeonDefine.EventType.AdventurerSquad then
				    			local libId = csv.CallCsvData("DungeonEventCsvData","EventPara2","EventPara2FromArray",eventId,data.id)
				    			local addEffectId = csv.CallCsvData("DungeonLibCsvData","Reward","RewardFromArray",libId,index)
				    			self:AddStuffEffect(i,j,addEffectId)
				    			self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.RefreshGrid,{x=i,y=j,gridClass=c})
				    		end
			    		end
			    	end
			    end
			end
		end
	end
end

--冒险小队升级
function M.AdventurerSquadLevelup(self,eventId,squadId)
	local e = dungeonDefine.ProtocolErrorType.AdventurerSquadLevelupError
	local data = self.dungeonServerData.adventurerSquads[squadId]
	local effectId = csv.CallCsvData("DungeonEventCsvData","EventSuccessLib","EventSuccessLibFromArray",eventId,squadId)[1]
	local levelUpCostItemIds = csv.CallCsvData("DungeonEffectCsvData","UPItem","UPItemArray",effectId)
	if #levelUpCostItemIds > data.level then
		local levelUpCostItemId = levelUpCostItemIds[data.level]
        local levelUpCostItemNum = csv.CallCsvData("DungeonEffectCsvData","UPItemNumber","UPItemNumberFromArray",effectId,data.level)
		local levelUpItemType = dungeonDefine.ItemType[csv.CallCsvData("DungeonItemCsvData","ItemType","ItemType",levelUpCostItemId)]
		local items = self.dungeonServerData:GetItems()
		for i=1,#items do
	        local item = items[i]
	        local itemType = dungeonDefine.ItemType[csv.CallCsvData("DungeonItemCsvData","ItemType","ItemType",item.id)] 
	        if itemType == levelUpItemType and item.count >= levelUpCostItemNum then
	        	e = dungeonDefine.ProtocolErrorType.None
	        	doAdventurerSquadLevelup(self,data,eventId)
	        	self.dungeonServerData:UseItem(item.id,levelUpCostItemNum)
	        	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.SetItem,{x=self.dungeonServerData.playerPoint.x,y=self.dungeonServerData.playerPoint.y,item=item})
	        	break
	        end 
	    end
	end
	return e
end

--使用龙珠，验证龙珠数量够不够
local function useDragonBall(self,red,yellow,blue)
	local flag = true
	local items = self.dungeonServerData:GetItems()
	red = red * csv.CallCsvData("DungeonParamCsvData","ConditionParam1","ConditionParam1FromArray",4,1)
	yellow = yellow * csv.CallCsvData("DungeonParamCsvData","ConditionParam1","ConditionParam1FromArray",5,1)
	blue = blue * csv.CallCsvData("DungeonParamCsvData","ConditionParam1","ConditionParam1FromArray",6,1)
	local useItems = {}
	for i=1,#items do
        local item = items[i]
        local itemType = dungeonDefine.ItemType[csv.CallCsvData("DungeonItemCsvData","ItemType","ItemType",item.id)] 
        if itemType == dungeonDefine.ItemType.DragonBallRed and red > 0 then
        	if item.count < red then
        		flag = false
        		break
        	end
        	table.insert(useItems,{id=item.id,count=red})
        elseif itemType == dungeonDefine.ItemType.DragonBallYellow and yellow > 0 then
            if item.count < yellow then
        		flag = false
        		break
        	end
        	table.insert(useItems,{id=item.id,count=yellow})
        elseif itemType == dungeonDefine.ItemType.DragonBallBlue and blue > 0 then
            if item.count < blue then
        		flag = false
        		break
        	end
        	table.insert(useItems,{id=item.id,count=blue})
        end 
    end
    if flag then
    	for i=1,#useItems do
	    	local useItem = useItems[i]
	    	local item = self.dungeonServerData:UseItem(useItem.id,useItem.count)
	    	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.SetItem,{x=self.dungeonServerData.playerPoint.x,y=self.dungeonServerData.playerPoint.y,item=item})
	    end
    end
    return flag
end

function M.ActiveDragonBall(self,eventId,red,yellow,blue)
	local e = dungeonDefine.ProtocolErrorType.UseDragonBallError
	local isSuccess = false
	local pos = nil
	local index = 0
	for i=self.dungeonServerData.playerPoint.x - 1,self.dungeonServerData.playerPoint.x + 1 do
	 	for j=self.dungeonServerData.playerPoint.y - 1,self.dungeonServerData.playerPoint.y + 1 do
	 		local c = self.dungeonServerData:GetGrid(i,j)
	 		if c ~= nil and dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Event,true) then
	 			local t = dungeonDefine.EventType[csv.CallCsvData("DungeonEventCsvData","EventType","EventType",c.stuff.id)]
	 			if t == dungeonDefine.EventType.DragonBall then
	 				pos = {x=i,y=j}
	 				break
	 			end
	 		end
		end
		if pos ~= nil then
			break
		end
	end
	if pos ~= nil then
		local effectArray = csv.CallCsvData("DungeonEventCsvData","EventSuccessLib","EventSuccessLibArray",eventId)
        local desc = ""
        for i=1,#effectArray do
            local redNum = csv.CallCsvData("DungeonEventCsvData","EventPara1","EventPara1FromArray",eventId,i)
            local yellowNum = csv.CallCsvData("DungeonEventCsvData","EventPara2","EventPara2FromArray",eventId,i)
            local blueNum = csv.CallCsvData("DungeonEventCsvData","EventPara3","EventPara3FromArray",eventId,i)
            if redNum == red and yellowNum == yellow and blueNum == blue then
            	if useDragonBall(self,red,yellow,blue) then
            		e = dungeonDefine.ProtocolErrorType.None
	                local rate = csv.CallCsvData("DungeonEventCsvData","EventChoiceSuccessRate","EventChoiceSuccessRateFromArray",eventId,i)
	                if rate == -1 then
	                    isSuccess = true
	                else
	                    local rNum = math.random(1,1000)
						if rate >= rNum then
							isSuccess = true
						end
	                end
	                local effectIds
	                if isSuccess then
	                	effectIds = effectArray[i]
	                else
	                	effectIds = csv.CallCsvData("DungeonEventCsvData","EventFailLib","EventFailLibFromArray",eventId,i)
	                end
	                for i=1,#effectIds do
	                	local effectId = effectIds[i]
	                	if effectId > 0 then
	                		self:AddEffect(pos.x,pos.y,effectId)
	                	end
	                end
	                index = i
	                break
            	end
            end
        end
	end
	return e,isSuccess,index
end

--选择事件
function M.ChoiceEvent(self,eventId,index)
	local isSuccess = false
	local stuffList = {}
	local e = dungeonDefine.ProtocolErrorType.EventIdError
	local currentEvent = getCurrentEvent(self)
	if currentEvent ~= nil and currentEvent.id == eventId then
		if index > 0 then
			doRound(self,dungeonDefine.EffectRoundType.Event)
			local c = self.dungeonServerData:GetGrid(currentEvent.x,currentEvent.y)
			if dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Event,true) and c.stuff.id == eventId then
				e = dungeonDefine.ProtocolErrorType.None
				c.stuff.number = c.stuff.number - 1
				local stuffIndex = c.stuff.index
				if c.stuff.number == 0 then
					removeStuff(self,currentEvent.x,currentEvent.y)
				end
				local rate = csv.CallCsvData("DungeonEventCsvData","EventChoiceSuccessRate","EventChoiceSuccessRateFromArray",eventId,index)
				if rate == -1 then
					isSuccess = true
				else
					local rNum = math.random(1,1000)
					if rate >= rNum then
						isSuccess = true
					end
				end
				
				local libList
				if isSuccess then
					libList = csv.CallCsvData("DungeonEventCsvData","EventSuccessLib","EventSuccessLibFromArray",eventId,index)
				else
					libList = csv.CallCsvData("DungeonEventCsvData","EventFailLib","EventFailLibFromArray",eventId,index)
				end
				for i=1,#libList do
					local libId = libList[i]
					if libId ~= 0 then
						local stuffs = self.dungeonServerData.dungeon:GetStuffsFromLibId(libId,stuffIndex)
						for j=1,#stuffs do
							local stuff = stuffs[j]
							if stuff.stuffType == dungeonDefine.StuffType.Monster or stuff.stuffType == dungeonDefine.StuffType.Event then
								c.gridType = dungeonDefine.MazeGridType.Stuff
								c.stuff = stuff
								showStuff(self,currentEvent.x,currentEvent.y,stuff)
							else
								if stuff.stuffType == dungeonDefine.StuffType.Item then
									addItem(self,currentEvent.x,currentEvent.y,stuff.id,stuff.number,stuff.followId,stuff.index)
								elseif stuff.stuffType == dungeonDefine.StuffType.Effect then
									self:AddEffect(currentEvent.x,currentEvent.y,stuff.id)
								end
							end
							table.insert(stuffList,stuff)
						end
					end
				end
				self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.FinishCommonEvent,{x=currentEvent.x,y=currentEvent.y,dungeonEvent={id=eventId,index=index,isSuccess=isSuccess}})
				self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.RefreshGrid,{x=currentEvent.x,y=currentEvent.y,gridClass=c})
			end

		else
			e = dungeonDefine.ProtocolErrorType.None
		end
	end
	removeCurrentEvent(self)
	return e,isSuccess,stuffList
end

--处理物品
local function getItem(self,x,y)
	local c = self.dungeonServerData:GetGrid(x,y)
	addItem(self,x,y,c.stuff.id,c.stuff.number,c.stuff.followId,c.stuff.index)
	removeStuff(self,x,y)
end

function M.CheckIsItem(self,x,y)
	local c = self.dungeonServerData:GetGrid(x,y)
	if dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Item,true) then
		getItem(self,x,y)
		return dungeonDefine.ProtocolErrorType.None
	end
	return dungeonDefine.ProtocolErrorType.CanNotGetItem
end

--打开格子
function M.OpenCoverGrid(self,x,y,isFirst)
	local c = self.dungeonServerData:GetGrid(x,y)
	c.isOpen = true
	c.isMist = false
	c.isBan = false
	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.OpenGrid,{x=x,y=y,gridClass=c})
	if c.gridType ~= dungeonDefine.MazeGridType.Block then
		OpenAllCrossMist(self)
		if c.gridType == dungeonDefine.MazeGridType.Stuff then
			showStuff(self,x,y,c.stuff)
		end
	end
	if not isFirst then
		onRound(self)
	end
end



function M.ChoiceRelic(self,effectId)
	local ret = dungeonDefine.ProtocolErrorType.RelicIdError
	if self.dungeonServerData.curentRelics ~= nil then
		for i=1,#self.dungeonServerData.curentRelics.ids do
			if self.dungeonServerData.curentRelics.ids[i] == effectId then
				self:AddEffect(self.dungeonServerData.curentRelics.x,self.dungeonServerData.curentRelics.y,effectId)
				ret = dungeonDefine.ProtocolErrorType.None
				break
			end
		end
		removeStuff(self,self.dungeonServerData.curentRelics.x,self.dungeonServerData.curentRelics.y)
		removeCurrentEvent(self)
	end
	self.dungeonServerData.curentRelics = nil
	return ret
end

function M.GetRelics(self,eventId)
	local e = dungeonDefine.ProtocolErrorType.EventIdError
	local currentEvent = getCurrentEvent(self)
	if currentEvent ~= nil and currentEvent.id == eventId then
		local c = self.dungeonServerData:GetGrid(currentEvent.x,currentEvent.y)
		if dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Event,true) and c.stuff.id == eventId then
			e = dungeonDefine.ProtocolErrorType.None
			if self.dungeonServerData.curentRelics == nil then
				self.dungeonServerData.curentRelics = {}
				self.dungeonServerData.curentRelics.x = currentEvent.x
				self.dungeonServerData.curentRelics.y = currentEvent.y
				self.dungeonServerData.curentRelics.ids = {}
				local lib = csv.CallCsvData("DungeonEventCsvData","EventSuccessLib","EventSuccessLibFromArray",eventId,1)[1]
				local stuffs = self.dungeonServerData.dungeon:GetStuffsFromLibId(lib,1)
				for i=1,#stuffs do
					local stuff = stuffs[i]
					table.insert(self.dungeonServerData.curentRelics.ids,stuff.id)
				end
			end
		end
	end
	return e,self.dungeonServerData.curentRelics
end

function M.DoEvent(self)
	if not self.isDoEvent then
		local event = getCurrentEvent(self)
		if event ~= nil then
			self.isDoEvent = true
			self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.DoEvent,{x=event.x,y=event.y})
		end
	end
end

--寻路过去看能否到达
local function checkTargetPos(self,x,y,playerX,playerY,isFirst)
	local flag = false
	if isFirst then
		flag = true
	else
		--先要能走到客戶端玩家的位置
		local path
		local lastPos
		if self.dungeonServerData.playerPoint.x == playerX and self.dungeonServerData.playerPoint.y == playerY then
			lastPos = {x=playerX,y=playerY}
		else
			path = astar.Seek(self.dungeonServerData:GetMaze(),self.dungeonServerData.playerPoint.x,self.dungeonServerData.playerPoint.y,playerX,playerY)
			lastPos = path[#path]
		end
		if lastPos.x == playerX and lastPos.y == playerY then
			--再看能否走到目標點
			path = astar.Seek(self.dungeonServerData:GetMaze(),playerX,playerY,x,y)
			lastPos = path[#path]
			--玩家站上面或者再玩家附近一格都符合要求
			if (lastPos.x==x and lastPos.y==y) or math.abs(lastPos.x-x)+math.abs(lastPos.y-y) == 1 then
				self.dungeonServerData:SetHeroMazePos(lastPos.x,lastPos.y)
				flag = true
			end
		end
	end
	return flag
end

function M.GoNextTier(self)
	local maze = self.dungeonServerData:GetMaze()
	local x,y
    for i=1,#maze do
        for j=1,#maze[i] do
            local c = maze[i][j]
            if c.gridType == dungeonDefine.MazeGridType.Exit then
                x = i
                y = j
                break
            end
        end
    end
    if checkTargetPos(self,x,y,self.dungeonServerData.playerPoint.x,self.dungeonServerData.playerPoint.y) then
    	local c = self.dungeonServerData:GetGrid(self.dungeonServerData.playerPoint.x,self.dungeonServerData.playerPoint.y)
		if c.gridType == dungeonDefine.MazeGridType.Exit and self.dungeonServerData:CanOpenDoor() then
			return dungeonDefine.ProtocolErrorType.None
		end
    end
	return dungeonDefine.ProtocolErrorType.CanNotGoNextTier
end

function M.OperateGrid(self,x,y,playerX,playerY,isFirst)
	if not checkTargetPos(self,x,y,playerX,playerY,isFirst) then
		return dungeonDefine.ProtocolErrorType.MovePosError
	end
	local c = self.dungeonServerData:GetGrid(x,y)
	if c.isOpen and self.dungeonServerData:IsHeroPos(x,y) then
		return dungeonDefine.OperateGridType.None
	end
	if c.isMist or c.isBan then
		return dungeonDefine.OperateGridType.None
	end
	if not isFirst and not isNearPlayer(self,x,y) then
		return dungeonDefine.OperateGridType.None
	end
	if not c.isOpen then
		self:OpenCoverGrid(x,y,isFirst)
		return dungeonDefine.OperateGridType.Open
	else
		local c = self.dungeonServerData:GetGrid(x,y)
		if c.gridType == dungeonDefine.MazeGridType.Stuff then
			if c.stuff.stuffType == dungeonDefine.StuffType.Monster then
				return dungeonDefine.OperateGridType.Monster
			elseif c.stuff.stuffType == dungeonDefine.StuffType.Event then
				AddEvent(self,x,y)
				return dungeonDefine.OperateGridType.Event
			end
		else
			return dungeonDefine.OperateGridType.None
		end
		
	end
end

function M.ClearSteps(self)
	self.dungeonStep:ClearStepList()
end

function M.GetSteps(self)
	return self.dungeonStep:GetStepList()
end

function M.Clear(self)
	clearCurrentEvent(self)
	self.dungeonStep:GetStepList()
end

--选择事件
function M.Create(self,mapId)
	--开局就加上的buff
    local effects = csv.CallCsvData("DungeonMapCsvData","MapEffect","MapEffectArray",mapId)
    for i=1,#effects do
        self:AddEffect(self.dungeonServerData.playerPoint.x,self.dungeonServerData.playerPoint.y,effects[i])
    end
    --开局遍历所有迷宫单位的effect，0回合的直接执行
    local maze = self.dungeonServerData:GetMaze()
	local x,y
    for i=1,#maze do
        for j=1,#maze[i] do
            local c = maze[i][j]
            if dungeonDefine:IsStuff(c,true) then
            	local monsterEffects = c.stuff.effects
            	self.lockStuffEffect = {x=i,y=j}
				for a=1,#monsterEffects do
    				local e = monsterEffects[a]
    				if e.roundNumber == 0 then
						e.roundNumber = e.roundNumber + 1
						self:DoEffect(e,false,i,j)
					end
    			end
    			self.lockStuffEffect = nil
    			--effect执行完后再删除需要删除的effect
			    if self.removeEffectList ~= nil then
			    	for b=1,#self.removeEffectList do
			    		local re = self.removeEffectList[b]
			    		self:RemoveStuffEffect(i,j,re.effect)
			    	end
			    	self.removeEffectList = nil
			    end
            end
        end
    end
end

function M.Init(self,data,dungeon)
	self.isDoEvent = false
	self.dungeonServerData = data
	self.dungeonStep = dungeonStepModel.new()
	self.dungeonStep:Init()
end

function M.Dispose(self)
	self:Clear()
	self.dungeonStep:Dispose()
end

function M.new()
    local t = {
    	dungeonServerData = nil,
        curentRelics = nil, --当前进行的遗物选择
		currentEvent = nil, --当前进行的事件
    }
    return setmetatable(t, {__index = M})
end


  
return M  
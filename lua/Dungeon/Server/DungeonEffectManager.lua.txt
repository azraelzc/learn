local csv = require("Dungeon.LuaCallCsvData")
local dungeonDefine = require("Dungeon.DungeonDefine")
local dungeonUtils = require("Dungeon.DungeonUtils")

local M = {}

--返回队伍effects
local function getTargetEffects(self,isPlayer,x,y)
	local effects = {}
	if isPlayer then
		effects = self.dungeonServerData.effectList
	else
		local grid = self.dungeonServerData:GetGrid(x,y)
		if dungeonDefine:IsStuff(grid,true) then
			effects = grid.stuff.effects
		end
	end
	return effects
end

--根据配置返回unitData
--[[
	unitData={
		x,
		y,
		isPlayer,
		isMvp,
		data = {
			HeroHp,
			PetHp={}
		}
	}
]]
local function getTargetUnitData(self,effect,teamDatas)
	local id = effect.id
	local level = effect.level
	local targetUnitType = dungeonDefine.EffectTargetUnitType[csv.CallCsvData("DungeonEffectCsvData","TargetUnitType","TargetUnitTypeFromArray",id,level)]
	local targetUnitNum = csv.CallCsvData("DungeonEffectCsvData","TargetUnitNum","TargetUnitNumFromArray",id,level)
	local retUnitDatas = {}
	local notInsertUnitDatas = {}
	for i=1,#teamDatas do
		local teamData = teamDatas[i]
		local unitDatas = teamData.data
		for j=1,#unitDatas do
			local unitData = unitDatas[j]
			local isInsert = false
			local retUnitData = {}
			retUnitData.x = teamData.x
			retUnitData.y = teamData.y
			retUnitData.isPlayer = teamData.isPlayer
			retUnitData.isMvp = teamData.isMvp
			retUnitData.data = unitData
			if targetUnitType == dungeonDefine.EffectTargetUnitType.LowestHP then
				--血量升序
				if unitData.HeroHp > 0 then
					for a=1,#retUnitDatas do
						if retUnitDatas[a].data.HeroHp > unitData.HeroHp then
							isInsert = true
							table.insert(retUnitDatas,i,retUnitData)
						end
					end
					if targetUnitNum > 0 then
						targetUnitNum = targetUnitNum - 1
						if not isInsert then
							isInsert = true
							table.insert(retUnitDatas,retUnitData)
						end
					else
						if isInsert then
							table.remove(retUnitDatas,#retUnitDatas)
						end
					end
				end
			elseif targetUnitType == dungeonDefine.EffectTargetUnitType.HeightHP then
				--血量倒序
				if unitData.HeroHp > 0 then
					for a=1,#retUnitDatas do
						if retUnitDatas[a].data.HeroHp < unitData.HeroHp then
							isInsert = true
							table.insert(retUnitDatas,i,retUnitData)
						end
					end
					if targetUnitNum > 0 then
						targetUnitNum = targetUnitNum - 1
						if not isInsert then
							isInsert = true
							table.insert(retUnitDatas,retUnitData)
						end
					else
						if isInsert then
							table.remove(retUnitDatas,#retUnitDatas)
						end
					end
				end
			elseif targetUnitType == dungeonDefine.EffectTargetUnitType.Dead then
				--死亡的敌人
				if unitData.HeroHp == 0 then
					isInsert = true
					table.insert(retUnitDatas,retUnitData)
				end
			elseif targetUnitType == dungeonDefine.EffectTargetUnitType.PetDead then
				if unitData.HeroHp > 0 then
					for i=1,#unitData.PetHp do
						if unitData.PetHp[i] == 0 then
							isInsert = true
							table.insert(retUnitDatas,retUnitData)
							break
						end
					end
				end
			elseif targetUnitType == dungeonDefine.EffectTargetUnitType.Random then
				if unitData.HeroHp > 0 then
					isInsert = true
					table.insert(retUnitDatas,retUnitData)
				end
			end
			if not isInsert then
				table.insert(notInsertUnitDatas,retUnitData)
			end
		end
	end
	--死亡单位和随机复活单位重新根据数量随机一下
	if targetUnitType == dungeonDefine.EffectTargetUnitType.Dead then
		if #retUnitDatas < targetUnitNum then
			while(#retUnitDatas < targetUnitNum and #notInsertUnitDatas > 0) do
				local rNum = math.random(1,#notInsertUnitDatas)
				table.insert(retUnitDatas,notInsertUnitDatas[rNum])
				table.remove(notInsertUnitDatas,rNum)
			end
		end
		while(targetUnitNum < #retUnitDatas) do
			local rNum = math.random(1,#retUnitDatas)
			table.remove(retUnitDatas,rNum)
		end
	elseif targetUnitType == dungeonDefine.EffectTargetUnitType.PetDead then
		while(targetUnitNum < #retUnitDatas) do
			local rNum = math.random(1,#retUnitDatas)
			table.remove(retUnitDatas,rNum)
		end
	elseif targetUnitType == dungeonDefine.EffectTargetUnitType.Random then
		if #retUnitDatas > targetUnitNum then
			while(#retUnitDatas > targetUnitNum) do
				local rNum = math.random(1,#retUnitDatas)
				table.remove(retUnitDatas,rNum)
			end
		end
	end
	return retUnitDatas
end

local function getTargetType(self,effect,isPlayer,x,y)
	local playerTeam = false 		--玩家数据
	local selfTeam = false			--传入的怪物本身
	local playerAllyTeam = false	--玩家盟友数据，不含monsterData数据
	local enemyTeam = false			--敌人数据，不含monsterData数据
	local isEnemy = false
	if not isPlayer then
		local grid = self.dungeonServerData:GetGrid(x,y)
		if dungeonDefine:IsStuffType(grid,dungeonDefine.StuffType.Monster,true) then
			isEnemy = grid.stuff.monsterData.isEnemy
		end
	end
	local targetTeamType = dungeonDefine.EffectTargetTeamType[csv.CallCsvData("DungeonEffectCsvData","TargetTeam","TargetTeamFromArray",effect.id,effect.level)]
	if targetTeamType == dungeonDefine.EffectTargetTeamType.All then
		--所有人
		selfTeam = true
		playerTeam = true
		playerAllyTeam = true
		enemyTeam = true
	elseif targetTeamType == dungeonDefine.EffectTargetTeamType.ExceptSelf then
		if isPlayer then
			selfTeam = true
			playerAllyTeam = true
			enemyTeam = true
		else
			playerTeam = true
			playerAllyTeam = true
			enemyTeam = true
		end
	elseif targetTeamType == dungeonDefine.EffectTargetTeamType.Self then
		--对自己
		if isPlayer then
			playerTeam = true
		else
			selfTeam = true
		end
	elseif targetTeamType == dungeonDefine.EffectTargetTeamType.Ally then
		--对盟友
		if isPlayer then
			--玩家自己触发时获取其他盟友
			playerAllyTeam = true
		else
			--盟友怪物
			playerTeam = true
			playerAllyTeam = true
		end
	elseif targetTeamType == dungeonDefine.EffectTargetTeamType.Friendly then
		--所有友方
		if isPlayer then
			playerTeam = true
			playerAllyTeam = true
		else
			selfTeam = true
			playerTeam = true
			playerAllyTeam = true
		end
	elseif targetTeamType == dungeonDefine.EffectTargetTeamType.Enemy then
		enemyTeam = true
		if isEnemy then
			selfTeam = true
		end
	elseif targetTeamType == dungeonDefine.EffectTargetTeamType.EnemyAlly then
		enemyTeam = true
	elseif targetTeamType == dungeonDefine.EffectTargetTeamType.TargetAlly or targetTeamType == dungeonDefine.EffectTargetTeamType.TargetEnemy then
		selfTeam = true
	elseif targetTeamType == dungeonDefine.EffectTargetTeamType.Player then
		playerTeam = true
	end
	return playerTeam,selfTeam,playerAllyTeam,enemyTeam
end

--根据effect配置获取队伍
--[[
	teamData={
		x,
		y,
		isPlayer,
		isMvp,
		data,		队伍里单位信息
		effects
	}
]]
local function getTargetTeamData(self,effect,isPlayer,x,y,addTeamNum)
	local targetTeamNum = csv.CallCsvData("DungeonEffectCsvData","TargetTeamNum","TargetTeamNumFromArray",effect.id,effect.level) + addTeamNum
	local stuff = nil
	local monsterData = nil
	if not isPlayer then
		local grid = self.dungeonServerData:GetGrid(x,y)
		if dungeonDefine:IsStuff(grid,true) then
			stuff = grid.stuff
			monsterData = stuff.monsterData
		end
	end
	local teamDatas = {}
	local playerTeam,selfTeam,playerAllyTeam,enemyTeam = getTargetType(self,effect,isPlayer,x,y)
	if selfTeam and stuff ~= nil then
		local teamData = {}
		teamData.x = x
		teamData.y = y
		teamData.isPlayer = false
		if monsterData ~= nil then
			teamData.isMvp = monsterData.isMvp
			teamData.data = monsterData.monsters
		else
			teamData.isMvp = false
			teamData.data = {}
		end
		teamData.effects = stuff.effects
		table.insert(teamDatas,teamData)
	end
	if playerTeam then
		local teamData = {}
		teamData.x = self.dungeonServerData.playerPoint.x
		teamData.y = self.dungeonServerData.playerPoint.y
		teamData.isPlayer = true
		teamData.isMvp = false
		teamData.data = self.dungeonServerData.heroDatas
		teamData.effects = self.dungeonServerData.effectList
		table.insert(teamDatas,teamData)
	end
	local maze = self.dungeonServerData:GetMaze()
	for i=1,#maze do
		for j=1,#maze[i] do
			local c = maze[i][j]
			if (x ~= i or y ~= j) and dungeonDefine:IsStuff(c,true) then
				local isEnemy = false
				local isMvp = false
				local monsters = {}
				if dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Monster,true) then
					isEnemy = c.stuff.monsterData.isEnemy
					isMvp = c.stuff.monsterData.isMvp
					monsters = c.stuff.monsterData.monsters
				end
				if (playerAllyTeam and not isEnemy) or (enemyTeam and isEnemy) then
					local teamData = {}
					teamData.x = i
					teamData.y = j
					teamData.isPlayer = false
					teamData.isMvp = isMvp
					teamData.data = monsters
					teamData.effects = c.stuff.effects
					table.insert(teamDatas,teamData)
				end
			end
		end
	end
	while(targetTeamNum < #teamDatas) do 
		local rNum = math.random(1,#teamDatas)
		table.remove(teamDatas,rNum)
	end
	return teamDatas
end

local function insertDirEffectTargetTeam(self,teamDatas,x,y,playerTeam,playerAllyTeam,enemyTeam)
	local c = self.dungeonServerData:GetGrid(x,y)
	if dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Monster,true) then
		if (c.isEnemy and enemyTeam) or (not c.isEnemy and playerAllyTeam) then
			local teamData = {}
			teamData.x = x
			teamData.y = y
			teamData.isPlayer = false
			teamData.isMvp = c.stuff.monsterData.isMvp
			teamData.data = c.stuff.monsterData.monsters
			teamData.effects = c.stuff.effects
			table.insert(teamDatas,teamData)
		end
	elseif x == self.dungeonServerData.playerPoint.x and y == self.dungeonServerData.playerPoint.y and playerTeam then
		local teamData = {}
		teamData.x = x
		teamData.y = y
		teamData.isPlayer = true
		teamData.isMvp = false
		teamData.data = self.dungeonServerData.heroDatas
		teamData.effects = self.dungeonServerData.effectList
		table.insert(teamDatas,teamData)
	end	
end

--获取方向类型技能队伍
local function getDirEffectTargetTeamData(self,effect,isPlayer,x,y,addTeamNum)
	local length = csv.CallCsvData("DungeonEffectCsvData","TargetUnitNum","TargetUnitNumFromArray",effect.id,effect.level) + addTeamNum
	local dirType = csv.CallCsvData("DungeonEffectCsvData","EffectPara1","EffectPara1FromArray",effect.id,effect.level)
	local playerTeam,selfTeam,playerAllyTeam,enemyTeam = getTargetType(self,effect,isPlayer,x,y)
	local teamDatas = {}
	local mazeLength = self.dungeonServerData:GetMazeLength(self)
	if length > mazeLength then
		length = mazeLength
	end
	if dirType == dungeonDefine.DirEffectType.X then
		for i=1,length do
			for j=-1,1 do
				for k=-1,1 do
					if j ~= 0 and k ~= 0 then
						insertDirEffectTargetTeam(self,teamDatas,x+i*j,y+i*k,playerTeam,playerAllyTeam,enemyTeam)
					end
				end
			end
		end
	elseif dirType == dungeonDefine.DirEffectType.Cross then
		for i=-length,length do
			if i ~= 0 then
				insertDirEffectTargetTeam(self,teamDatas,x+i,y,playerTeam,playerAllyTeam,enemyTeam)
				insertDirEffectTargetTeam(self,teamDatas,x,y+i,playerTeam,playerAllyTeam,enemyTeam)
			end
		end
	end
	return teamDatas
end

--所有改变hp的走这里
local function ChangeUnitHP(self,unit,hpNumber,targetHero,targetPet,isPlayer,x,y)
	--print("=====ChangeUnitHP====",hpNumber,targetHero,targetPet,isPlayer,x,y)
	local addHeroHp = 0
	local addPetHp = {0,0,0,0}
	if targetHero then
		addHeroHp = hpNumber
	end
	if targetPet then
		for j=1,#unit.PetHp do
			addPetHp[j] = hpNumber
		end
	end	
	self.dungeonServerData:AddUnitHP(x,y,unit,addHeroHp,addPetHp)
	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.ChangeHP,{x=x,y=y,isPlayer=isPlayer,paraInt1=unit.id,paraInt2=unit.generateId,unitHPData=unit})
end



local function SwitchAddEffect(self,effect,teamDatas)
	local libId = csv.CallCsvData("DungeonEffectCsvData","EffectPara1","EffectPara1FromArray",effect.id,effect.level)
	local effectIds = csv.CallCsvData("DungeonLibCsvData","Reward","RewardArray",libId)
	local index = math.fmod(effect.totalTriggerCount-1, #effectIds) + 1
	local effectId = effectIds[index]
	for i=1,#teamDatas do
		local teamData = teamDatas[i]
		if teamData.isPlayer then
			self.dungeonServerData.dungeonLogic:AddEffect(teamData.x,teamData.y,effectId)
		else
			self.dungeonServerData.dungeonLogic:AddStuffEffect(teamData.x,teamData.y,effectId)
		end
	end
end

local function GetCacheEffect(self,effect,teamDatas)
	local cacheEffects = self.dungeonServerData.cacheEffectList
	--print("=====GetCacheEffect teamDatas====",dungeonUtils.PairTabMsg(teamDatas))
	--print("=====GetCacheEffect cacheEffects====",dungeonUtils.PairTabMsg(cacheEffects))
	if #cacheEffects > 0 then
		for i=1,#teamDatas do
			local teamData = teamDatas[i]
			if teamData.isPlayer then
				for j=1,#cacheEffects do
					local e = cacheEffects[j]
					self.dungeonServerData.dungeonLogic:AddEffect(teamData.x,teamData.y,e.id,e.level,e.overlay)
				end
			else
				for j=1,#cacheEffects do
					local e = cacheEffects[j]
					self.dungeonServerData.dungeonLogic:AddStuffEffect(teamData.x,teamData.y,e.id,e.level,e.overlay)
				end
			end
		end
	end
end

local function AddCacheEffect(self,effect,isPlayer,x,y)
	local addEffectId = csv.CallCsvData("DungeonEffectCsvData","EffectPara1","EffectPara1FromArray",effect.id,effect.level)
	local probility = csv.CallCsvData("DungeonEffectCsvData","EffectPara2","EffectPara2FromArray",effect.id,effect.level)
	local rNum = math.random(1,1000)
	if rNum <= probility then
		self.dungeonServerData.dungeonLogic:AddCacheEffect(isPlayer,x,y,addEffectId)
	end
end

local function AddEffect(self,effect,teamDatas)
	local addEffectId = csv.CallCsvData("DungeonEffectCsvData","EffectPara1","EffectPara1FromArray",effect.id,effect.level)
	local probility = csv.CallCsvData("DungeonEffectCsvData","EffectPara2","EffectPara2FromArray",effect.id,effect.level)
	local rNum = math.random(1,1000)
	if rNum <= probility then
		for i=1,#teamDatas do
			local teamData = teamDatas[i]
			if teamData.isPlayer then
				self.dungeonServerData.dungeonLogic:AddEffect(teamData.x,teamData.y,addEffectId)
			else
				self.dungeonServerData.dungeonLogic:AddStuffEffect(teamData.x,teamData.y,addEffectId)
			end
		end
	end
end

local function ClearStifle(self,isPlayer,x,y)
	for i=1,#self.dungeonServerData.effectList do
	 	local effect = self.dungeonServerData.effectList[i]
 		effect.overlay = 1
 		self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.RefreshEffect,{x=x,y=y,effect=effect,isPlayer=isPlayer})
	 end 
end

local function Stifle(self,effect)
	local stifleDamageNum = csv.CallCsvData("DungeonEffectCsvData","EffectPara1","EffectPara1FromArray",effect.id,effect.level)
	if effect.overlay >= stifleDamageNum then
		local hpPer = -csv.CallCsvData("DungeonEffectCsvData","EffectPara2","EffectPara2FromArray",effect.id,effect.level)
		local x = self.dungeonServerData.playerPoint.x
		local y = self.dungeonServerData.playerPoint.y
		local param = 10000 * hpPer / 1000
		local teamData = {}
		teamData.x = x
		teamData.y = y
		teamData.isPlayer = true
		teamData.effect = effect
		teamData.paraInt1 = param
		self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.TeamChangeHPStart,teamData)
		for i=1,#self.dungeonServerData.heroDatas do
			local d = self.dungeonServerData.heroDatas[i]
			local addHeroHp = 0
			local addPetHp = {0,0,0,0}
			if d.HeroHp > 0 then
				addHeroHp = param
			end
			for j=1,#d.PetHp do
				if d.PetHp[j] > 0 then
					addPetHp[j] = param
				end
			end		
			self.dungeonServerData:AddUnitHP(x,y,d,addHeroHp,addPetHp)
			self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.ChangeHP,{x=x,y=y,paraInt1=d.id,isPlayer=true,paraInt2=d.generateId,unitHPData=d})
		end
		self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.TeamChangeHPEnd,teamData)
	else
		effect.overlay = effect.overlay + 1
	end
end

local function OpenTargetGrid(self,x,y)
	local c = self.dungeonServerData:GetGrid(x,y)
	if not c.isOpen then
		self.dungeonServerData.dungeonLogic:OpenCoverGrid(x,y,true)
	end
end

local function OpenGrid(self,effect)
	local openNum = csv.CallCsvData("DungeonEffectCsvData","EffectPara1","EffectPara1FromArray",effect.id,effect.level)
	local coverGridList = {}
	local maze = self.dungeonServerData:GetMaze()
	for i=1,#maze do
		for j=1,#maze[i] do
			local c = maze[i][j]
			if not c.isOpen then
				local pos = {x=i,y=j}
				table.insert(coverGridList,pos)
			end
		end
	end
	local i = 0
	while(openNum > 0 and #coverGridList > 0) do
		i=i+1
		openNum = openNum - 1
		local rNum = math.random(1,#coverGridList)
		local pos = coverGridList[rNum]
		OpenTargetGrid(self,pos.x,pos.y)
		table.remove(coverGridList,rNum)
	end
end

local function Resurrection(self,effect,teamDatas,targetHero,targetPet)
	local notifyTeam = {}
	local unitDatas = getTargetUnitData(self,effect,teamDatas)
	local para1 = csv.CallCsvData("DungeonEffectCsvData","EffectPara1","EffectPara1FromArray",effect.id,effect.level)
	local effectMVP = csv.CallCsvData("DungeonEffectCsvData","EffectMVP","EffectMVPFromArray",effect.id,effect.level) 
	local param = 10000 * para1 / 1000
	--print("====Resurrection teamDatas===",dungeonUtils.PairTabMsg(teamDatas))
	--print("====Resurrection unitDatas===",dungeonUtils.PairTabMsg(unitDatas))
	for i=1,#unitDatas do
		local unitData = unitDatas[i]
		local d = unitData.data
		local notified = false
		for j=1,#notifyTeam do
			local nt = notifyTeam[j]
			if nt.x == unitData.x and nt.y == unitData.y then
				notified = true
				break
			end
		end
		if not notified then
			local nt = {}
			nt.x = unitData.x
			nt.y = unitData.y
			nt.isPlayer = unitData.isPlayer
			nt.effect = effect
			nt.paraInt1 = param
			table.insert(notifyTeam,nt)
			self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.TeamChangeHPStart,nt)
		end
		if effectMVP or not unitData.isMvp then
			ChangeUnitHP(self,unitData.data,param,targetHero,targetPet,unitData.isPlayer,unitData.x,unitData.y)
		end
		
	end
	for i=1,#notifyTeam do
		local nt = notifyTeam[i]
		self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.TeamChangeHPEnd,nt)
	end
end

local function RelieveDebuff(self,effect,isPlayer,x,y)
	local id = effect.id
	local effects
	if isPlayer then
		effects = self.dungeonServerData.effectList
	else
		local monsterData = nil
		local grid = self.dungeonServerData:GetGrid(x,y)
		if dungeonDefine:IsStuffType(grid,dungeonDefine.StuffType.Monster,true) then
			monsterData = grid.stuff.monsterData
			effects = grid.stuff.effects
		end
	end
	local removeBuffList = {}
	for i=1,#effects do
		local e = effects[i]
		local effectTypeStr = csv.CallCsvData("DungeonEffectCsvData","EffectType","EffectTypeFromArray",e.id,e.level)
		local effectType = dungeonDefine.EffectType[effectTypeStr]
		if effectType == dungeonDefine.EffectType.DEBUFF then
			table.insert(removeBuffList,e)
		end
	end
	for i=1,#removeBuffList do
		local e = removeBuffList[i]
		if isPlayer then
			self.dungeonServerData.dungeonLogic:RemoveEffect(self.dungeonServerData.playerPoint.x,self.dungeonServerData.playerPoint.y,e)
		else
			self.dungeonServerData.dungeonLogic:RemoveStuffEffect(x,y,e)
		end
	end
end

local function DoSputteringHP(self,effect,isMvp,effectMVP,damage,targetHero,targetPet,units,isPlayer,x,y)
	local nt = {}
	nt.x = x
	nt.y = y
	nt.isPlayer = isPlayer
	nt.effect = effect
	nt.paraInt1 = damage
	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.TeamChangeHPStart,nt)
	if effectMVP or not isMvp then
		for j=1,#units do
			ChangeUnitHP(self,units[j],damage,targetHero,targetPet,isPlayer,x,y)
		end
	end
	self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.TeamChangeHPEnd,nt)
end

local function DoSputteringGrid(self,effect,effectMVP,sourceGrid,damage,targetHero,targetPet,x,y)
	--print("===DoSputteringGrid===",effect.id,sourceGrid,damage,targetHero,targetPet,x,y)
	local grid = self.dungeonServerData:GetGrid(x,y)
	if grid ~= nil then
		if sourceGrid ~= nil then
			if sourceGrid.stuff.monsterData.isEnemy then
				if dungeonDefine:IsStuffType(grid,dungeonDefine.StuffType.Monster,true) then
					if not grid.stuff.monsterData.isEnemy then
						DoSputteringHP(self,effect,grid.stuff.monsterData.isMvp,effectMVP,damage,targetHero,targetPet,grid.stuff.monsterData.monsters,false,x,y)
					end 
				else
					if newX == self.dungeonServerData.playerPoint.x and y == self.dungeonServerData.playerPoint.y then
						DoSputteringHP(self,effect,false,effectMVP,damage,targetHero,targetPet,self.dungeonServerData.heroDatas,true,x,y)
					end
				end	
			else
				if dungeonDefine:IsStuffType(grid,dungeonDefine.StuffType.Monster,true) then
					if grid.stuff.monsterData.isEnemy then
						DoSputteringHP(self,effect,grid.stuff.monsterData.isMvp,effectMVP,damage,targetHero,targetPet,grid.stuff.monsterData.monsters,false,x,y)
					end 
				end
			end
		else
			if dungeonDefine:IsStuffType(grid,dungeonDefine.StuffType.Monster,true) then
				if grid.stuff.monsterData.isEnemy then
					DoSputteringHP(self,effect,grid.stuff.monsterData.isMvp,effectMVP,damage,targetHero,targetPet,grid.stuff.monsterData.monsters,false,x,y)
				end 
			end
		end
	end
end

--溅射，现在设计成对附近单位根据配置造成伤害
local function Sputtering(self,effect,effectMVP,baseDamage,targetHero,targetPet,targetX,targetY,isPlayer,x,y)
	--print("====Sputtering===",effect.id,baseDamage,targetHero,targetPet,targetX,targetY,isPlayer,x,y)
	local damagePer = csv.CallCsvData("DungeonEffectCsvData","EffectPara1","EffectPara1FromArray",effect.id,effect.level)
	local damage = baseDamage * damagePer / 1000
	local length = csv.CallCsvData("DungeonEffectCsvData","EffectPara2","EffectPara2FromArray",effect.id,effect.level) / 10
	local sourceGrid 
	if not isPlayer then
		local c = self.dungeonServerData:GetGrid(x,y)
		if dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Monster,true) then
			sourceGrid = c
		end
	end
	if length > 0 then
		self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.DoEffect,{x=targetX,y=targetY,effect=effect,isPlayer=false})
		for i=-length,length do
			if i ~= 0 then
				local newX = targetX-i
				local newY = targetY-i
				DoSputteringGrid(self,effect,effectMVP,sourceGrid,damage,targetHero,targetPet,newX,targetY)
				DoSputteringGrid(self,effect,effectMVP,sourceGrid,damage,targetHero,targetPet,targetX,newY)
			end
		end
	end
end

--伤害治疗通用逻辑
local function DoHP(self,unitDatas,teamDatas,effect,param,targetHero,targetPet,isPlayer,x,y)
	local effectMVP = csv.CallCsvData("DungeonEffectCsvData","EffectMVP","EffectMVPFromArray",effect.id,effect.level) 
	local addEffects = {}
	local sputteringEffects = {}
	if param < 0 then
		addEffects = self:GetDamageAddEffect(isPlayer,x,y)
		sputteringEffects = self:GetSputteringEffects(isPlayer,x,y)
	elseif param > 0 then
		addEffects = self:GetCureAddEffect(isPlayer,x,y)
	end
	local notifyTeam = {}
	for i=1,#unitDatas do
		local unitData = unitDatas[i]
		local notified = false
		for j=1,#notifyTeam do
			local nt = notifyTeam[j]
			if nt.x == unitData.x and nt.y == unitData.y then
				notified = true
				break
			end
		end
		if not notified then
			local nt = {}
			nt.x = unitData.x
			nt.y = unitData.y
			nt.isPlayer = unitData.isPlayer
			nt.effect = effect
			nt.paraInt1 = param
			table.insert(notifyTeam,nt)
			self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.TeamChangeHPStart,nt)
		end
		if effectMVP or not unitData.isMvp then
			ChangeUnitHP(self,unitData.data,param,targetHero,targetPet,unitData.isPlayer,unitData.x,unitData.y)
		end
	end
	for i=1,#notifyTeam do
		local nt = notifyTeam[i]
		local killEffect,hpPer = self:GetKillHPPer(isPlayer,x,y)
		for j=1,#teamDatas do
			local t = teamDatas[j]
			if nt.x == t.x and nt.y == t.y then
				local monsters = t.data
				--斩杀判断
				if killEffect ~= nil then
					local killEffectMVP = csv.CallCsvData("DungeonEffectCsvData","EffectMVP","EffectMVPFromArray",killEffect.id,killEffect.level) 
					if killEffectMVP or not t.isMvp then
						local curHp = 0
						local totalHp = 0
						for k=1,#monsters do
							local m = monsters[k]
							curHp = curHp + m.totalHp
							totalHp = totalHp + 50000
						end
						if curHp/totalHp * 1000 <= hpPer then
							local killParam = -10000
							local killNt = {} 
							killNt.x = nt.x
							killNt.y = nt.y
							killNt.isPlayer = nt.isPlayer
							killNt.effect = killEffect
							killNt.paraInt1 = killParam
							self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.TeamChangeHPStart,killNt)
							for k=1,#monsters do
								local m = monsters[k]
								ChangeUnitHP(self,m,killParam,true,true,t.isPlayer,t.x,t.y)
							end
							self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.TeamChangeHPEnd,killNt)
							self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.DoEffect,{x=t.x,y=t.y,effect=killEffect,isPlayer=isPlayer})
						end
					end
				end
				--受伤或回血添加effect
				if #addEffects > 0 and (effectMVP or not t.isMvp) then
					local addEffectTeams = {}
					addEffectTeams[1] = nt
					for j=1,#addEffects do
						AddEffect(self,addEffects[j],addEffectTeams)
					end
				end	
				--溅射伤害
				if #sputteringEffects > 0 and (effectMVP or not t.isMvp) then
					for j=1,#sputteringEffects do
						Sputtering(self,sputteringEffects[j],effectMVP,param,targetHero,targetPet,t.x,t.y,isPlayer,x,y)
					end
				end
			end
		end
		self.dungeonStep:OnNotifycation(dungeonDefine.NotificationType.TeamChangeHPEnd,nt)
	end
end

local function DirectionHP(self,effect,isPlayer,x,y,addTeamNum)
	local teamDatas = getDirEffectTargetTeamData(self,effect,isPlayer,x,y,addTeamNum)
	local hpType = csv.CallCsvData("DungeonEffectCsvData","EffectPara2","EffectPara2FromArray",effect.id,effect.level)
	local para1 = csv.CallCsvData("DungeonEffectCsvData","EffectPara3","EffectPara3FromArray",effect.id,effect.level)
	local param = 10000 * para1 / 1000
	local targetHero = false
	local targetPet = false
	if hpType == dungeonDefine.HPTargetType.All then
		targetHero = true
		targetPet = true
	elseif hpType == dungeonDefine.HPTargetType.Hero then
		targetHero = true
	elseif hpType == dungeonDefine.HPTargetType.Pet then
		targetPet = true
	end
	local unitDatas = getTargetUnitData(self,effect,teamDatas)
	DoHP(self,unitDatas,teamDatas,effect,param,targetHero,targetPet,isPlayer,x,y)
end

local function HP(self,effect,teamDatas,targetHero,targetPet,isPlayer,x,y)
	local unitDatas = getTargetUnitData(self,effect,teamDatas)
	--print("====HP===",effect.id,isPlayer,x,y)
	--print("====HP teamDatas===",dungeonUtils.PairTabMsg(teamDatas))
	--print("====HP unitDatas===",dungeonUtils.PairTabMsg(unitDatas))
	local para1 = csv.CallCsvData("DungeonEffectCsvData","EffectPara1","EffectPara1FromArray",effect.id,effect.level)
	local param = 10000 * para1 / 1000
	DoHP(self,unitDatas,teamDatas,effect,param,targetHero,targetPet,isPlayer,x,y)
end

local function doEveryBuff(self,effect,buffType,isPlayer,x,y,teamDatas)
	local addTeamNum = self:GetAddTargetNumber(isPlayer,x,y)
	if buffType == dungeonDefine.EffectBuffType.HPAll then
		if teamDatas == nil then
			teamDatas = getTargetTeamData(self,effect,isPlayer,x,y,addTeamNum)
		end
		HP(self,effect,teamDatas,true,true,isPlayer,x,y)
	elseif buffType == dungeonDefine.EffectBuffType.HPHero then
		if teamDatas == nil then
			teamDatas = getTargetTeamData(self,effect,isPlayer,x,y,addTeamNum)
		end
		HP(self,effect,teamDatas,true,false,isPlayer,x,y)
	elseif buffType == dungeonDefine.EffectBuffType.HPPet then
		if teamDatas == nil then
			teamDatas = getTargetTeamData(self,effect,isPlayer,x,y,addTeamNum)
		end
		HP(self,effect,teamDatas,false,true,isPlayer,x,y)
	elseif buffType == dungeonDefine.EffectBuffType.RelieveDebuff then
		RelieveDebuff(self,effect,isPlayer,x,y)
	elseif buffType == dungeonDefine.EffectBuffType.Resurrection then
		if teamDatas == nil then
			teamDatas = getTargetTeamData(self,effect,isPlayer,x,y,addTeamNum)
		end
		Resurrection(self,effect,teamDatas,true,true)
	elseif buffType == dungeonDefine.EffectBuffType.ResurrectionHero then
		if teamDatas == nil then
			teamDatas = getTargetTeamData(self,effect,isPlayer,x,y,addTeamNum)
		end
		Resurrection(self,effect,teamDatas,true,false)
	elseif buffType == dungeonDefine.EffectBuffType.ResurrectionPet then
		if teamDatas == nil then
			teamDatas = getTargetTeamData(self,effect,isPlayer,x,y,addTeamNum)
		end
		Resurrection(self,effect,teamDatas,false,true)
	elseif buffType == dungeonDefine.EffectBuffType.OpenGrid then
		OpenGrid(self,effect)
	elseif buffType == dungeonDefine.EffectBuffType.Stifle then
		Stifle(self,effect)
	elseif buffType == dungeonDefine.EffectBuffType.ClearStifle then
		ClearStifle(self,isPlayer,x,y)
	elseif buffType == dungeonDefine.EffectBuffType.AddEffect then
		if teamDatas == nil then
			teamDatas = getTargetTeamData(self,effect,isPlayer,x,y,addTeamNum)
		end
		AddEffect(self,effect,teamDatas)
	elseif buffType == dungeonDefine.EffectBuffType.AddCacheEffect then
		AddCacheEffect(self,effect,isPlayer,x,y)
	elseif buffType == dungeonDefine.EffectBuffType.GetCacheEffect then
		if teamDatas == nil then
			teamDatas = getTargetTeamData(self,effect,isPlayer,x,y,addTeamNum)
		end
		GetCacheEffect(self,effect,teamDatas)
	elseif buffType == dungeonDefine.EffectBuffType.SwitchAddEffect then
		if teamDatas == nil then
			teamDatas = getTargetTeamData(self,effect,isPlayer,x,y,addTeamNum)
		end
		SwitchAddEffect(self,effect,teamDatas)
	elseif buffType == dungeonDefine.EffectBuffType.DirectionHP then
		DirectionHP(self,effect,isPlayer,x,y,addTeamNum)
	end
end

--执行某个effect得时候添加effect
local function DoEffectAddEffect(self,isPlayer,x,y)
	local effects = getTargetEffects(self,isPlayer,x,y)
	for i=1,#effects do
		local e = effects[i]
		local buffType = dungeonDefine.EffectBuffType[csv.CallCsvData("DungeonEffectCsvData","BuffType","BuffTypeFromArray",e.id,e.level)]
		if buffType == dungeonDefine.EffectBuffType.DoEffectAddEffect then
			local addTeamNum = self:GetAddTargetNumber(isPlayer,x,y)
			local teamDatas = getTargetTeamData(self,e,isPlayer,x,y,addTeamNum)
			AddEffect(self,e,teamDatas)
		end
	end
end

--attacker buff施放者
--target   buff目标
function M.DoEffect(self,effect,isPlayer,x,y)
	effect.totalTriggerCount = effect.totalTriggerCount + 1
	DoEffectAddEffect(self,isPlayer,x,y)
	local buffType = dungeonDefine.EffectBuffType[csv.CallCsvData("DungeonEffectCsvData","BuffType","BuffTypeFromArray",effect.id,effect.level)]
	if buffType ~= nil then
		doEveryBuff(self,effect,buffType,isPlayer,x,y)
	end
end

--attacker buff施放者
--target   buff目标
function M.DoTargetEffect(self,effect,x,y)
	local targetTeamType = dungeonDefine.EffectTargetTeamType[csv.CallCsvData("DungeonEffectCsvData","TargetTeam","TargetTeamFromArray",effect.id,effect.level)]
	local grid = self.dungeonServerData:GetGrid(x,y)
	if dungeonDefine:IsStuffType(grid,dungeonDefine.StuffType.Monster,true) then
		local monsterData = nil
		if (targetTeamType == dungeonDefine.EffectTargetTeamType.TargetAlly and not grid.stuff.monsterData.isEnemy)
		or (targetTeamType == dungeonDefine.EffectTargetTeamType.TargetEnemy and grid.stuff.monsterData.isEnemy) then
			monsterData = grid.stuff.monsterData
		end
		if monsterData ~= nil then
			local teamDatas = {{x=x,y=y,isPlayer=false,isMvp=monsterData.isMvp,data=monsterData.monsters,effects=grid.stuff.effects}}
			local buffType = dungeonDefine.EffectBuffType[csv.CallCsvData("DungeonEffectCsvData","BuffType","BuffTypeFromArray",effect.id,effect.level)]
			doEveryBuff(self,effect,buffType,true,x,y,teamDatas)
		end
	end
end	

--免疫debuff
function M.IsImmuneDebuff(self,isPlayer,x,y)
	local effects = getTargetEffects(self,isPlayer,x,y)
	for i=1,#effects do
		local e = effects[i]
		local buffType = dungeonDefine.EffectBuffType[csv.CallCsvData("DungeonEffectCsvData","BuffType","BuffTypeFromArray",e.id,e.level)]
		if buffType == dungeonDefine.EffectBuffType.ImmuneDebuff then
			return true
		end
	end
	return false
end		

--封印非战斗effect
function M.IsSealPassiveness(self,isPlayer,x,y)
	local effects = getTargetEffects(self,isPlayer,x,y)
	for i=1,#effects do
		local e = effects[i]
		local buffType = dungeonDefine.EffectBuffType[csv.CallCsvData("DungeonEffectCsvData","BuffType","BuffTypeFromArray",e.id,e.level)]
		if buffType == dungeonDefine.EffectBuffType.SealPassiveness then
			return true
		end
	end
	return false
end

--封印背包
function M.IsSealItem(self)
	local effects = self.dungeonServerData.effectList
	for i=1,#effects do
		local e = effects[i]
		local buffType = dungeonDefine.EffectBuffType[csv.CallCsvData("DungeonEffectCsvData","BuffType","BuffTypeFromArray",e.id,e.level)]
		if buffType == dungeonDefine.EffectBuffType.SealAllItem then
			return true
		end
	end
	return false
end

--增加或减少effect目标数量
function M.GetAddTargetNumber(self,isPlayer,x,y)
	local addTeamNum = 0
	local effects = getTargetEffects(self,isPlayer,x,y)
	for i=1,#effects do
		local e = effects[i]
		local buffType = dungeonDefine.EffectBuffType[csv.CallCsvData("DungeonEffectCsvData","BuffType","BuffTypeFromArray",e.id,e.level)]
		if buffType == dungeonDefine.EffectBuffType.TargetNumber then
			addTeamNum = addTeamNum + csv.CallCsvData("DungeonEffectCsvData","EffectPara1","EffectPara1FromArray",e.id,e.level)
		end
	end
	return addTeamNum
end	

--effect造成伤害时加effect
function M.GetDamageAddEffect(self,isPlayer,x,y)
	local addEffects = {}
	local effects = getTargetEffects(self,isPlayer,x,y)
	for i=1,#effects do
		local e = effects[i]
		local buffType = dungeonDefine.EffectBuffType[csv.CallCsvData("DungeonEffectCsvData","BuffType","BuffTypeFromArray",e.id,e.level)]
		if buffType == dungeonDefine.EffectBuffType.DamageAddEffect then
			table.insert(addEffects,e)
		end
	end
	return addEffects
end	

--effect造成伤害时加effect
function M.GetCureAddEffect(self,isPlayer,x,y)
	local addEffects = {}
	local effects = getTargetEffects(self,isPlayer,x,y)
	for i=1,#effects do
		local e = effects[i]
		local buffType = dungeonDefine.EffectBuffType[csv.CallCsvData("DungeonEffectCsvData","BuffType","BuffTypeFromArray",e.id,e.level)]
		if buffType == dungeonDefine.EffectBuffType.CureAddEffect then
			table.insert(addEffects,e)
		end
	end
	return addEffects
end	

--effect造成伤害时获取斩杀effect
function M.GetKillHPPer(self,isPlayer,x,y)
	local hpPer = 0
	local effect
	local addEffects = {}
	local effects = getTargetEffects(self,isPlayer,x,y)
	for i=1,#effects do
		local e = effects[i]
		local buffType = dungeonDefine.EffectBuffType[csv.CallCsvData("DungeonEffectCsvData","BuffType","BuffTypeFromArray",e.id,e.level)]
		if buffType == dungeonDefine.EffectBuffType.KillHPBelowPer then
			local param = csv.CallCsvData("DungeonEffectCsvData","EffectPara1","EffectPara1FromArray",e.id,e.level)
			if hpPer < param then
				hpPer = param
				effect = e
			end
		end
	end
	return effect,hpPer
end	

--effect造成伤害时获取溅射effect
function M.GetSputteringEffects(self,isPlayer,x,y)
	local sputteringEffects = {}
	local effect
	local addEffects = {}
	local effects = getTargetEffects(self,isPlayer,x,y)
	for i=1,#effects do
		local e = effects[i]
		local buffType = dungeonDefine.EffectBuffType[csv.CallCsvData("DungeonEffectCsvData","BuffType","BuffTypeFromArray",e.id,e.level)]
		if buffType == dungeonDefine.EffectBuffType.Sputtering then
			table.insert(sputteringEffects,e)
		end
	end
	return sputteringEffects
end	

function M.Clear(self)
	
end

function M.Init(self,data)
	self.dungeonServerData = data
	self.dungeonLogic = data.dungeonLogic
	self.dungeonStep = data.dungeonLogic.dungeonStep
end

function M.Dispose(self)
	
end

function M.new()
    local t = {
    }
    return setmetatable(t, {__index = M})
end


  
return M  
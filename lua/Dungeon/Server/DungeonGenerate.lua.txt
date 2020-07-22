local M = {}
local dungeonUtils = require("Dungeon.DungeonUtils")
local csv = require("Dungeon.LuaCallCsvData")
local autoDungeon = require("Dungeon.Server.DungeonAutoGenerate")
local manualDungeon = require("Dungeon.Server.DungeonManualGenerate")
local dungeonDefine = require("Dungeon.DungeonDefine")
local dungeonStruct = require("Dungeon.DungeonStruct")

local function getMonsterPosition(self,leftPosition,pos)
	local removed = false
	if pos ~= nil then
		for i=1,#leftPosition do
			if leftPosition[i] == pos then
				table.remove(leftPosition,i)
				removed = true
				break
			end
		end
	end
	if not removed then
		local rPos = math.random(1,#leftPosition)
		pos = leftPosition[rPos]
		table.remove(leftPosition,rPos)
	end
	return pos
end

local function createEventData(self,stuff,isMapCreate)
	local id = stuff.id
	local effects = {}
	local buffType = dungeonDefine.EventType[csv.CallCsvData("DungeonEventCsvData","EventType","EventType",id)] 
	if buffType == dungeonDefine.EventType.DoctorOwl then
		--猫头鹰博士事件
		local eventLib = csv.CallCsvData("DungeonEventCsvData","EventPara1","EventPara1FromArray",id,1)
		local effectLib = csv.CallCsvData("DungeonEventCsvData","EventPara2","EventPara2FromArray",id,1)
		local overlay = csv.CallCsvData("DungeonEventCsvData","EventPara3","EventPara3FromArray",id,1)
		--随问题事件
		local weights = csv.CallCsvData("DungeonLibCsvData","Weight","WeightArray",eventLib)
		local randomIds = csv.CallCsvData("DungeonLibCsvData","Reward","RewardArray",eventLib)
		local randomNum = csv.CallCsvData("DungeonLibCsvData","LibSecond","LibSecond",eventLib)
		local ids = {}
		if randomNum == #randomIds then
			ids = randomIds
		else
			while(randomNum > 0 and #randomIds > 0) do
				local id,randomIds,weights = dungeonUtils.commonRandom(randomIds,weights)
				table.insert(ids,id)
				randomNum = randomNum - 1
			end
		end
		--随出effect
		weights = csv.CallCsvData("DungeonLibCsvData","Weight","WeightArray",effectLib)
		randomIds = csv.CallCsvData("DungeonLibCsvData","Reward","RewardArray",effectLib)
		randomNum = csv.CallCsvData("DungeonLibCsvData","LibSecond","LibSecond",effectLib)
		local effectIndex = 0
		while(randomNum > 0 and #randomIds > 0) do
			local id,randomIds,weights = dungeonUtils.commonRandom(randomIds,weights)
			effectIndex = effectIndex + 1
			table.insert(effects,dungeonStruct.CreatEffect(id,effectIndex,1,overlay))
			randomNum = randomNum - 1
		end
		stuff.eventData = dungeonStruct.CreatEventData(ids,dungeonUtils.copyTable(effects))
		stuff.effects = effects
	end
	return stuff
end

--见DungeonStruct monsterData
local function createMonsterData(self,monsterId,index,isMapCreate)
	local generateId = 0
	--布阵上剩余的位置
	local leftPosition = {}
	for i=0,14 do
		table.insert(leftPosition,i)
	end
	local monsterNumber = 0
	local monsterLevel = 0
	local monsterStar = 0
	local monsterHpRate = 0
	local monsterAttackRate = 0
	local scrollStar = 0
	local scrollHpRate = 0
	local scrollAttackRate = 0
	if self.generateType == dungeonDefine.DungeonGenerateType.Auto then
		monsterNumber = csv.CallCsvData("DungeonAutoGenerateCsvData","AutoEnemyMonsterNum","AutoEnemyMonsterNumFromArray",self.dungeonId,index)
		monsterLevel = csv.CallCsvData("DungeonAutoGenerateCsvData","MonsterAttrLevel","MonsterAttrLevelFromArray",self.dungeonId,index)
		monsterStar = csv.CallCsvData("DungeonAutoGenerateCsvData","MonsterStar","MonsterStarFromArray",self.dungeonId,index)
		monsterHpRate = csv.CallCsvData("DungeonAutoGenerateCsvData","MonsterHpRate","MonsterHpRateFromArray",self.dungeonId,index)
		monsterAttackRate = csv.CallCsvData("DungeonAutoGenerateCsvData","MonsterAttackRate","MonsterAttackRateFromArray",self.dungeonId,index)
		scrollStar = csv.CallCsvData("DungeonAutoGenerateCsvData","ScrollStar","ScrollStarFromArray",self.dungeonId,index)
		scrollHpRate = csv.CallCsvData("DungeonAutoGenerateCsvData","ScrollHpRate","ScrollHpRateFromArray",self.dungeonId,index)
		scrollAttackRate = csv.CallCsvData("DungeonAutoGenerateCsvData","ScrollAttackRate","ScrollAttackRateFromArray",self.dungeonId,index)
	elseif self.generateType == dungeonDefine.DungeonGenerateType.Manual then
		monsterNumber = csv.CallCsvData("DungeonManualGenerateCsvData","ManualEnemyMonsterNum","ManualEnemyMonsterNumFromArray",self.dungeonId,index)
		monsterLevel = csv.CallCsvData("DungeonManualGenerateCsvData","MonsterAttrLevel","MonsterAttrLevelFromArray",self.dungeonId,index)
		monsterStar = csv.CallCsvData("DungeonManualGenerateCsvData","MonsterStar","MonsterStarFromArray",self.dungeonId,index)
		monsterHpRate = csv.CallCsvData("DungeonManualGenerateCsvData","MonsterHpRate","MonsterHpRateFromArray",self.dungeonId,index)
		monsterAttackRate = csv.CallCsvData("DungeonManualGenerateCsvData","MonsterAttackRate","MonsterAttackRateFromArray",self.dungeonId,index)
		scrollStar = csv.CallCsvData("DungeonManualGenerateCsvData","ScrollStar","ScrollStarFromArray",self.dungeonId,index)
		scrollHpRate = csv.CallCsvData("DungeonManualGenerateCsvData","ScrollHpRate","ScrollHpRateFromArray",self.dungeonId,index)
		scrollAttackRate = csv.CallCsvData("DungeonManualGenerateCsvData","ScrollAttackRate","ScrollAttackRateFromArray",self.dungeonId,index)
	end
	--随机形象
	local sprites = csv.CallCsvData("DungeonMonsterCsvData","MonsterSprite","MonsterSpriteArray",monsterId)
	local spriteWeights = csv.CallCsvData("DungeonMonsterCsvData","MonsterSpriteWeight","MonsterSpriteWeightArray",monsterId)
	local a,b,c,exhibitIndex = dungeonUtils.commonRandom(sprites,spriteWeights)
	--MVP
	local isMvp = false
	if isMapCreate and self.generateType == dungeonDefine.DungeonGenerateType.Manual then
		if csv.CallCsvData("DungeonManualGenerateCsvData","ManualEnemyMVP","ManualEnemyMVPFromArray",self.dungeonId,index) then
			isMvp = true
		end
	end
	--钥匙
	local isKeyMonster = self.keyMonsterIndexs[index] ~= nil
	local data = dungeonStruct.CreatMonsterData(monsterId,true,exhibitIndex,isMvp,isKeyMonster)
	--根据数量随机怪物，优先获取精英怪
	local eliteMonsterIds = csv.CallCsvData("DungeonMonsterCsvData","EliteMonsterId","EliteMonsterIdArray",monsterId)
	if monsterNumber > 0 then
		for i=1,#eliteMonsterIds do
			if eliteMonsterIds[i] > 0 then
				generateId = generateId + 1
				monsterNumber = monsterNumber - 1
				local monster = {}
				monster.id = csv.CallCsvData("DungeonMonsterCsvData","EliteDisplayHeroId","EliteDisplayHeroIdFromArray",monsterId,i)
				monster.eliteId = eliteMonsterIds[i]
				monster.generateId = generateId
				monster.level = csv.CallCsvData("DungeonMonsterCsvData","EliteMonsterLv","EliteMonsterLvFromArray",monsterId,i)
				monster.star = 1
				monster.position = getMonsterPosition(self,leftPosition,csv.CallCsvData("DungeonMonsterCsvData","EliteMonsterStation","EliteMonsterStationFromArray",monsterId,i))
				monster.hpRate = 0
				monster.attackRate = 0
				monster.scrollId = 0
				monster.scrollStar = 0
				monster.scrollHpRate = 0
				monster.scrollAttackRate = 0
				monster.HeroHp = 10000
				monster.PetHp = {0,0,0,0}
				monster.totalHp = 10000
				table.insert(data.monsters,monster)
				if monsterNumber == 0 then
					break
				end
			end
		end
	end
	--其次固定怪
	if monsterNumber > 0 then
		local fixedMonsterIds = csv.CallCsvData("DungeonMonsterCsvData","FixedMonsterId","FixedMonsterIdArray",monsterId)
		for i=1,#fixedMonsterIds do
			if fixedMonsterIds[i] > 0 then
				generateId = generateId + 1
				monsterNumber = monsterNumber - 1
				local monster = {}
				monster.id = fixedMonsterIds[i]
				monster.generateId = generateId
				monster.eliteId = 0
				monster.level = monsterLevel
				monster.star = monsterStar
				monster.position = getMonsterPosition(self,leftPosition,csv.CallCsvData("DungeonMonsterCsvData","Station","StationFromArray",monsterId,i))
				monster.hpRate = monsterHpRate
				monster.attackRate = monsterAttackRate
				monster.scrollId = csv.CallCsvData("DungeonMonsterCsvData","FixedScrollId","FixedScrollIdFromArray",monsterId,i)
				monster.scrollStar = scrollStar
				monster.scrollHpRate = scrollHpRate
				monster.scrollAttackRate = scrollAttackRate
				monster.HeroHp = 10000
				monster.PetHp = {10000,10000,10000,10000}
				monster.totalHp = 50000
				table.insert(data.monsters,monster)
				if monsterNumber == 0 then
					break
				end
			end
		end
	end
	--最后随机怪
	if monsterNumber > 0 then
		local randomMonsterIds = csv.CallCsvData("DungeonMonsterCsvData","RandomMonsterId","RandomMonsterIdArray",monsterId)
		local randomMonsterWeights = csv.CallCsvData("DungeonMonsterCsvData","RandomMonsterWeight","RandomMonsterWeightArray",monsterId)
		local randomScrollIds = csv.CallCsvData("DungeonMonsterCsvData","RandomScrollId","RandomScrollIdArray",monsterId)
		local randomScrollIdWeights = csv.CallCsvData("DungeonMonsterCsvData","RandomScrollWeight","RandomScrollWeightArray",monsterId)
		local tRandomMonsters = {}
		local tScrolls = {}
		for i=1,#randomMonsterIds do
			local monster = {}
			monster.id = randomMonsterIds[i]
			table.insert(tRandomMonsters,monster)
		end
		while(monsterNumber > 0 and #randomMonsterWeights > 0) do
			local monster,tRandomMonsters,randomMonsterWeights = dungeonUtils.commonRandom(tRandomMonsters,randomMonsterWeights)
			generateId = generateId + 1
			monsterNumber = monsterNumber-1
			monster.eliteId = 0
			monster.generateId = generateId
			monster.level = monsterLevel
			monster.star = monsterStar
			monster.position = getMonsterPosition(self,leftPosition,nil)
			monster.hpRate = monsterHpRate
			monster.attackRate = monsterAttackRate
			--随机scroll
			monster.scrollId,tScrolls,randomScrollIdWeights = dungeonUtils.commonRandom(randomScrollIds,randomScrollIdWeights)
			monster.scrollStar = scrollStar
			monster.scrollHpRate = scrollHpRate
			monster.scrollAttackRate = scrollAttackRate
			monster.HeroHp = 10000
			monster.PetHp = {10000,10000,10000,10000}
			monster.totalHp = 50000
			table.insert(data.monsters,monster)
		end
	end
	return data
end

--见DungeonStruct stuff
function M.GetStuffsFromLibId(self,libId,index,isMapCreate)
	local stuffs = {}
	if libId ~= 0 then
		local weights = csv.CallCsvData("DungeonLibCsvData","Weight","WeightArray",libId)
		local ids = csv.CallCsvData("DungeonLibCsvData","Reward","RewardArray",libId)
		local types = csv.CallCsvData("DungeonLibCsvData","LibType","LibTypeArray",libId)
		local follows = csv.CallCsvData("DungeonLibCsvData","Follow","FollowArray",libId)
		local followRates = csv.CallCsvData("DungeonLibCsvData","FollowRate","FollowRateArray",libId)
		local stuffNums = csv.CallCsvData("DungeonLibCsvData","LibNum","LibNumArray",libId)
		local randomNum = csv.CallCsvData("DungeonLibCsvData","LibSecond","LibSecond",libId)
		--先将id放入table，因为之后要把随机到了的移除
		local tStuffs = {}
		for i=1,#weights do
			local rNum = math.random(0,10000)
			local followId = 0
			if rNum <= followRates[i] then
				followId = follows[i]
			end
			table.insert(tStuffs,dungeonStruct.CreatStuff(ids[i],stuffNums[i],index,followId,dungeonDefine.StuffType[types[i]]))
		end
		while(randomNum > 0 and #tStuffs > 0) do
			local stuff,tStuffs,weights = dungeonUtils.commonRandom(tStuffs,weights)
			table.insert(stuffs,stuff)
			if stuff.stuffType == dungeonDefine.StuffType.Monster then
				stuff.monsterData = createMonsterData(self,stuff.id,stuff.index,isMapCreate)
				--怪物额外能力
				if isMapCreate then
					local effectLib
					if self.generateType == dungeonDefine.DungeonGenerateType.Auto then
						effectLib = csv.CallCsvData("DungeonAutoGenerateCsvData","AutoEnemySpecialEffectLib","AutoEnemySpecialEffectLibFromArray",self.dungeonId,index)
					elseif self.generateType == dungeonDefine.DungeonGenerateType.Manual then
						effectLib = csv.CallCsvData("DungeonManualGenerateCsvData","ManualEnemySpecialEffectLib","ManualEnemySpecialEffectLibFromArray",self.dungeonId,index)
					end
					if effectLib ~= nil and effectLib > 0 then
						local effectStuffs = self:GetStuffsFromLibId(effectLib,index)
						for i=1,#effectStuffs do
							table.insert(stuff.effects,dungeonStruct.CreatEffect(effectStuffs[i].id,i))
						end
					end
				end
			elseif stuff.stuffType == dungeonDefine.StuffType.Event then
				stuff = createEventData(self,stuff,isMapCreate)
				--事件固定effect
				local effectIds = csv.CallCsvData("DungeonEventCsvData","TargetEffect","TargetEffectArray",stuff.id)
				if #effectIds > 0 then
					local lastEffect = stuff.effects[#stuff.effects]
					local index = 0
					if lastEffect ~= nil then
						index = lastEffect.index
					end
					for i=1,#effectIds do
						table.insert(stuff.effects,dungeonStruct.CreatEffect(effectIds[i],index+i))
					end
				end
			end
			randomNum = randomNum-1
		end
	end
	return stuffs
end

--创建格子类,见DungeonStruct grid
local function createGridClass(self,gridType,libId,index)
	local c = dungeonStruct.CreatGrid(gridType)
	if c.gridType == dungeonDefine.MazeGridType.Stuff then
		local stuffs = self:GetStuffsFromLibId(libId,index,true)
		c.stuff = stuffs[1]
		if c.stuff.stuffType == dungeonDefine.StuffType.Event then
			if csv.CallCsvData("DungeonEventCsvData","EventOpen","EventOpen",c.stuff.id) then
				c.isOpen = true
				c.isMist = false
			end
		end
	elseif c.gridType == dungeonDefine.MazeGridType.Entrance then
		c.isMist = false
	end
	return c
end

local function createGameMaze(self,maze,enemyNum)
	local enemyIndex = 0
	local eventIndex = 0
	local itemIndex = 0
	self.keyMonsterIndexs = {}
	if self.generateType == dungeonDefine.DungeonGenerateType.Auto then
		local keyIndex = math.random(1,enemyNum)
		self.keyMonsterIndexs[keyIndex] = true
	elseif self.generateType == dungeonDefine.DungeonGenerateType.Manual then
		local manualKeyInfoArray = csv.CallCsvData("DungeonManualGenerateCsvData","ManualKeyInfo","ManualKeyInfoArray",self.dungeonId)
		for i=1,#manualKeyInfoArray do
			if manualKeyInfoArray[i] == 1 then
				self.keyMonsterIndexs[i] = true
			end
		end
	end
	for i=1,#maze do
		for j=1,#maze[i] do
			local obj = nil
			local gridStr = maze[i][j]
			if gridStr == "N" then
				obj = createGridClass(self,dungeonDefine.MazeGridType.None)
			elseif gridStr == "I" then
				obj = createGridClass(self,dungeonDefine.MazeGridType.Entrance)
			elseif gridStr == "O" then
				obj = createGridClass(self,dungeonDefine.MazeGridType.Exit)
			elseif gridStr == "M" then
				enemyIndex = enemyIndex + 1
				local libId
				if self.generateType == dungeonDefine.DungeonGenerateType.Auto then
					libId = csv.CallCsvData("DungeonAutoGenerateCsvData","AutoMonsterLib","AutoMonsterLibFromArray",self.dungeonId,enemyIndex)
				elseif self.generateType == dungeonDefine.DungeonGenerateType.Manual then
					libId = csv.CallCsvData("DungeonManualGenerateCsvData","ManualEnemyMonsterLib","ManualEnemyMonsterLibFromArray",self.dungeonId,enemyIndex)
				end
				obj = createGridClass(self,dungeonDefine.MazeGridType.Stuff,libId,enemyIndex)
			elseif gridStr == "E" then
				eventIndex = eventIndex + 1
				local libId
				if self.generateType == dungeonDefine.DungeonGenerateType.Auto then
					libId = csv.CallCsvData("DungeonAutoGenerateCsvData","AutoEventLib","AutoEventLibFromArray",self.dungeonId,eventIndex)
				elseif self.generateType == dungeonDefine.DungeonGenerateType.Manual then
					libId = csv.CallCsvData("DungeonManualGenerateCsvData","ManualEventLib","ManualEventLibFromArray",self.dungeonId,eventIndex)
				end
				obj = createGridClass(self,dungeonDefine.MazeGridType.Stuff,libId,eventIndex)
			elseif gridStr == "G" then
				itemIndex = itemIndex + 1
				local libId
				if self.generateType == dungeonDefine.DungeonGenerateType.Auto then
					libId = csv.CallCsvData("DungeonAutoGenerateCsvData","AutoItemLib","AutoItemLibFromArray",self.dungeonId,itemIndex)
				elseif self.generateType == dungeonDefine.DungeonGenerateType.Manual then
					libId = csv.CallCsvData("DungeonManualGenerateCsvData","ManualItemLib","ManualItemLibFromArray",self.dungeonId,itemIndex)
				end
				obj = createGridClass(self,dungeonDefine.MazeGridType.Stuff,libId,itemIndex)
			elseif gridStr == "B" then
				obj = createGridClass(self,dungeonDefine.MazeGridType.Block)
			end
			maze[i][j] = obj
		end
	end
	--默认打开格子
	if self.generateType == dungeonDefine.DungeonGenerateType.Auto then
		local autoOpenNum = csv.CallCsvData("DungeonAutoGenerateCsvData","AutoDefaultOpen","AutoDefaultOpen",self.dungeonId)
		local randomCount = #maze * #maze
		while(autoOpenNum > 0 and randomCount > 0) do
			randomCount = randomCount - 1
			local rx = math.random(1,#maze)
			local ry = math.random(1,#maze)
			local c = maze[i][j]
			if c.gridType ~= dungeonDefine.MazeGridType.Entrance and not c.isOpen then
				c.isOpen = true
				c.isMist = false
				autoOpenNum = autoOpenNum - 1
			end
		end
	elseif self.generateType == dungeonDefine.DungeonGenerateType.Manual then
		local manualOpenArray = csv.CallCsvData("DungeonManualGenerateCsvData","ManualDefaultOpenInfo","ManualDefaultOpenInfoArray",self.dungeonId)
		for i=1,#manualOpenArray do
			for j=1,#manualOpenArray[i] do
				if manualOpenArray[i][j] == "T" then
					c = maze[i][j]
					if c.gridType ~= dungeonDefine.MazeGridType.Entrance then
						c.isOpen = true
						c.isMist = false
					end
				end
			end
		end
	end
	return maze
end

--如果有无限的事件就去替换一个砖块位置，以免迷宫卡死
local function ExchangeInfiniteEventToBlock(self,maze)
	local blocks = {}
	local infiniteEvent = {}
	local length = #maze
	for i=1,length do
		for j=1,length do
			local c = maze[i][j]
			if dungeonDefine:IsStuffType(c,dungeonDefine.StuffType.Event) then
				if c.stuff.number == -1 then
					local pos = {}
					pos.x = i
					pos.y = j
					table.insert(infiniteEvent,pos)
				end
			elseif c.gridType == dungeonDefine.MazeGridType.Block then
				local pos = {}
				pos.x = i
				pos.y = j
				table.insert(blocks,pos)
			end
		end
	end
	while(#infiniteEvent > 0 and #blocks > 0) do	
		local rNum = math.random(1,#blocks)
		local pos = infiniteEvent[1]
		local pos1 = blocks[rNum]
		local c = maze[pos.x][pos.y]
		local c1 = maze[pos1.x][pos1.y]
		maze[pos1.x][pos1.y] = c
		maze[pos.x][pos.y] = c1
		c1.gridType = dungeonDefine.MazeGridType.None
		table.remove(infiniteEvent,1)
		table.remove(blocks,rNum)
	end
end

--随机物品和事件数量
local function randomAutoItemAndEventNum(self)
	--item
	local numStr = csv.CallCsvData("DungeonAutoGenerateCsvData","AutoItemNum","AutoItemNum",self.dungeonId)
	local numArray = dungeonUtils.split(numStr,"#")
	local itemNum =  math.random(tonumber(numArray[1]),tonumber(numArray[2]))

	--event
	numStr = csv.CallCsvData("DungeonAutoGenerateCsvData","AutoEventNum","AutoEventNum",self.dungeonId)
	numArray = dungeonUtils.split(numStr,"#")
	local eventNum =  math.random(tonumber(numArray[1]),tonumber(numArray[2]))
	return itemNum,eventNum
end

--传入三种类型权重通用随机item、event、effect
function M.RandomItemOrEventOrEffect(itemWeight,eventWeight,effectWeight)
    local retType = dungeonDefine.RandomTyoe.None
    local randomNum = math.random(1,1000)
    if randomNum <= itemWeight then
        retType = dungeonDefine.RandomTyoe.Item
    elseif randomNum <= itemWeight + eventWeight then
        retType = dungeonDefine.RandomTyoe.Event
    elseif randomNum <= itemWeight + eventWeight + effectWeight then
        retType = dungeonDefine.RandomTyoe.Effect
    end
    return retType
end

function M.Create(self,mapId)
	self.dungeonId = csv.CallCsvData("DungeonMapCsvData","AutoGenerateTemplate","AutoGenerateTemplate",mapId)
    self.generateType = dungeonDefine.DungeonGenerateType.Auto
    if self.dungeonId == 0 then
        self.dungeonId = csv.CallCsvData("DungeonMapCsvData","ManualGenerateTemplate","ManualGenerateTemplate",mapId)
        self.generateType = dungeonDefine.DungeonGenerateType.Manual
    end
	local maze = nil
	local enemyNum = 0
	local itemNum = 0
	local eventNum = 0
	if self.generateType == dungeonDefine.DungeonGenerateType.Auto then
		enemyNum = #csv.CallCsvData("DungeonAutoGenerateCsvData","AutoMonsterLib","AutoMonsterLibArray",self.dungeonId)
		itemNum,eventNum = randomAutoItemAndEventNum(self)
		maze = autoDungeon.Create(self.dungeonId,enemyNum,itemNum,eventNum)
	elseif self.generateType == dungeonDefine.DungeonGenerateType.Manual then
		enemyNum = #csv.CallCsvData("DungeonManualGenerateCsvData","ManualEnemyMonsterLib","ManualEnemyMonsterLibArray",self.dungeonId)
		maze = manualDungeon.Create(self.dungeonId)
	end
    maze = createGameMaze(self,maze,enemyNum)
    if self.generateType == dungeonDefine.DungeonGenerateType.Auto then
    	--自动生成的迷宫要避免死路
    	ExchangeInfiniteEventToBlock(self,maze)
    end
    local keyNumber = 0
    for k,v in pairs(self.keyMonsterIndexs) do
    	keyNumber = keyNumber + 1
    end
    self.keyMonsterIndexs = {}
	return maze,keyNumber
end

function M.CreateWorld(self,mapId)
	--math.randomseed(tostring(os.time()):reverse():sub(1, 7))
	if mapId > 0 then
		self.dungeonId = csv.CallCsvData("DungeonMapCsvData","AutoGenerateTemplate","AutoGenerateTemplate",mapId)
	    self.generateType = dungeonDefine.DungeonGenerateType.Auto
	    if self.dungeonId == 0 then
	        self.dungeonId = csv.CallCsvData("DungeonMapCsvData","ManualGenerateTemplate","ManualGenerateTemplate",mapId)
	        self.generateType = dungeonDefine.DungeonGenerateType.Manual
	    end
	end
end

function M.new()
    local t = {
    	dungeonId = 0,
    	generateType = 0,
		keyMonsterIndexs = {},
    }
    return setmetatable(t, {__index = M})
end

return M
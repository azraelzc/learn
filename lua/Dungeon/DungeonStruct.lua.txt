local dungeonDefine = require("Dungeon.DungeonDefine")
local csv = require("Dungeon.LuaCallCsvData")

--所有迷宫里结构体
local M = {}

local function ListToTable(list)
    local t = nil
    if list ~= nil then
        t = {}
        for i=0,list.Count-1 do
            t[i+1]=list[i]
        end
    end
    return t
end

local function toAdventurerSquad(squad)
    local t
    if squad ~= nil then
        t = {}
        t.id = squad.id
        t.level = squad.level   
        t.isActive = squad.isActive       
        t.comprehands = ListToTable(squad.comprehands)
    end
    return t    
end

local function toAdventurerSquads(squads)
    local t 
    if squads ~= nil then
        t = {}
        for i=0,squads.Count-1 do
            table.insert(t,toAdventurerSquad(squads[i]))
        end
    end
    
    return t    
end

local function toMonster(sm)
    local tm = nil
    if sm ~= nil then
        tm = {}
        tm.id  = sm.id
        tm.generateId = sm.generateId
        tm.eliteId = sm.eliteId
        tm.level = sm.level
        tm.star = sm.star
        tm.position = sm.position
        tm.hpRate = sm.hpRate
        tm.attackRate = sm.attackRate
        tm.scrollId = sm.scrollId
        tm.scrollStar = sm.scrollStar
        tm.scrollHpRate = sm.scrollHpRate
        tm.scrollAttackRate = sm.scrollAttackRate
        tm.HeroHp = sm.HeroHp
        tm.PetHp = ListToTable(sm.PetHp)
        tm.totalHp = sm.totalHp
    end
    return tm
end

local function toMonsters(monsters)
    local ret = nil
    if monsters ~= nil then
        ret = {}
        for i=0,monsters.Count-1 do
            table.insert(ret,toMonster(monsters[i]))
        end
    end
    return ret
end

local function toStuff(stuff)
    local newStuff = nil 
    if stuff ~= nil then
        newStuff = {}
        newStuff.id = stuff.id
        newStuff.number = stuff.number
        newStuff.index = stuff.index
        newStuff.followId = stuff.followId
        newStuff.stuffType = stuff.stuffType
        newStuff.effects = ListToTable(stuff.effects)
        if stuff.monsterData ~= nil then
            newStuff.monsterData = {}
            newStuff.monsterData.id = stuff.monsterData.id
            newStuff.monsterData.isEnemy = stuff.monsterData.isEnemy
            newStuff.monsterData.exhibitIndex = stuff.monsterData.exhibitIndex
            newStuff.monsterData.isMvp = stuff.monsterData.isMvp
            newStuff.monsterData.isKeyMonster = stuff.monsterData.isKeyMonster
            newStuff.monsterData.monsters = toMonsters(stuff.monsterData.monsters)
        end
        if stuff.eventData ~= nil then
            newStuff.eventData = {}
            newStuff.eventData.choiceDatas = ListToTable(stuff.eventData.choiceDatas)
            newStuff.eventData.questionIndex = stuff.eventData.questionIndex
            newStuff.eventData.effects = ListToTable(stuff.eventData.effects)
        end
    end
    return newStuff
end

local function toGridClass(grid)
    local c = nil
    if grid ~= nil then
        c = {}
        c.gridType = grid.gridType
        c.isOpen = grid.isOpen
        c.isBan = grid.isBan
        c.isMist = grid.isMist
        c.stuff = toStuff(grid.stuff)
    end
    return c
end

local function mazeListToTable(mazeList)
    local maze = nil
    if mazeList ~= nil then
        maze = {}
        for i=0,mazeList.Count-1 do
            maze[i+1] = {}
            local list = mazeList[i].list
            for j=0,list.Count-1 do
                maze[i+1][j+1]=toGridClass(list[j])
            end
        end
    end
    return maze
end

----坐标点 
--[[
Point ={
    x   int
    y   int 
} 
]]
function M.CreatPoint(x,y)  
    local t= {}  
    t.x = x
    t.y = y
    return t  
end 

----迷宫格子 
--[[
Grid = {
    gridType    int     dungeonDefine.MazeGridType
    isOpen      bool    是否被翻开
    isBan       bool    是否被禁止打开
    isMist      bool    是否有迷雾
    ---------------------------------------------
    stuff= {            Stuff如果格子上有东西则有stuff,为了方便看结构直接放这里
        id              int
        number          int
        index           int     读取迷宫表的下标,物品表开出物品时候下表都是0
        followId        int     完成后的奖励libid
        stuffType       int     DungeonDefine.stuffType
        effects         Effect* effect放格子上，删除怪物身上    
    ------------------------------------------------    
        monsterData = {     MonsterData，如果是怪物类型要有怪物数据,为了方便看结构直接放这里
            id              int     dungeonMonster表的id
            isEnemy         bool    是否是敌人 
            exhibitIndex     int     形象随机下标
            monsters = {    Monster,战斗里的monster数据,为了方便看结构直接放这里
                id                  int     hero表id
                generateId          int     自己队伍中的唯一id
                eliteId             int     精英怪id
                level               int
                star                int
                position            int     怪物布阵中的位置
                hpRate              int
                attackRate          int
                scrollId            int
                scrollStar          int
                scrollHpRate        int
                scrollAttackRate    int
                HeroHp              int     血量万分比
                PetHp,              int*    {10000,10000,10000,10000}  --宠物血量万分比定死4个
                totalHp,            int     魔物和随从加起来，总血量为50000
            },
            isMvp                   bool    如果迷宫初始生成的怪可能是MVP
            isKeyMonster            bool    如果迷宫初始生成的怪可能会掉落钥匙
        }   
    }
}
]]
function M.CreatGrid(gridType)  
    local t={}  
    t.gridType = gridType
    t.isOpen = false
    t.isBan = false
    t.isMist = true
    return t  
end  

----格子上的东西  
--[[
Stuff= {           
    id          int
    number      int
    index       int             读取迷宫表的下标,物品表开出物品时候下表都是0
    followId    int             完成后的奖励libid
    stuffType   int             DungeonDefine.stuffType
    effects     Effect*  		effect放格子上
    monsterData MonsterData     如果是monster类型会有monster Data数据
    eventData   EventData       如果是event类型会有event Data
}
]]
function M.CreatStuff(id,number,index,followId,stuffType)  
    local t={}  
    t.id = id
    t.number = number
    t.index = index
    t.stuffType = stuffType
    t.followId = followId
    t.effects = {}
    return t  
end  

----格子上的怪物数据 
--[[
monsterData = {     MonsterData，如果是怪物类型要有怪物数据,为了方便看结构直接放这里
    id              int         dungeonMonster表的id
    isEnemy         bool        是否是敌人 
    exhibitIndex    int         形象随机下标
    monsters        Monster*   
    isMvp           bool        如果迷宫初始生成的怪可能是MVP
    isKeyMonster    bool        如果迷宫初始生成的怪可能会掉落钥匙
}   
]]
function M.CreatMonsterData(id,isEnemy,exhibitIndex,isMvp,isKeyMonster)  
    local t={}  
    t.id = id
    t.isEnemy = isEnemy
    t.exhibitIndex = exhibitIndex
    t.isMvp = isMvp
    t.isKeyMonster = isKeyMonster
    t.monsters = {}
    return t  
end 

----格子上的事件数据 
--[[
eventData = {     EventData，如果是事件类型要有事件数据,为了方便看结构直接放这里
    choiceDatas     eventChoiceData*    猫头鹰博士事件问题数组
    questionIndex   int                 猫头鹰博士问题index
    effects         Effect*             猫头鹰博士问题得effect，为了拓展做成数组
}   
eventChoiceData = {
    id              int     事件id
    selectIndex     int     选择的index
}
]]
function M.CreatEventData(ids,effects)  
    local t={}  
    t.choiceDatas = {}
    for i=1,#ids do
        local choiceData = {}
        choiceData.id = ids[i]
        choiceData.selectIndex = 0
        t.choiceDatas[i] = choiceData
    end
    t.questionIndex = 1
    t.effects = effects
    return t  
end

----格子上的怪物数据里战斗数据 
--[[
Monster = {
    id                  int     hero表id
    generateId          int     自己队伍中的唯一id
    eliteId             int     精英怪id
    level               int
    star                int
    position            int     怪物布阵中的位置
    hpRate              int
    attackRate          int
    scrollId            int
    scrollStar          int
    scrollHpRate        int
    scrollAttackRate    int
    HeroHp              int     血量万分比
    PetHp,              int*    {10000,10000,10000,10000}  --宠物血量万分比定死4个
    totalHp,            int     魔物和随从加起来，总血量为50000
}
]]
function M.CreatMonster(id,generateId,eliteId,level,star,position,hpRate,attackRate,scrollId,scrollStar,scrollHpRate)  
    local t={}  
    t.id = id
    t.generateId = generateId
    t.eliteId = eliteId
    t.level = level
    t.star = star
    t.position = position
    t.hpRate = hpRate
    t.attackRate = attackRate
    t.scrollId = scrollId
    t.scrollStar = scrollStar
    t.scrollHpRate = scrollHpRate
    t.HeroHp = 10000
    t.PetHp  = {10000,10000,10000,10000}
    t.totalHp = 50000
    return t  
end 

----迷宫里效果，类似buff  
--[[
Effect = {           
    index               int
    id                  int     effect的id
    level               int     effect等級,初始1級
    roundNumber         int     effect持续回合数
    roundType           int     dungeonDefine.EffectRoundType  effect回合类型，开格子、战斗
    triggerRound        int     总的触发的回合数
    triggerCount        int     当前剩余触发回合数
    overlay             int     叠加层数,初始1层
    totalTriggerCount   int     记录触发次数
}
]]
function M.CreatEffect(id,index,level,overlay)  
    level = level or 1
    overlay = overlay or 1
    local t= {}  
    t.id = id
    t.index = index
    t.level = level
    t.roundNumber = csv.CallCsvData("DungeonEffectCsvData","EffectRoundNumber","EffectRoundNumberFromArray",id,level)
    t.roundType = dungeonDefine.EffectRoundType[csv.CallCsvData("DungeonEffectCsvData","EffectRoundType","EffectRoundTypeFromArray",id,level)] 
    t.triggerRound = csv.CallCsvData("DungeonEffectCsvData","TriggerRound","TriggerRoundFromArray",id,level)
    t.triggerCount = t.triggerRound
    t.overlay = overlay
    t.totalTriggerCount = 0
    return t  
end  

----物品  
--[[
Item = {           
    id              int
    index           int
    followId        int     
    count           int
}
]]
function M.CreatItem(id,count,followId,index)  
    local t= {}  
    t.id = id
    t.count = count
    t.followId = followId
    t.index = index
    return t  
end 

----冒险者小队  
--[[
AdventurerSquad = {           
    id              int     小队id
    level           int     小队等级
    isActive        bool    是否出击状态
    comprehands     int*    领悟技能    
}
]]
function M.CreatAdventurerSquads()  
    local t = {}  
    for i=1,3 do
        table.insert(t,{id=i,level=1,isActive=false,comprehands={0,0,0,0}})
    end
    return t  
end

----玩家魔物  
--[[
Hero = {           
    id              int
    position        int     上阵位置，没上阵为-1
    HeroHp          int     
    PetHp           int*
    totalHp         int
}
]]
function M.CreatHero(id)  
    local t= {}  
    t.id = id
    t.position = -1
    t.HeroHp = 10000
    t.PetHp = {10000,10000,10000,10000}
    t.totalHp = 50000
    return t  
end 

----执行步骤  
--[[
Step = {           
    notificationType    int     dungeonDefine.NotificationType
    data {
        x               int
        y               int
        paraInt1        int     传递int参数1
        paraInt2        int     传递int参数2     
        isPlayer        bool
        unitHPData {
            HeroHp      int
            PetHp       int*
            totalHp     int
        }
        item            Item
        effect          Effect
        stuff           Stuff
        dungeonEvent {
            id          int     事件id
            index       int     事件选项
            isSuccess   bool    是否成功
        }
        gridClass       Grid
        heroDatas       Hero*
        adventurerSquads AdventurerSquad*
    }
}
]]
function M.CreatStep(notificationType)  
    local t= {}  
    t.notificationType = notificationType
    return t  
end 

----迷宫结构 
--[[
Maze = {           
    grid    Grid*
}
]]

----轉換服務器數據，迷宫所有需要存储的数据结构 
--[[
DungeonData = {           
    dungeonType         int     dungeonDefine.DungeonType
    difficultyLevel     int     dungeonDefine.DifficultyLevelType
    mazeTier            int     迷宫层数
    maze                Maze*  格子Grid的二维数组
    keyNumber           int     
    myKeyNumber         int  
    bag                 Item*   
    effectList          Effect*   
    effectIndex         int
    playerPoint         Point
    heroDatas           Hero*
    roundNumber         int
    battleRoundNumber   int
}
]]
function M.TransformDungeonData(serverDungeonData)  
    local t= {}  
    t.dungeonType = serverDungeonData.dungeonType
    t.difficultyLevel = serverDungeonData.difficultyLevel
    t.mazeTier = serverDungeonData.mazeTier
    t.maze = mazeListToTable(serverDungeonData.maze) 
    t.keyNumber = serverDungeonData.keyNumber
    t.myKeyNumber = serverDungeonData.myKeyNumber
    t.bag = ListToTable(serverDungeonData.bag)
    t.effectList = ListToTable(serverDungeonData.effectList)
    t.effectIndex = serverDungeonData.effectIndex
    t.playerPoint = serverDungeonData.playerPoint
    t.heroDatas = toMonsters(serverDungeonData.heroDatas) 
    t.roundNumber = serverDungeonData.roundNumber
    t.battleRoundNumber = serverDungeonData.battleRoundNumber
    t.adventurerSquads = toAdventurerSquads(serverDungeonData.adventurerSquads)
    t.cacheEffectList = ListToTable(serverDungeonData.cacheEffectList)
    return t  
end

--转换转发协议的Response结构给服务器
function M.TransformResponseToServer(resp)  
    if resp.data.maze ~= nil then
        local t = resp.data.maze
        resp.data.maze = {}
        for i=1,#t do
            resp.data.maze[i] = {}
            resp.data.maze[i].list = {}
            for j=1,#t[i] do
                resp.data.maze[i].list[j] = t[i][j]
            end
        end
    end
    return resp  
end 

--转换转发协议的Response结构给客户端
function M.TransformResponseToClient(resp)  
    local t= {}  
    t.protocolType = resp.protocolType
    t.error = resp.error
    t.data = {}
    t.data.dungeonType = resp.data.dungeonType
    t.data.difficultyLevel = resp.data.difficultyLevel
    t.data.mazeTier = resp.data.mazeTier
    t.data.maze = mazeListToTable(resp.data.maze) 
    t.data.keyNumber = resp.data.keyNumber
    t.data.myKeyNumber = resp.data.myKeyNumber
    t.data.bag = ListToTable(resp.data.bag)
    t.data.effectList = ListToTable(resp.data.effectList)
    t.data.effectIndex = resp.data.effectIndex
    t.data.playerPoint = resp.data.playerPoint
    t.data.heroDatas = toMonsters(resp.data.heroDatas) 
    t.data.roundNumber = resp.data.roundNumber
    t.data.battleRoundNumber = resp.data.battleRoundNumber
    t.data.adventurerSquads = toAdventurerSquads(resp.data.adventurerSquads)
    t.data.cacheEffectList = ListToTable(resp.data.cacheEffectList)
    t.data.paramBool1 = resp.data.paramBool1
    t.data.paramInt1 = resp.data.paramInt1
    t.data.item = resp.data.item
    t.data.stuff = resp.data.stuff
    if resp.data.stuffList ~= nil then
        t.data.stuffList = {}
        local stuffList = resp.data.stuffList
        for i=0,stuffList.Count-1 do
            table.insert(t.data.stuffList,toStuff(stuffList[i]))
        end
    end
    t.data.path = ListToTable(resp.data.path) 
    t.data.battleGameData = resp.data.battleGameData
    if resp.data.relic ~= nil then
        t.data.relic = {}
        t.data.relic.x = resp.data.relic.x
        t.data.relic.y = resp.data.relic.y
        t.data.relic.ids = ListToTable(resp.data.relic.ids)
    end
    local serverSteps = resp.steps
    t.steps = {}
    for i=0,serverSteps.Count-1 do
        local serverStep = serverSteps[i]
        local step = {}
        step.notificationType = serverStep.notificationType
        step.data = {}
        step.data.x = serverStep.data.x
        step.data.y = serverStep.data.y
        step.data.paraInt1 = serverStep.data.paraInt1
        step.data.paraInt2 = serverStep.data.paraInt2
        step.data.isPlayer = serverStep.data.isPlayer
        if serverStep.data.unitHPData ~= nil then
            step.data.unitHPData = {}
            step.data.unitHPData.HeroHp = serverStep.data.unitHPData.HeroHp
            step.data.unitHPData.PetHp = ListToTable(serverStep.data.unitHPData.PetHp)
        end
        step.data.heroDatas = toMonsters(serverStep.data.heroDatas) 
        step.data.item = serverStep.data.item
        step.data.effect = serverStep.data.effect
        step.data.stuff = toStuff(serverStep.data.stuff) 
        step.data.dungeonEvent = serverStep.data.dungeonEvent
        step.data.gridClass = toGridClass(serverStep.data.gridClass)  
        step.data.heroDatas = toMonsters(serverStep.data.heroDatas)
        step.data.adventurerSquads = toAdventurerSquads(serverStep.data.adventurerSquads)
        table.insert(t.steps,step)
    end
    t.rewards = resp.rewards
    t.hashCode = resp.hashCode
    return t  
end 
  
return M  
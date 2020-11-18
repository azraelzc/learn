local M = {}

--协议的类型
M.ProtocolType = {
	CreateMaze = 1,					--创建迷宫

	OperateGrid = 3,				--处理某格格子
	GetItem = 4,					--获得物品
	GetEvent = 5,					--获得事件
	ChoiceEvent = 6,				--选择事件
	FinishEvent = 7,				--一次事件触发结束
	FightMonster = 8,				--与怪物战斗

	GetRelics = 10,					--通过eventId请求3个遗物
	ChoiceRelic = 11,				--选择一个遗物
	GoNextTier = 12,				--进入下一层
	UseItem = 13,					--使用物品
	UseDragonBall = 14,				--使用龙珠祭坛
	TargetEffect = 15,				--选目标buff
	StartBattle = 16,				--开始战斗
	EndBattle = 17,					--战斗结束
	AdventurerSquadLevelup = 18,	--冒险小队升级
	AdventurerSquadActive = 19,		--冒险小队激活
	GlacierKingActive = 20,			--冰川之王激怒
	DoctorOwlAnswer = 21,			--猫头鹰博士答题

	Empty = 999,			--为了通关存储发一条空协议
	testAddStuff = 1001,	--debug添加东西，暂时就添加物品吧
	testToTier = 1002,		--需要再迷宫里，输入层数
	testRemoveEffect = 1003,		--需要再迷宫里，删除effect
}

--为了按步骤播放特效、动画，定义通知类型
M.NotificationType = {
	OpenGrid = 1,				--打开格子
	BanGrid = 2,				--怪物出现ban掉周围格子
	RemoveBanGrid = 3,			--怪物四掉去掉被ban的格子
	RemoveMistGrid = 4,			--去掉迷雾的格子
	RefreshGrid = 5,			--刷新格子格子
	ShowStuff = 6,		    	--出现怪物、事件、物品
	RemoveStuff = 7,			--杀死怪物、使用事件
	GetItem = 8,				--获取物品
	AddEffect = 9,				--获取effect
	RemoveEffect = 10,			--移除effect
	DoEffect = 11,				--执行effect
	RefreshEffect = 12,			--更新effect数据
	GetKey = 13,				--获取钥匙
	UseItem = 14,				--使用物品
	HeroDatasChange = 15,		--玩家魔物数据改变
	SetItem = 16,				--设置物品
	DoEvent = 17,				--开启事件
	FinishCommonEvent = 18,		--完成普通事件
	ChangeHP = 19,				--加减血量
	TeamChangeHPStart = 20,		--为了动画表现，当teamhp开始变化时调用
	TeamChangeHPEnd = 21,		--为了动画表现，当teamhp结束变化时调用
	StuffAttack = 22,			--怪物攻击
	OnRound = 23,				--触发了一回合
	OnBattleRound = 24,			--触发了战斗一回合

	AdventurerSquadActive = 25,	--当小队激活时候
	AdventurerSquadLevelup = 26,--当小队升级时候
	AddCacheEffect = 27,		--添加effect到存储部分

	EnterDoor = 100,			--进入下一层
	EnterDoorAni = 101,			--进入下一层成功，播放动画
}

--协议报错类型
M.ProtocolErrorType = {
	None = 1,						--无错误
	CanNotGetItem = 2,				--格子上没物品
	EventIdError = 3,				--选择的事件id与服务器记录的事件id不匹配
	MovePosError = 4,				--移动的格子不对
	RelicIdError = 5,				--选择的遗物id不对
	CanNotGoNextTier = 6,			--不能进入下一层
	GameServerError = 7,			--游戏服务器报错
	UseItemError = 8,				--使用物品出错，id找不到
	UseItemSeal = 9,				--使用物品被封印，不能使用
	FightMonsterError = 10,			--和怪物战斗出错，格子上找不到怪物
	UseDragonBallError = 11,		--龙珠祭坛使用错误
	AdventurerSquadLevelupError = 12,		--冒险小队升级错误
	AdventurerSquadActiveError = 13,		--冒险小队激活错误
	GlacierKingActiveActiveError = 14,		--冰川之王激活错误
}

--迷宫类型
M.DungeonType = {
	None = 0,			--没选择类型
    Seabed = 1,			--海底迷宫
    Desert = 2,			--沙漠迷宫
    Glacier = 3,		--冰川迷宫
    MagicForest = 4,	--魔法森林
}

--迷宫生成类型
M.DungeonGenerateType = {
    Auto = 1,		--自动生成
    Manual = 2,		--手动生成
}

--迷宫难度类型
M.DifficultyLevelType = {
	None = 0,		--没选择难度
    Normal = 1,		--普通难度
    Hell = 2,		--地狱难度
}

--格子类型
M.MazeGridType = {
	None = 1,		--通路
	Entrance = 2,	--入口
	Exit = 3,		--出口
	Stuff = 4, 		--有东西的格子
	Block = 5,		--阻挡
}

--通用的东西类型
M.StuffType = {
	None = 1,
	Monster = 2,	--怪物
	Event = 3,		--事件
	Item = 4,		--物品
	Effect = 5,		--效果
}

--掉落类型
M.EnemyDropTyoe = {
	None = 1,		--什么都不掉落
	Event = 2,		--事件
	Item = 3,		--掉落物品
}

--使用物品或开启事件或怪物掉落后随机东西的类型
M.RandomTyoe = {
	None = 1,		
	Event = 2,		--事件
	Item = 3,		--物品
	Effect = 4,		--buff
}

--buff造成的效果类型
M.EffectAttributeType = {
	None = 1,			--其他的特殊效果
	HP = 2,				--血量
	PhysicalDamage = 3,	--物理攻击		
	MagicalDamage = 4,	--魔法攻击
}

--点击格子返回操作
M.OperateGridType = {
	None = 1,				--点的空地
	Event = 2,				--触发事件
	Monster = 3,			--触发怪物
	Open = 4,				--打开格子
}

--事件类型
M.EventType = {
	Common = 1,				--通用事件
	Relic = 2,				--遗物
	DragonBall = 3,			--龙珠事件
	AdventurerSquad = 4,	--冒险者小队
	GlacierKingSleep = 5,	--沉睡的冰川之王
	GlacierKingAnger = 6,	--愤怒的冰川之王
	DoctorOwl = 7,			--猫头鹰博士
	DoctorOwlQuestion = 8,	--猫头鹰博士的问题
}

--物品类型
M.ItemType = {
	Useable = 1,			--可以使用的物品
	DragonBallRed = 2,		--红色龙珠
	DragonBallBlue = 3,		--蓝色龙珠
	DragonBallYellow = 4,	--黄色龙珠
	AttackToken = 5,		--出击令
	Swordman = 6,			--剑士升级道具
	Sage = 7,				--贤者升级道具
	Priest = 8,				--牧师升级道具
}

--事件触发类型
M.EventTriggleType = {
	Manual = 1,				--手动
	Auto = 2,				--自动
}

--事件动画类型
M.EventAnimType = {
	None = 1,				--无动画
	BreakCage = 2,			--打破牢笼
}

--buff品质
M.EffectRarity = {
	Normal = 1,				--普通
	Rare = 2,				--稀有
}

--buff回合類型
M.EffectRoundType = {
	None = 1,				--不会主动触发
	Grid = 2,				--翻格子
	Battle = 3,				--战斗
	SelfDead = 4,			--单位自身死亡
	EnemyDead = 5,			--敌人单位死亡
	AllyDead = 6,			--玩家盟友单位死亡
	Event = 7,				--触发一个事件
	Item = 8,				--使用一个道具一个事件
}

--effect類型
M.EffectType = {
	BUFF = 1,				--增益buff
	DEBUFF = 2,				--减益buff
	RELIC = 3,				--遗物
	SPECIALDEBUFF = 4,		--特殊的减益buff，为了不被清除debuff的道具清除
}

--effect目标队伍类型
M.EffectTargetTeamType = {
	All = 1,			--所有队伍
	Self = 2,			--对自己
	Ally = 3,			--对盟友
	Friendly = 4,		--对自己和盟友
	Enemy = 5,			--对敌人
	EnemyAlly = 6,		--对敌人盟友
	TargetAlly = 7,		--对指定盟友
	TargetEnemy = 8,	--对指定敌人
	Player = 9,			--对玩家
	ExceptSelf = 10,	--除了自己之外的
}

--effect目标队伍里魔物类型
M.EffectTargetUnitType = {
	LowestHP = 1,			--最低血量目标
	HeightHP = 2,			--最高血量目标
	Random = 3,				--随机目标
	Dead = 4,				--死亡目标
	PetDead = 5,			--只有随从死亡，魔物没死的目标
}

--buff類型
M.EffectBuffType = {
	HPAll = 1,				--所有的加血或者减血,EffectPara1:血量百分比
	HPHero = 2,				--对魔物加血或者减血,EffectPara1:血量百分比
	HPPet = 3,				--对随从加血或者减血,EffectPara1:血量百分比
	RelieveDebuff = 4,		--解除减益
	ImmuneDebuff = 5,		--免疫减益
	SealPassiveness = 6,	--封印被动
	SealAllItem = 7,		--无法使用所有道具
	Resurrection = 8,		--随机复活魔物和随从,EffectPara1:复活血量百分比
	OpenGrid = 9,			--翻开格子,EffectPara1:开格子数量
	Stifle = 10,			--窒息,EffectPara1:回合数后受到伤害,EffectPara2:伤害
	ClearStifle = 11,		--消除窒息层数
	AddEffect = 12,			--添加一个effect,EffectPara1:effect表id,EffectPara2:概率
	TargetNumber = 13,		--增加或减少目标单位,EffectPara1:数量
	DamageAddEffect = 14,	--effect造成伤害时加effect,EffectPara1:effect表id,EffectPara2:概率
	Sputtering = 15,		--溅射,EffectPara1:基础伤害千分比,EffectPara2:距离
	KillHPBelowPer = 16,    --血量百分比之下的斩杀,EffectPara1:斩杀血线
	CureAddEffect = 17,    	--回血的時候添加effect,EffectPara1:effect表id,EffectPara2:概率
	ResurrectionPet = 18,	--随机复活魔物的随从,EffectPara1:复活血量百分比
	ResurrectionHero = 19,	--随机复活魔,EffectPara1:复活血量百分比
	DoEffectAddEffect = 20,	--当释放技能时候AddEffect,EffectPara1:effect表id,EffectPara2:概率
	AddCacheEffect = 21,	--触发时会记录一个effect,EffectPara1:effect表id,EffectPara2:概率
	GetCacheEffect = 22,	--将缓存effect加到身上
	SwitchAddEffect = 23,	--轮换添加技能,EffectPara1:lib表id
	DirectionHP = 24,		--[[方向性影响血量的effect,TargetTeamNum:距离，EffectPara1：方向类型DirEffectType，
								DirEffectType2：单位HPTargetType，DirEffectType3：伤害]]
}

--方向类型effect的方向定义
M.DirEffectType = {
	X = 1,			--X方向
	Cross = 2,		--十字方向
}

--对扣血加血类型effect的目标类型
M.HPTargetType = {
	All = 1,		--所有单位
	Hero = 2, 		--英雄
	Pet = 3,		--随从
}

--格子上是不是有东西
function M.IsStuff(self,c,isOpen)
    local flag = false
    if c ~= nil and (isOpen == nil or c.isOpen == isOpen) and c.gridType == self.MazeGridType.Stuff then
        flag = true
    end
    return flag
end

--格子上的东西是不是指定类型
function M.IsStuffType(self,c,stuffType,isOpen)
    local flag = false
    if c ~= nil and (isOpen == nil or c.isOpen == isOpen) and c.gridType == self.MazeGridType.Stuff and c.stuff.stuffType == stuffType then
        flag = true
    end
    return flag
end

return M
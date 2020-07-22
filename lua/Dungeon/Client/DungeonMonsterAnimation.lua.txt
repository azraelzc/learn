local Utils = require("Utils")
local dungeonDefine = require("Dungeon.DungeonDefine")
local dungeonUtils = require("Dungeon.DungeonUtils")
local dungeonUnitAnimation = require("Dungeon.Client.DungeonUnitAnimation")

local M = dungeonUnitAnimation:extend()

function M.Attack(self)
    self.animator:Play("Dungeon_Monster_Attack",0)
end

function M.Cast(self)
    self.animator:Play("Dungeon_Monster_Cast",0)
end

function M.Hit(self)
    self.animator:Play("Dungeon_Monster_Hit",0)
end

function M.Idle(self)
    --self.animator:Play("Dungeon_Monster_Standby",-1)
end

function M.Enter(self)
    self.animator:Play("Dungeon_Monster_Appear",0)
end

function M.Out(self,cb)
    Utils.playAnimation(self.animator,"Dungeon_Monster_Disappear",self.trigger,cb)
end

function M.PlayAnimByName(self,name)
    Utils.playAnimation(self.animator,name,self.trigger,function() 
		self:Idle()
	end)
end

function M.new(self,obj)
	M.super.new(self,obj)
	self.animator = obj:GetComponent("Animator")
	self.trigger = obj:GetComponent("AnimatorFinishEventTrigger")
end

return M  
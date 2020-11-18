local Utils = require("Utils")
local dungeonDefine = require("Dungeon.DungeonDefine")
local dungeonUtils = require("Dungeon.DungeonUtils")
local dungeonUnitAnimation = require("Dungeon.Client.DungeonUnitAnimation")

local M = dungeonUnitAnimation:extend()

function M.Enter(self)
	Utils.playAnimation(self.animator,"Dungeon_Event_Appear",self.trigger,function() 
		self:Idle()
	end)
end

function M.Out(self,cb)
    Utils.playAnimation(self.animator,"Dungeon_Event_Disappear",self.trigger,cb)
end

function M.Idle(self)
	if self.idleName ~= nil then
		self.animator:Play(self.idleName,0,0)
	end
end

function M.Attack(self)
	--self.animator:Play("Dungeon_Event_Attack",0,0)
	Utils.playAnimation(self.animator,"Dungeon_Event_Attack",self.trigger,function() 
		self:Idle()
	end)
end

function M.Cast(self)
	Utils.playAnimation(self.animator,"Dungeon_Event_Cast",self.trigger,function() 
		self:Idle()
	end)
end

function M.SetIdleName(self,idleName)
	self.idleName = idleName
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
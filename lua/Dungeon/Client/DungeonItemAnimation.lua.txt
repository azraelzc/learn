local Utils = require("Utils")
local dungeonDefine = require("Dungeon.DungeonDefine")
local dungeonUtils = require("Dungeon.DungeonUtils")
local dungeonUnitAnimation = require("Dungeon.Client.DungeonUnitAnimation")

local M = dungeonUnitAnimation:extend()

function M.Enter(self)
    self.animator:Play("Dungeon_Item_Appear",0)
end

function M.Out(self,cb)
    Utils.playAnimation(self.animator,"Dungeon_Item_Disappear",self.trigger,cb)
end

function M.new(self,obj)
	M.super.new(self,obj)
	self.animator = obj:GetComponent("Animator")
	self.trigger = obj:GetComponent("AnimatorFinishEventTrigger")
end

return M  
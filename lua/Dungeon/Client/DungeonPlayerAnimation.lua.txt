local dungeonDefine = require("Dungeon.DungeonDefine")
local dungeonUtils = require("Dungeon.DungeonUtils")
package.loaded["Dungeon.Client.DungeonUnitAnimation"] = nil
local dungeonUnitAnimation = require("Dungeon.Client.DungeonUnitAnimation")

local M = dungeonUnitAnimation:extend()

local moving = false

local function onTrackComplate(self,track)
	track:Complete("+" , function(e)
        moving = false
        self.animation.AnimationState:AddEmptyAnimation(1,0.2,0)
    end) 
end

function M.ClearCurrentTrack(self)
    moving = false
    local track = self.animation.AnimationState:GetCurrent(1)
    if track then
        self.animation.AnimationState:SetEmptyAnimation(1, 0)
    end
end

function M.Attack(self)
    self.animation.AnimationState:SetAnimation(1,"Dungeon_Player_Attack",false)
    onTrackComplate(self,self.animation.AnimationState:AddAnimation(1,"Dungeon_Player_Back",false,0))
end

function M.Cast(self)
	onTrackComplate(self,self.animation.AnimationState:SetAnimation(1,"Dungeon_Player_Cast",false))
end

function M.Hit(self)
    onTrackComplate(self,self.animation.AnimationState:SetAnimation(1,"Dungeon_Player_Hit",false))
end

function M.Idle(self)
    self.animation.AnimationState:SetAnimation(0,"Dungeon_Player_Standby",true)
end

function M.Enter(self)
    onTrackComplate(self,self.animation.AnimationState:SetAnimation(1,"Dungeon_Player_Enter",false))
end

function M.Out(self,cb)
    self.animation.AnimationState:SetAnimation(1,"Dungeon_Player_Out",false)
    local track = self.animation.AnimationState:AddEmptyAnimation(0,0.2,0)
    track:Complete("+" , function(e)
         if cb ~= nil then
            cb()
         end
    end) 
end

function M.Move(self)
    if not moving then
        self:ClearCurrentTrack(self)
        moving = true
        local track = self.animation.AnimationState:GetCurrent(1)
        track = self.animation.AnimationState:SetAnimation(1,"Dungeon_Player_Mobile",false)
        track:Complete("+" , function(e)
            moving=false
            self.animation.AnimationState:AddEmptyAnimation(1,0.2,0)
        end) 
    end
end

function M.new(self,obj)
	M.super.new(self,obj)
	self.animation = obj.transform:Find("CHARACTER"):GetComponent(typeof(CS.Spine.Unity.SkeletonGraphic))
end

return M  
local LuaObject = require("Dungeon.LuaObject")
local dungeonDefine = require("Dungeon.DungeonDefine")
local dungeonUtils = require("Dungeon.DungeonUtils")

local M = LuaObject:extend()

function M.Attack(self)
    
end

function M.Cast(self)
    
end

function M.Hit(self)
    
end

function M.Idle(self)
    
end

function M.Enter(self)
    
end

function M.Out(self,cb)
   
end

function M.PlayAnimByName(self,name)
    
end

--因为是2d的，所以缩放x坐标正负转向,orientation为迷宫坐标方向，(1,1)
function M.UnitToward(self,orientation)
    local scaleX = 1
    if (orientation.x == 0 and orientation.y < 0) or (orientation.y == 0 and orientation.x < 0) then
        scaleX = -1
    end
    self.obj.transform.localScale = CS.UnityEngine.Vector3(scaleX,1,1)
end

function M.new(self,obj)
    M.super.new(self)
    self.obj = obj
end

return M  
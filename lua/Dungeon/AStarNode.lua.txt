local dungeonDefine = require("Dungeon.DungeonDefine")

----定义节点类  
local node= {}

local function gridCanMove(c)
    if c.gridType == dungeonDefine.MazeGridType.Block then
        return false
    elseif c.gridType == dungeonDefine.MazeGridType.Stuff then
        if c.stuff.stuffType == dungeonDefine.StuffType.Monster then
             return false
        elseif c.stuff.stuffType == dungeonDefine.StuffType.Event then
             return false
        end
    end
    if c.isBan then
        return false
    end
    if not c.isOpen then
        return false
    end
    return true
end

--创建节点,x,y是map的item  
function node.create(x,y,maze)  
    local myNode={}  
    -- 节点在tmx的位置  
    myNode.x = x;  
    myNode.y = y;  
    ---A start参数  
    myNode.g = 0;  --当前节点到起始点的代价  
    myNode.h = 0;  --当前点的终点的估价  
    myNode.f = 0;  --f=g+h  
    myNode.moveable = gridCanMove(maze[x][y])  --该节点是否可行走  
     
    myNode.father={} -- 记录父节点,用来回溯路径    
    return myNode  
end  
  
return node  
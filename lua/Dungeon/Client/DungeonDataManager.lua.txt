local dungeonDefine = require("Dungeon.DungeonDefine")
local dungeonUtils = require("Dungeon.DungeonUtils")
local ERId = require("ERId")

--迷宫数据类
local M= {}

function M.ReloadToTier(self)
    local tier = 0
    if S_DungeonData.mazeTier > 0 then
        tier = dungeonUtils.LayerToTier(S_DungeonData.dungeonType,S_DungeonData.mazeTier)
        if tier > 5 then
            local n = math.floor(tier/5)
            if math.fmod(tier,5) == 0 then
                tier = (n - 1) * 5 + 1
            else
                tier = n * 5 + 1
            end
        else
            tier = 0    
        end
    end
    return tier
end

function M.GetActivedAdventurerSquadIcon(self)
    local activeData = self:GetActivedAdventurerSquad()
    local mapIcon,uiIcon
    if activeData ~= nil then
        if activeData.id == 1 then
            mapIcon = "Event_Swordsman"
        elseif activeData.id == 2 then
            mapIcon = "Event_Sage"
        else
            mapIcon = "Event_Priest"
        end
    end
    return mapIcon,uiIcon
end

function M.GetActivedAdventurerSquad(self)
    local activeData
    local adventurerSquads = S_DungeonData:GetAdventurerSquads()
    for i=1,#adventurerSquads do
        if adventurerSquads[i].isActive then
            activeData = adventurerSquads[i]
            break
        end
    end
    return activeData
end
  
return M  
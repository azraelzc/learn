local csv = require("Dungeon.LuaCallCsvData")

local M = {}

function M.Create(dungeonId)
	local mapInfos = csv.CallCsvData("DungeonManualGenerateCsvData","ManualMapInfo","ManualMapInfoArray",dungeonId)
	local maze = {}
	for i=1,#mapInfos do
		for j=0,#mapInfos[i]do
			if maze[i] == nil then
				maze[i] = {}
			end
			maze[i][j] = mapInfos[i][j]
		end
	end
	return maze
end

return M
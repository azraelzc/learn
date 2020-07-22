local csv = require("Dungeon.LuaCallCsvData")
local M = {}



local MazeGridType = {
	Black = 0,			--砖块
	Route = 1,			--通路
	Entrance = 2, 		--入口
	Exit = 3, 			--出口
}

local L = 0

--判断点是否符合要求
local function checkPoint(maze,x,y,centerX,centerY,tempMaze)
	local flag = false
	if tempMaze[x] == nil then
		tempMaze[x] = {}
	elseif tempMaze[x][y] == nil then
		tempMaze[x][y] = true
	end
	local pointNum = 0
	for i=-1,1 do
		for j=-1,1 do
			local newX = centerX + i
			local newY = centerY + j
			if maze[newX] == nil or maze[newX][newY] == nil or (newX ~= centerX or newY ~= centerY) and (newX ~= x or newY ~= y) and (tempMaze[newX] ~= nil and tempMaze[newX][newY]) then
				pointNum = pointNum + 1
				if math.abs(newX - x) + math.abs(newY -y) > 1 then
					flag = true
					break
				end
			end
		end
		if flag then
			break
		end
	end
	if pointNum == 0 then
		flag = true
	end
	return flag
end

--判断通路是否被包围,true为可以创建砖块
local function checkSurround(maze,x,y,tempMaze)
	if tempMaze[x] ~= nil and tempMaze[x][y] ~= nil then
		return true
	end
	local num = 0
	if tempMaze[x] == nil then
		tempMaze[x] = {}
	end
	tempMaze[x][y] = true
	for i=-1,1 do
		for j=-1,1 do
			if i ~= 0 or j ~= 0 then
				local newX = x+i
				local newY = y+j
				if maze[x+i] == nil then
					if checkPoint(maze,newX,newY,x,y,tempMaze) then
						num = num + 1
					end
				else
					local t = maze[x+i][y+j]
					if t == nil then
						if checkPoint(maze,newX,newY,x,y,tempMaze) then
	 						num = num + 1
	 					end
					elseif t == MazeGridType.Black then
	 					if checkPoint(maze,newX,newY,x,y,tempMaze) then
	 						num = num + 1
	 					end
	 					local isSurround = checkSurround(maze,newX,newY,tempMaze)
	 					if not isSurround then
	 						num = num + 1
	 					end
					end
				end	
			end
		end
	end
	return num >= 2
end

local function createMaze(maze,blockNum)
	--因为砖块会随机以及判断是否符合要求，很可能出现不了预期的砖块数量，因此多循环几遍
	local depth = blockNum * 5
	while(blockNum > 0 and depth > 0) do
		local i = math.random(L)
		local j = math.random(L)
		if maze[i][j] == MazeGridType.Route then
			depth = depth - 1
			maze[i][j] = MazeGridType.Black
			local tempMaze = {}
			local flag = checkSurround(maze,i,j,tempMaze) --判断是否会可以创建砖块,true为可以不创建砖块
			if flag then
				maze[i][j] = MazeGridType.Route
			else
				blockNum = blockNum - 1
			end
		end
	end
end

local function calExitPosition(entryX,entryY)
	local exitX = 1
	local exitY = 1
	if entryX > L - entryX then
		exitX = math.random(1,entryX-1)
	else
		exitX = math.random(entryX+1,L) 
	end
	if entryY > L - entryY then
		exitY = math.random(1,entryY-1)
	else
		exitY = math.random(entryY+1,L) 
	end
	return exitX,exitY
end

local function randomEvent(maze,num,str)
	while(num > 0) do
		local x = math.random(1,#maze)
		local y = math.random(1,#maze)
		if maze[x][y] == "N" then
			num = num - 1
			maze[x][y] = str
		end
	end
end

local function createDungeonData(dungeonId,maze,enemyNum,itemNum,eventNum)
	--把固定的替换
	for i=1,#maze do
		for j=1,#maze do
			if maze[i][j] == MazeGridType.Route then
				maze[i][j] = "N"
			elseif maze[i][j] == MazeGridType.Entrance then 
				maze[i][j] = "I"
			elseif maze[i][j] == MazeGridType.Exit then
				maze[i][j] = "O"
			else
				maze[i][j] = "B"
			end
		end
	end

	randomEvent(maze,enemyNum,"M")
	randomEvent(maze,itemNum,"G")
	randomEvent(maze,eventNum,"E")
end

function M.Create(dungeonId,enemyNum,itemNum,eventNum)
	local size = csv.CallCsvData("DungeonAutoGenerateCsvData","AutoDungeonSize","AutoDungeonSize",dungeonId)
	local maze = {}
	L = math.sqrt(size)
	for i=1,L do
		maze[i] = {}
		for j=1,L do
			maze[i][j] = MazeGridType.Route
		end
	end

	--随机生成入口位置
	local entryX = math.random(1,L)
	local entryY = math.random(1,L)
	maze[entryX][entryY] = MazeGridType.Entrance

	local exitX,exitY = calExitPosition(entryX,entryY)
	maze[exitX][exitY] = MazeGridType.Exit

	--砖块数量,-2代表去掉出入口
	local blockNum =math.random(0,size - (enemyNum + itemNum + eventNum) - 2) 
	createMaze(maze,blockNum)
	createDungeonData(dungeonId,maze,enemyNum,itemNum,eventNum)
	return maze
end

return M
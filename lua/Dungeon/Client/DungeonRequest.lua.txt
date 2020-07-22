local json = require("dkjson")
local dungeonServerProxyModel = require("Dungeon.Server.DungeonServerProxy")
local dungeonDefine = require("Dungeon.DungeonDefine")
local dungeonStruct = require("Dungeon.DungeonStruct")
local dungeonUtils = require("Dungeon.DungeonUtils")

local M = {}

local requestList = {}

local openLayer = 21
local tourMax = 20
local tourCross = 19

local function sendRequest()
	if #requestList > 0 and not isSendingRequest then
		isSendingRequest = true
		local r = requestList[1]
		table.remove(requestList,1)
		local req = CS.JoywindsSprotoType.DungeonRequest.request()
		req.id = S_DungeonData:GetDungeonType()
		req.req = CS.JoywindsSprotoType.DungeonReq()
		req.req.protocolType = r.reqData.protocolType
		req.req.id = r.reqData.id or 0
		req.req.index = r.reqData.index or 0
		req.req.x = r.reqData.x or 0
		req.req.y = r.reqData.y or 0
		req.req.paramInt1 = r.reqData.paramInt1 or 0
		req.req.paramInt2 = r.reqData.paramInt2 or 0
		req.req.paramInt3 = r.reqData.paramInt3 or 0
		if r.reqData.effect ~= nil then
			req.req.effect = r.reqData.effect
		end
		if r.reqData.fightheroDatas ~= nil then
			req.req.fightheroDatas = r.reqData.fightheroDatas
		end
		if r.reqData.startData ~= nil then
			req.req.startData = r.reqData.startData
		end
		req.req.randomSeed = r.reqData.randomSeed or 0
		if r.reqData.hashCode ~= nil then
			req.req.hashCode = r.reqData.hashCode
		end
		--printT("==reqData==",PairTabMsg(r))
	    CS.RPC.Client.Call(req, function(res)
	    	if res.HasError then
	    		print("==respData server error==",res.error.msg)
	    	end
	    	local respData = {error=dungeonDefine.ProtocolErrorType.None}
	    	if res.res ~= nil then
	    		respData = dungeonStruct.TransformResponseToClient(res.res)
	    	end
        	S_EventManager:Fire("dungeonStepNotification",respData.steps)
        	--printT("==respData==",PairTabMsg(respData))
            r.callback(respData,res.error)
	        isSendingRequest = false
	        sendRequest()
	    end)
	end
end

local function serverRequest(reqData,callback)
	local r = {}
	r.reqData = reqData
	r.callback = callback
	table.insert(requestList,r)
	sendRequest()
end

local function localRequest(reqData,callback)
	local newReqData = dungeonUtils.copyTable(reqData) 
	local serverError,respData = dungeonServerProxy:Request(newReqData)
	if callback then
		local newRespData = dungeonUtils.copyTable(respData) 
		S_EventManager:Fire("dungeonStepNotification",newRespData.steps)
    	callback(newRespData)
    end
end

--请求服务器
function M.Request(reqData,callback)
	if S_DungeonLocal then
		localRequest(reqData,callback)
	else
		serverRequest(reqData,callback)
	end
end

--获取迷宫记录
function M.RequestGetDungeonInfo(id, callback)
	local respData = {error=dungeonDefine.ProtocolErrorType.None}
	if S_DungeonLocal then
		respData.tourMax = tourMax
		respData.tourCross = tourCross
		respData.currentOpenTour = openLayer
		respData.startTime = 0
		respData.receivedTour = 0
		respData.receivedTour2 = 0
		callback(respData)
	else
		local req = CS.JoywindsSprotoType.GetDungeonInfo.request()
		req.id = id
	    CS.RPC.Client.Call(req, function(res)
	        if not res.HasError then
	        	respData.tourMax = res.tourMax
	        	respData.tourCross = res.tourCross
	        	respData.currentOpenTour = res.currentOpenTour
	        	respData.startTime = res.startTime
	        	-- respData.id = res.id
	        	respData.id = res.isMain
		        respData.boxInfo = res.boxInfo
		        respData.receivedTour = res.receivedTour
		        respData.receivedTour2 = res.receivedTour2
	        	if res.uiDataJson ~= nil then
		        	respData.uiData = {}
		        	respData.uiData.dungeonType = res.uiDataJson.dungeonType
		        	respData.uiData.difficultyLevel = res.uiDataJson.difficultyLevel
		        	respData.uiData.mazeTier = res.uiDataJson.mazeTier
	        	end
	        else
	        	print("====RequestGetDungeonInfo error====",res.error.msg)
	           	respData.error = dungeonDefine.ProtocolErrorType.GameServerError
	           	respData.serverError = res.error
	        end
	        callback(respData)
	    end)
	end
end

--第一次创建迷宫
function M.RequestDungeonCreate(reqData,callback)
	local respData = {error=dungeonDefine.ProtocolErrorType.None}
	if S_DungeonLocal then
		local heroes = CS.Joywinds.Data.GameData.Instance:GetHeroes()
	    local heroIds = {}
	    local totalNum = 10
	    for _,v in pairs(heroes) do
	    	totalNum = totalNum - 1
            table.insert(heroIds,v.Id)
            if totalNum <= 0 then
            	break
            end
	    end
		dungeonServerProxy:CreateData(heroIds,reqData.dungeonType,reqData.difficultyLevel)
		local data = dungeonServerProxy:SaveData()
		local newData = dungeonUtils.copyTable(data) 
		respData.data = newData
		callback(respData)
	else
		local req = CS.JoywindsSprotoType.DungeonCreate.request()
		req.id = reqData.dungeonType
    	req.difficult = reqData.difficultyLevel
	    CS.RPC.Client.Call(req, function(res)
	        if not res.HasError then
	        	respData.data = dungeonStruct.TransformDungeonData(res.dataJson) 
	        else
	        	print("====RequestDungeonCreate error====",res.error.msg)
	        	respData.error = dungeonDefine.ProtocolErrorType.GameServerError
	        end
	        callback(respData)
	    end)
	end
end

--获取迷宫详细信息
function M.RequestDungeonGet(reqData,callback)
	local respData = {error=dungeonDefine.ProtocolErrorType.None}
	if S_DungeonLocal then
		callback(respData)
	else
		local req = CS.JoywindsSprotoType.DungeonGet.request()
	    req.id = reqData.dungeonType
	    CS.RPC.Client.Call(req, function(res)
	        if not res.HasError then
	            respData.data = dungeonStruct.TransformDungeonData(res.dataJson)
	            respData.loadCount = res.loadCount
            else
            	print("====RequestDungeonGet error====",res.error.msg)
            	respData.error = dungeonDefine.ProtocolErrorType.GameServerError
            	respData.serverError = res.error
	        end
	        callback(respData)
	    end)
	end
end

--重置迷宫
function M.RequestDungeonReset(reqData,callback)
	local respData = {error=dungeonDefine.ProtocolErrorType.None}
	if S_DungeonLocal then
		dungeonServerProxy:Reset()
		callback(respData)
	else
		local req = CS.JoywindsSprotoType.DungeonReset.request()
	    req.id = reqData.dungeonType
	    print("=====RequestDungeonReset====",reqData.dungeonType)
	    CS.RPC.Client.Call(req, function(res)
	        if res.HasError then
	        	print("====RequestDungeonReset error====",res.error.msg)
	           	respData.error = dungeonDefine.ProtocolErrorType.GameServerError
	           	respData.serverError = res.error
	        end
	        callback(respData)
	    end)
	end
end

--回到之前5层迷宫
function M.RequestDungeonLoad(reqData,callback)
	local respData = {error=dungeonDefine.ProtocolErrorType.None}
	if S_DungeonLocal then
		dungeonServerProxy:Reset()
		callback(respData)
	else
		local req = CS.JoywindsSprotoType.DungeonLoad.request()
	    req.id = reqData.dungeonType
	    print("=====RequestDungeonLoad====",reqData.dungeonType,req)
	    CS.RPC.Client.Call(req, function(res)
	        if not res.HasError then
	            respData.data = dungeonStruct.TransformDungeonData(res.dataJson)
	            respData.loadCount = res.loadCount
            else
            	print("====RequestDungeonLoad error====",res.error.msg)
            	respData.error = dungeonDefine.ProtocolErrorType.GameServerError
            	respData.serverError = res.error
	        end
	        callback(respData)
	    end)
	end
end

--请求服务器
function M.Init(self)
	dungeonServerProxy = dungeonServerProxyModel.new()
	dungeonServerProxy:Init(nil,openLayer,tourCross,true)
end
  
return M
package.path = package.path..";./?.lua;"
socket  = require "skynet.socket"
local sharedata = require "skynet.sharedata"

local cjson = require "cjson"

local STATUS_ONLINE 	= 1		-- Player online status
local STATUS_OFFLINE 	= -1	-- Player offline status

local ACT_CONTROL 		= 2		-- Control action need stat sync
local ACT_COMBAT 			= 3		-- Combat action need frame sync

local GMS_INITED 			= 1		-- Room instance nitialized
local GMS_COUNTED 		= 2		-- Hero selection timeup or all player selected
local GMS_STARTED 		= 3 	-- All peers load complete and ready to enter combat scene
local GMS_EXITED 			= 4		-- Quit room 

local ROOM_KEEP_TIME 	= 35 * 100 --keep 35 seconds if all players left
local FRAME_INPUT 		= 40

local COMBAT_INFO_KEY 	= "{combat}{combat_srv_room_infos}"
local COMBAT_DATA_KEY		= "{last_combat_rc}{%s}" -- %s = pid

local OnlinePeers = {}
local MsgOnlinePeers 	= {	sender = 'refree',
													cmd = 'notify_online_peers',
													data= OnlinePeers 	}

local MsgCountDown 	 	= {	sender = 'refree',
													cmd = 'count_down',
													data = {}	} 

local MsgEnterCombat 	= {	sender = 'refree', 
													cmd = 'enter_combat',
													data = {} } 

local MsgGameStart 		= { sender = 'refree',
													cmd = 'game_start' }

class("Room", function(self) 
	self.players = {} --	hash pid -> player
	self.sids = {} 		-- 	hash sid => pid

	self.inputFrmLine = nil
	 
	self.token = nil
	self.roomInfo = nil

	--self.agentinfo = sharedata.query("UDP_AGENT_POOL")
	--print("agent pool",inspect(self.agentinfo))
end)

local m = Room

function m:init()
	print("[room] Room init....")
	RedisHelper.start()

	self.broadcaster = FrameBroadcaster.new(self)
	self.inputFrmLine = InputFrameLine.new(self.broadcaster)
	self.statModel = CombatStatModel.new(self)

	self.broadcaster:init()
	self.inputFrmLine:init(FRAME_INPUT)
end

function m:destroy()
	self:exit()

	collectgarbage("collect")
	skynet.exit()
end

function m:setRoomStatus(status)
	if not self.roomInfo then return end
	self.roomInfo.status = status
end

function m:inBattle()
	if self.roomInfo.status == GMS_STARTED then return true end
	return false
end

function m:exit()
	self:setRoomStatus(GMS_EXITED)
	self:stopCheckAllLeft()
	self:stopCountDown()
	self.broadcaster:exit()
	self.inputFrmLine:exit()
	self:removeRoomInfo()

	self.players = {} --	hash pid -> player
	self.sids = {} 		-- 	hash sid => pid
	self.token = nil
	self.broadcaster = nil
	self.inputFrmLine = nil
	self.roomInfo = nil
end

function m:removeRoomInfo()
	if not self.token then return end
	local hRoomMan = skynet.queryservice("room_man_service")
	print("[room] remove room:", self.token, hRoomMan )
	skynet.send(hRoomMan, "lua", "remove_room", self.token)

	skynet.send(".vfyproxy", "lua",	"removeRoomVfyService", self.token)
end

function m:stopCountDown()
	if self.hCountDown then
		Scheduler.unschedule(self.hCountDown)
		self.hCountDown = nil
	end
end

function m:startCountDown()
	if self.hCountDown then return end
	if self.roomInfo.status >= GMS_COUNTED then return end

	self.roomInfo.countDown = 60
	
	self.hCountDown = Scheduler.schedule( 100, function()
			self.roomInfo.countDown = self.roomInfo.countDown - 1 

			MsgCountDown.data["countDown"] = self.roomInfo.countDown
			self:broadcastMsg(ACT_CONTROL, MsgCountDown)

			if self.roomInfo.countDown <= 0 or self:checkAllHeroConfirm() then
				self:stopCountDown()

				self:setRoomStatus(GMS_COUNTED)
				self:assignDefaultProperty()
				MsgEnterCombat.data["roomInfo"] = self.roomInfo

				self.statModel:init()
				self:broadcastMsg(ACT_CONTROL, MsgEnterCombat)
			end
		end)

	--notify verify service
	skynet.send(".vfyproxy", "lua", "clearRoomInfo", self.token)
end

function m:assignDefaultProperty()
	--print("[room] 11")
	local members = self:members()
	for _, side in pairs(members) do 
		for _, seat in pairs(side) do 
			if seat ~= -1 and not seat.tid then
				-- print('room tid:', self.roomInfo.player_data.selected_car)
				seat.tid = self.roomInfo.player_data[seat.pid].selected_car
			end
		end
	end
end

function m:player_enter(pid, token, roomInfo, hGate, addr, port, sid, hAgent)
	print("[room] player enter room:", pid, token, hGate, addr, port, sid, hAgent)
	--Room initialized by player that enter room first

	print("[room] roominfo:",inspect(roomInfo))

	if not self.roomInfo then
		self.roomInfo = roomInfo

		self.token = self.token or token
		self:setRoomStatus(GMS_INITED)		
	end
	statsDB:gauge("room." .. self.token .. ".players", #(self.players), 1)

	local player = self.players[pid]
	if not player 
		then player = {} 
	else
		--Tell gate to destroy old client instance if player online
		if player.status == STATUS_ONLINE then
			self.broadcaster:resetSendStatus(player)
			--skynet.send( player.hGate, "lua", "client_udpated", player.addr, player.port)
		end
	end

	--Player info can be updated by reconnect
	player.pid = pid
	player.token = token
	player.hGate = hGate
	player.hAgent = hAgent
	player.addr = addr
	player.port = port
	player.sid = sid
	player.status = STATUS_ONLINE

	if self.roomInfo.status >= GMS_STARTED then 
		self.statModel:re_enter(pid, player)
	end
	

	self.players[pid] = player
	self.sids[sid] = pid

	self:startCountDown()
	self:stopCheckAllLeft()
	self:notifyOnlinePeers()
	return self.roomInfo
end

function m:pushInput(msg)
	self.inputFrmLine:pushInput(msg)
end

function m:frmLstAck(msg)
	local frmIndex = msg.frmIndex
	self.inputFrmLine:frmLstAck(frmIndex)
end

function m:player_disconnect(hGate, addr, port, sid)
	local pid = self.sids[sid]
	print("[room] player disconnect:", hGate, addr, port, sid, pid)
	local player = nil
	if not pid then
		return 
	end
		
	player =  self.players[pid]
	player.status = STATUS_OFFLINE

	self.statModel:player_offline(pid)

	self.broadcaster:resetSendStatus(player)
	self:notifyOnlinePeers()
	
	--If all offline should start check time to keep room exist for a while
	local allLeft = self:checkAllLeft()
	
	--If someone offline, we should check whether all online players have been ready
	--if all ready should start combat or else continue waiting
	if not allLeft then
		self:checkLoadingReady()
	end

	statsDB:increment("exit_room")
	statsDB:gauge("room." .. self.token .. ".players", #(self.players), 1)
	return true
end

function m:roomDesp()
	return "room."
end

function m:members()
	return self.roomInfo["members"]
end

function m:notifyOnlinePeers()
	for k, v in pairs(OnlinePeers) do
    OnlinePeers[k] = nil
  end

	local empty = true
	for _,side in pairs(self:members()) do 
		for _, seat in pairs(side) do 
			if seat ~= -1 and seat.status == STATUS_ONLINE then
				empty = false
				table.insert(OnlinePeers, seat['pid'])
			end
		end
	end

	if empty then return end

	self:broadcastMsg(ACT_CONTROL, MsgOnlinePeers)

end

function m:stopCheckAllLeft()
	if self.hAllLeft then
		print("[room] stop check all left")
		Scheduler.unschedule(self.hAllLeft)
		self.hAllLeft = nil
	end
end

function m:checkAllLeft(destroy)
	self:stopCheckAllLeft()

	local allLeft = true
	for i,v in pairs(self.players) do 
		if v.status == STATUS_ONLINE then
			allLeft = false
		end
	end

	if allLeft then
		if destroy then
			print("[room] destroy room!!!")
			self:destroy()
			return
		end

		self.hAllLeft = Scheduler.schedule(ROOM_KEEP_TIME, function()
				print("[room] do check all left")
				self:checkAllLeft(true)
			end)
		print("[room] start check all left colck:", self.hAllLeft)
	end
	return allLeft
end

function m:message(buf, sz)
	local cmd, i = string.unpack(">B", buf)
	--print("[room] combat room unpack cmd:", cmd, i, sz)
	assert(cmd > 1)

	local data = string.sub(buf, i, sz)

	local msg = data
	if cmd ~= 3 then
		msg = UdpEncoding.decode(msg)
	end

    -- print("[room] Room msg", cmd, inspect(msg))
	local handler = Dispatcher.handlers[cmd]
	assert(handler)
	local ok, err = pcall(handler, self, msg)
	if not ok then print(err) end
	return ok
end

function m:checkAllHeroConfirm()
	local members = self:members()
	for _, side in pairs(members) do 
		for _, seat in pairs(side) do 
			if seat ~= -1 and not seat.tid then
				return false
			end
		end
	end
	return true
end

function m:on_rcv_sync_frame(action)
	local startFrame = action.data.startFrame
	local pid = action.sender
	local player = self.players[pid]
	if not player then return end

	self.broadcaster:startBatchSend(player, startFrame)
end


function m:on_rcv_hero_selected(action)
	local tid = action.data.tid
	local pid = action.data.pid
	local schemeID = action.data.schemeID

	local members = self:members()
	for _, side in pairs(members) do 
		for _, seat in pairs(side) do 
			if seat ~= -1 and seat.pid == pid then
				seat.tid = tid
			end
		end
	end

	--Sync player data to room info
	local token = self.roomInfo.id
	local combatInfo = RedisHelper.hget(COMBAT_INFO_KEY, token)
	if combatInfo then
		combatInfo = cjson.decode(combatInfo)

		self.roomInfo.player_data = combatInfo.room_info.player_data
	end
	
	-- Return room info to all peers
	action.data.roomInfo = self.roomInfo
end

function m:checkLoadingReady()
	if self.roomInfo.status ~= GMS_COUNTED then
		return 
	end

	--Check all online player's ready status
	local allReady = true
	for _,side in pairs(self:members()) do 
		for _, seat in pairs(side) do 
			if seat ~= -1 then
				local pid = seat['pid']
				local player = self.players[pid]

				--print("<<<< seat:",inspect(seat))
				--print("<<<< player:",inspect(player))

				if ( player and player["status"] == STATUS_ONLINE ) and
					not seat['loadingReady'] then
				--	print("seat:",inspect(seat))
				--	print("player:",inspect(player))
					print("[room] player not ready:", pid)
					allReady = false
					break
				end
			end
		end
	end

	print("[room] all ready:", allReady)
	if allReady then
		self:broadcastMsg(ACT_CONTROL, MsgGameStart)

		self.inputFrmLine:start()
		self:setRoomStatus(GMS_STARTED)
	end
end

function m:on_rcv_player_ready(action)
	local pid = action.sender
--	print("<<<< members:",inspect(self:members()))
	for _,side in pairs(self:members()) do 
		for _, seat in pairs(side) do 
			if seat ~= -1 and seat['pid'] == pid then 
				seat['loadingReady'] = true
				break
			end
		end
	end

	self:checkLoadingReady()
end

function m:get_combatStat()
	local resdata = self.statModel:resolve_combatstat()
	if resdata then 
		-- self:broadcastMsg(ACT_CONTROL, resdata)
	end

	local jsStat = cjson.encode(resdata)
	self:eachPlayer(function(player)
			print("save stat:", player.pid, tostring(player.pid), inspect(stat))
			local key = string.format(COMBAT_DATA_KEY, player.pid)
			RedisHelper.set(key, jsStat)
		end)
	self.stat_saved = true
end

function m:on_rcv_upload_stat(action)
	print("on_rcv_upload_stat", inspect(action))

	self.statModel:modify_totaldata(action.sender, action)	

	

	if true then return end

	if self.stat_saved then return end

	local stat = action.data.stat
	local jsStat = cjson.encode(stat)
	self:eachPlayer(function(player)
			print("save stat:", player.pid, tostring(player.pid), inspect(stat))
			local key = string.format(COMBAT_DATA_KEY, player.pid)
			RedisHelper.set(key, jsStat)
		end)
	self.stat_saved = true

	Scheduler.performWithDelay(300, function()
			self:destroy()
		end)
end

function m:on_rcv_combat_detail(action)
	print("on_rcv_combat_detail", inspect(action))
	self.statModel:modify_playerdata(action.sender, action.data)	
end

function m:broadcastMsg(cmd, msg)
	for pid, player in pairs(self.players) do 
		if player.status == STATUS_ONLINE then
			self:sendClientMsg(player, cmd, msg)
		end
	end
end

function m:eachPlayer(func)
	if not func then return end
	for _, player in pairs(self.players) do 
		func(player)
	end
end

function m:eachOnlinePlayer(func)
	if not func then return end
	for _, player in pairs(self.players) do 
		if player.status == STATUS_ONLINE then
			func(player)
		end
	end
end

function m:getClientAgent(addr, port)
	local serviceIndex = socket.udp_getserviceindex(addr, port, self.agentinfo.count)+1
	local agent = self.agentinfo.list[serviceIndex]
	return agent
end

function m:sendClientMsg(player, cmd, msg)
	local data = UdpEncoding.encode(msg)
	--[[
	local agent = self:getClientAgent(player.addr, player.port)
	local clientid = player.addr..":"..tostring(player.port)

	if agent then
		skynet.send(agent, "lua", "kcpSendBuf", clientid, cmd, data)
		return
	end--]]

	if player.hAgent then
		skynet.send(player.hAgent, "lua", "kcpSendBuf", cmd, data)
		return
	end

	--skynet.send(player.hGate, "lua", "send_client_msg", player.addr, player.port, player.sid, cmd, data) 
end

function m:sendClientMsg_byid(pid, cmd, msg)
	local player = self.players[pid]
	if not player then return end

	if player.status == 1 then 
		self:sendClientMsg(player, cmd, msg)
	end
end


			







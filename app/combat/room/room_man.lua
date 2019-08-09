local queue = require "skynet.queue"
local cs = queue()  

class("RoomManager", function(self) 
		self.combats = {} 						-- token => combatInfo
		self.hChecker = nil
		self.interval = 60 * 100 			-- check clear per 60s
		self.timeout = 60 * 60 * 100 	-- clear room that exist more than 1 hour
		self.roomcount = 0
		self.combat_info_key = "{combat}{combat_srv_room_infos}"
		self.player_cur_room_key = "{combat}{player_cur_rooms}"
	end)

local m = RoomManager

function m:init()
	self:startClearRoom()
end

function m:exit()
	self:stopClearRoom()
end

function m:start(hMaintain)
	RedisHelper.start()
	return true
end

local function cs_get_room(rm, pid, token, entered, roomInfo)
	print("[room_man] get_room: ", pid, token, inspect(rm.combats))
	if not token or not pid then
		skynet.error("[room_man] get room invalide args pid:", pid, " token:", token)
		return -1
	end

	local hRoom = nil
	local combatInfo = rm.combats[token]

	if combatInfo then
		hRoom = combatInfo.handler
	else
		if entered then
			-- Already entered sometime, but now room not exist.
			-- therefore, return -1 to tell client that room was not exist
			return -1
		else
			hRoom = skynet.newservice("combat_room", token)
			print("[room_man] I [", pid, ']create room room:', hRoom)
			rm.combats[token] = { handler 	= hRoom, 
														timestamp = skynet.now(), 
														creator 	= pid, 
														roomInfo	= roomInfo} 

			rm.roomcount = rm.roomcount + 1
			
		end
	end

	return hRoom
end

function m:get_room(pid, token, entered, roomInfo)
	return cs(cs_get_room, self, pid, token, entered, roomInfo)
end

local RM_PLAYER_CUR_COOMBAT = [[
  	local playerKey 	= unpack(KEYS)
  	local token, pid 	= unpack(ARGV)
  	
  	local jsonData = redis.call('hget', playerKey, pid)
  	if not jsonData then return end

  	local data 		 = cjson.decode(jsonData)
  	if not data then return end

  	if data.token ~= token then return end

  	redis.call('hdel', playerKey, pid)
  ]]
function m:remove_room(token)
	if not token then 
		return 
	end

	--Remove server room info and player current room info
	local ci = self.combats[token]
	if not ci then return end
	
	local ri = ci.roomInfo
	RedisHelper.hdel(self.combat_info_key, token)

	for _, side in pairs(ri.members) do 
		for _, seat in pairs(side) do
			if seat ~= -1 then
				local pid = tostring(seat.pid)
				print("[room_man] remove user combat info:", pid, token)
				-- RedisHelper.hdel(self.player_cur_room_key, pid)
				RedisHelper.eval(	RM_PLAYER_CUR_COOMBAT, {self.player_cur_room_key}, {token, pid})
			end
		end
	end

	self.hMaintain = self.hMaintain or skynet.queryservice("maintain")
	print("[room_man] send maintain releasePayload")
	skynet.send(self.hMaintain, "lua", "releasePayload", token)

	print("[room_man] remove room:", token)
	self.combats[token] = nil

	self.roomcount = self.roomcount - 1
	statsDB:gauge("RoomManager.Rooms", self.roomcount, 1)
end

function m:checkClearPeriodic()
	local now = skynet.now()
	local toRomove = {}
	for k, v in pairs(self.combats) do 
		local elapse = now - v.timestamp
		if elapse >= self.timeout then
			table.insert(toRomove, k)
		end
	end

	for _,v in pairs(toRomove) do 
		print("[room_man] remove room timeout:", v)
		self.roomcount = self.roomcount - 1
		self.combats[v] = nil
	end

	statsDB:gauge("RoomManager.Rooms", self.roomcount, 1)

	skynet.send(".maintain", "lua", "setRoomCount", self.roomcount)
end

function m:startClearRoom()
	self:stopClearRoom()
	self.hChecker = Scheduler.schedule(self.interval, function()
			self:checkClearPeriodic()
		end)
end

function m:stopClearRoom()
	if self.hChecker then
		Scheduler.unschedule(self.hChecker)
		self.hChecker = nil
	end
end


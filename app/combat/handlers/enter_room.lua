local cjson = require "cjson"
--[[
About combat information, plz refer to combat_room.rb start_combat 
Combat information => {
    :ip => ip,
    :port => port,
    :token => id,
    :room_info => room_info.to_hash
}

Logic about combat information
1 data server 	: start_combat => write player combat info
2 combat server	: enter_room => read player combat info => get create room => ok 		=> sign as entered => update player combat info
																																					 => fail 	=> remove player combat info
3 combat server : combat finish => remove player combat info
]]

local hroomMan = nil
local combat_info_key 		= "{combat}{combat_srv_room_infos}"
local player_cur_room_key	= "{combat}{player_cur_rooms}"

local function do_loadtest(client, msg)
	if msg["loadtest"] == nil then return false end

	local pid 	= msg["pid"]
	local token = msg["token"]
	local roomInfo = msg["roomInfo"]

	hroomMan = hroomMan or skynet.queryservice("room_man_service")
	local hRoom = skynet.call(hroomMan, "lua", "get_room", pid, token, false, roomInfo)
	if not hRoom or hRoom == -1 then
		return true
	end

	client:setRoom(hRoom)

	local roomInfo = skynet.call(hRoom, "lua", "player_enter", pid, token, roomInfo, client:getGate(), client.addr, client.port, client.sid, skynet.self())
	print("[gate] player enter room ", inspect(roomInfo))

	client:kcpSend(1, roomInfo)

	return true
end

return function(client, msg)
	if do_loadtest(client, msg) then return end

	local pid 	= msg["pid"]
	local token = msg["token"]

	--Get player combat info  from redis db
	curRoomInfo = RedisHelper.hget(player_cur_room_key, pid)
	if not curRoomInfo then
		print("[gate] Cutoff client as player current room information not exist")
		client:kcpSend(1, -1)
		client:cutOff()
		return
	end

	curRoomInfo = cjson.decode(curRoomInfo)
	if not curRoomInfo or curRoomInfo.token ~= token then
		print("[gate] Cutoff client as enter room arg token not same with user current room token")
		client:kcpSend(1, -1)
		client:cutOff()
		return
	end

	local combatInfo = RedisHelper.hget(combat_info_key, token)
	if not combatInfo or not combatInfo then
		print("[gate] Cutoff client as enter room but [combat info] not exist")
		client:kcpSend(1, -1)
		client:cutOff()
		return
	end


	combatInfo = cjson.decode(combatInfo)
	print("[gate] Got combat info:", inspect(combatInfo))


	local entered  = curRoomInfo.entered
	local roomInfo = combatInfo.room_info

	hroomMan = hroomMan or skynet.queryservice("room_man_service")
	print("queryservice: ", hroomMan)
	local hRoom = skynet.call(hroomMan, "lua", "get_room", pid, token, entered, roomInfo)
	print("[gate] Got hroom:", hRoom)
	if not hRoom or hRoom == -1 then
		print("[gate] Cutoff as enter room but [room handler] not exist")
		client:kcpSend(1, -1)
		client:cutOff()
		return
	end

	client:setRoom(hRoom)

	combatInfo = cjson.encode(combatInfo)
	RedisHelper.hset(combat_info_key, token, combatInfo)

	--Update as entered	
	curRoomInfo.entered = true
	curRoomInfo = cjson.encode(curRoomInfo)
	RedisHelper.hset(player_cur_room_key, pid, curRoomInfo)


	local roomInfo = skynet.call(hRoom, "lua", "player_enter", pid, token, roomInfo, client:getGate(), client.addr, client.port, client.sid, skynet.self())
	
	print("[gate] player enter room ", inspect(roomInfo))
	--Send client current room info
	client:kcpSend(1, roomInfo)

	statsDB:increment("enter_room")
end


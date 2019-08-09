
local CSC = 1
local SC 	= 2
local CS 	= 3
local CSS = 4


return function(room, msg)
	local cmd = msg['cmd']
	if not cmd then 
			skynet.error("cmd can not be null", inspect(msg))
		return 
	end

	local f = room['on_rcv_'..cmd]
	if f then
		local ok, err = pcall(f, room, msg)
		if not ok then
			skynet.error(err)
			return
		end
	end

	if msg['__mt__'] == CSS then
		if cmd ~= "upload_stat" then
			local pid = msg['sender']
			if not pid then return end
			local player = room.players[pid]
			if not player then return end
			if player.status == 1 then 
				room:sendClientMsg(player, 2, msg)
			end
		end
	else
		if msg['__mt__'] ~= CS then
			for i,player in pairs(room.players) do 
				if player.status == 1 then 
					room:sendClientMsg(player, 2, msg)
				end
			end
		end
	end
end
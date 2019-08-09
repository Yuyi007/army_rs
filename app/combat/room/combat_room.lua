package.path = package.path..";../../?.lua;"
skynet = require "skynet"
netpack = require "skynet.netpack"

require "inspect"
SCHEDULER_PRECISION = 1
require "winnie/winnie"
statsDB = require "statsd"
require "app/combat/gate/udpencoding"
require "app/combat/dispatcher"
require "app/combat/room/input_frame_line"
require "app/combat/room/frame_broadcaster"
require "app/combat/room/combat_statmodel"
require "app/combat/room/combat_statitem"
require "app/combat/room/room"

local room = nil
local activetick = skynet.now()

local function doCheck()
	print("doCheck",activetick,skynet.now())
	if room:inBattle() == true then
		--Must more than 35s, plz lookup ROOM_KEEP_TIME
		--Room has busniess to do after all left checked
		if  skynet.now() - activetick >= 45 * 100 then 
			print('room time out..')
			skynet.exit()
			return
		end
	else
		if  skynet.now() - activetick >= 5*6000 then
			print('room time out')
			skynet.exit()
			return
		end
	end

    local mem = math.floor(collectgarbage("count"))
    if mem > 10000 then
    	skynet.send(skynet.self(), "debug", "GC")
    	--collectgarbage("collect")
    end
 end

skynet.start(function()
	print("Service combat room start")
	room = Room.new()
	room:init()

	--local cnt = 0
	local hTimer = Scheduler.schedule(500, doCheck)

	  skynet.dispatch("lua", function(_,_, command, ...)
	  		activetick = skynet.now()

	        local f = room[command]
	        local ok, res = pcall(f, room, ...)
	        if ok then
	          skynet.ret(skynet.pack(res))
	        else
	        	skynet.error(msg)
	        	room:destroy()
	        end
	      end)
  end)

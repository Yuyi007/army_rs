package.path = package.path..";../../?.lua;"
skynet = require "skynet"
require "inspect"
SCHEDULER_PRECISION = 100
require "winnie/winnie"
statsDB = require "statsd"
require "app/combat/room/room_man"

local roomMan = nil

skynet.start(function()
		print("Service room manager start")
	  roomMan = RoomManager.new()
	  roomMan:init()

	  skynet.dispatch("lua", function(_,_, command, ...)
	        local f = roomMan[command]
	        print("[room service] command:", command)
	        local ok, res = pcall(f, roomMan, ...)
	        if ok then
	          skynet.ret(skynet.pack(res))
	        else
	        	skynet.error(res)
	        	roomMan:exit()
	        end
	      end)
  end)

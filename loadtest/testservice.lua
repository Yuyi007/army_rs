package.path = package.path..";../../?.lua;../../loadtest/?.lua;"
skynet 	= require "skynet"
require "inspect"
require "winnie/winnie"
socket 	= require "luasocket"
require "testclient"
local cjson = require "cjson"
lkcp 		= require "lkcp"
require "udpencoding"

local CMD = {}
local clients = {}
local opts = nil
local COMBAT_ROOMS_KEY = "{combat}{player_cur_rooms}"

local str = ""


function CMD.start(options)
	--RedisServicePool.init()
	--RedisHelper.start()
	Scheduler.start()

	opts = options
	print ("Test CombatServer: " .. options.host .. ":" .. tostring(options.port))
	


	if options["test_type"] == 0 then
		str = "conncount,connreqtime\n"

		for i=1,options.conncount do
			options.connectno = i
			options.roomno = 0
			clients[i] = testClient.new(options)

			clients[i]:init(i,0, options["beginuid"] +i, "test" .. tostring(i), function(loginfo)
				str = str .. loginfo .. "\n"
				skynet.error(loginfo)

				if i == options.conncount then
					local f = assert(io.open('testResult.txt','w'))
  				f:write(str)
  				f:close()
				end
			end)
		end
	else
		str = "roomcount,enterroomtime\n"

		for i=1,10*options.groupcount do
			options.connectno = i
			options.roomno = math.floor(i / 10.0)
			clients[i] = testClient.new(options)

			clients[i]:init(i,math.floor(i / 10.0),options["beginuid"] +i, "test" .. tostring(i), function(loginfo)
				str = str .. loginfo .. "\n"
				skynet.error(loginfo)

				if i >= 10*(options.groupcount-1) then
					local f = assert(io.open('testResult.txt','w'))
  				f:write(str)
  				f:close()
				end
			end)
		end
	end

	

	return true
end

function CMD.quit()
	RedisServicePool.exit()
	skynet.exit()
end

skynet.start(function()
	print("Test Service start......")

	skynet.dispatch("lua", function(_,_, command, ...)
        local f = CMD[command]
        local res = f(...)
        if res then
          skynet.ret(skynet.pack(res))
        end
      end) 
end)
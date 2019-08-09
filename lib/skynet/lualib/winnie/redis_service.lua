package.path = package.path..";../../?.lua;"
skynet = require "skynet"
netpack = require "skynet.netpack"
require "inspect"
SCHEDULER_PRECISION = -1
require "winnie/winnie"

local connection = nil

skynet.start(function()
	  print("Service redis start")
	  connection = RedisConnection.new()

	  skynet.dispatch("lua", function(_,_, command, ...)
      local f = connection[command]
      local ok, res = pcall(f, connection, ...)
      if ok then
        skynet.ret(skynet.pack(res))
      else
      	skynet.error(command, res)
      	connection:stop()
      end
    end)
  end)

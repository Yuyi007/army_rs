package.path = package.path..";./?.lua;"
skynet       = require "skynet"
require "winnie/winnie"

local function initDebugConsole()
  if (skynet.getenv("debug_console") == "true") then
   -- skynet.newservice("debug_console",8002)
  end
end

skynet.start(function()
		initDebugConsole()
		
		local port = tonumber(skynet.getenv("tcpport"))
		local addr = skynet.getenv("tcpaddr")
		
		local dt = skynet.uniqueservice("datacenter")
	  skynet.send(dt, "lua", "start", addr, port, mt)

	  skynet.exit()
  end)
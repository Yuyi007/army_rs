package.path = package.path..";./?.lua;"
skynet       = require "skynet"
require "winnie/winnie"

local function initGameConfig()
  GameConfig.load_all()
end

local function initDebugConsole()
  if (skynet.getenv("debug_console") == "true") then
    skynet.newservice("debug_console",9001)
  end
end

skynet.init(function()
		-- initGameConfig()
	end)

skynet.start(function()
	initDebugConsole()

	local port = skynet.getenv("udpport")
	local addr = skynet.getenv("udpaddr")
	print("Server started")
	skynet.syslog(5, "Server started", 1, 22, "test001")

	local mt = skynet.uniqueservice("maintain")
	skynet.call(mt, "lua", "start", addr, port)
	print("Maintain started")


	local rm =  skynet.uniqueservice("room_man_service") 
	skynet.call(rm, "lua", "start")
	print("Room manager started")


	if skynet.getenv("statsd_host") then 
		local stat = skynet.newservice("stat")
		skynet.send(stat, "lua", "init")
	end

	if skynet.getenv("verify_host") then 
		local vfy = skynet.newservice("vfyproxy")
		skynet.send(vfy, "lua", "init")
	end

--[[		local gate = skynet.newservice("udpgate")
	  skynet.call(gate, "lua", "start", addr, port)
	  print("Agents Watchdog listen on ", tostring(port))--]]

	  skynet.exit()
  end)
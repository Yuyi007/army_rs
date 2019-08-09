local skynet = require "skynet"
local socket = require "skynet.socket"
require "inspect"

local hRoom = nil
local function server()
	local host
	host = socket.udp(function(str, from)
		print("server recv111", str, socket.udp_address(from))
		--socket.sendto(host, from, "OK " .. str)
		local addr, port = socket.udp_address(from)
		--local fr = socket.udp_makeaddr(addr, port)
		--socket.sendto(host, fr, "OK " .. str)
		--skynet.call(hRoom, "lua", "onReceive", host, addr, port, str, '\n')



	end , "127.0.0.1", 7001)	-- bind an address
end



local c = nil
local sendPKG=0

local function sendhb()
	while(true) do
	for i=1,1000 do
		local sendPkg = string.pack(">H>B", 42789, 2);
		socket.write(c, sendPkg)

		sendPKG = sendPKG + 1
		print("####SEND PKG:", sendPKG)

		--print("@@@RECV PKG", rcc)
		--socket.write(c, "hello " .. i)	-- write to the address by udp_connect binding
		--print("send hello"..i)
	end
	skynet.sleep(50)
	end
end
local recvPKG = 0
local function client()
	c = socket.udp(function(data, size, from)
		local str = skynet.tostring(data,size)
		local _pid, _op, i = string.unpack(">H>B", str)
		print("client recv", str, socket.udp_address(from), _pid, _op, i)

		recvPKG = recvPKG + 1
		print("@@@@RECV PKG:", recvPKG)

		--local sendPkg = string.pack(">H>B", 42789, 2);
		--socket.write(c, sendPkg)
	end)

	socket.udp_connect(c, "127.0.0.1", 6668)
	
	local sendPkg = string.pack(">H>B", 42789, 1);
	socket.write(c, sendPkg)

	sendPKG = sendPKG + 1
	print("####SEND PKG:", sendPKG)
	
end

--[[local function tcpClient()
	local t = socket.open("127.0.0.1", 7668)
	socket.open(t,function(id, size, data)
		print("data:", id,size,data)
		-- body
	end)
end--]]

skynet.start(function()
	print(inspect(socket))

	--hRoom = skynet.newservice("testroom")
	--skynet.fork(server)
	-- skynet.fork(client)
	-- skynet.fork(tcpClient)

	skynet.sleep(100)
	
	--[[skynet.fork(function()
			local st, err = pcall(sendhb, c)
			if not st then
				skynet.error("send error:"..err)
			end
		end)--]]
	sendhb(c)
end)

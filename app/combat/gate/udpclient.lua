package.path = package.path..";./?.lua;"
skynet 	= require "skynet"
socket  = require "skynet.socket"

local queue = require "skynet.queue"
local cs = queue()  

local bInit = false

class("UdpClient", function(self) end)

local m = UdpClient
local HB_TIMEOUT = 15
local EMPTY_MSG = {}
local EMPTY_BUF = nil
function m:init(gate, sid, host)
	if self.bInit == true then return end
	
	self.bInit = true
--[[	self.addr = addr
	self.port = port
	self.sockaddr = socket.udp_makeaddr(self.addr, self.port)  --]]
	
	self.sid 	= sid
	self.pid = tonumber(skynet.getenv("udppid"))
	self.updatingKcp = false
	self.hTimeout = nil
	self.hUpdateKcp = nil
	self.hbTime = nil
	self.connected = false
	self.hRoom = nil
	--self.hGate = gate --skynet.self()
	self.udp = host
	self.kcp = nil

	self.sendbytes = 0
	self.recvbytes = 0
	self.sendbytesSum = 0
	self.recvbytesSum = 0

	self:initKcp()
	self:startKeepAlive()

	self.bInit = 1

	statsDB:increment("UdpClient.count")
	skynet.send(".maintain", "lua", "incConnection")
end

function m:setAddrInfo(addr, port)
	if self.addr == nil then
		self.addr = addr
		self.port = port
		self.sockaddr = socket.udp_makeaddr(self.addr, self.port)  
	end
end

function m:onRecycle()

end

function m:exit()
	self.udp = nil
	self.sid 	= nil
	self.hbTime = nil
	self.updatingKcp = false
	self.connected = false
	self.hRoom = nil	
	self.kcp = nil
	self:stopCheckTimeout()
	self:stopUpdateKcp()

	print("udp client disconnect so remove client:", self.addr, self.port)
	--skynet.send(self.hGate, "lua", "removeClient", self.addr, self.port)

	self.addr = nil
	self.port = nil
	self.sockaddr = nil
	self.hGate = nil
end

function m:resetKcp()
	self.hUpdateKcp = nil
	self.updatingKcp = false
	self.kcp = nil

	if self.connected == false then return end

	self:initKcp()
end

function m:sockSend(data)
	-- print("udpclient", self.sid, "send ",self.udp)

	local buf = string.pack(">H", self.pid)..data
	local len = string.len(buf)
	self.sendbytes = self.sendbytes + len
	--local from = socket.udp_makeaddr(self.addr, self.port)  
 	socket.sendto(self.udp, self.sockaddr, buf)
end

function m:updateNetBytes()
	skynet.send(".maintain", "lua", "incNetBytes", math.ceil(self.sendbytes/1024), math.ceil(self.recvbytes/1024))

	self.sendbytesSum = self.sendbytesSum + self.sendbytes
	self.recvbytesSum = self.recvbytesSum + self.recvbytes
	self.sendbytes = 0
	self.recvbytes = 0
end

function m:stopUpdateKcp()
	if self.hUpdateKcp then
		self.hUpdateKcp()
		self.hUpdateKcp = nil
	end
end
	
function m:updateKcp()
	local startTime = skynet.time()
	while true do 
		if not self.updatingKcp then
			break
		end

		local current = skynet.time()
		local elapse = math.floor(current - startTime)
		self.kcp:update(elapse)  

   	local len, buf = self.kcp:recv()
   	if not self.updatingKcp then
			break
		end
		if len > 0 then
		 	self:onKcpRecv(len, buf)
		end

    skynet.sleep(1)
	end	

	self:exit()
end

function m:initKcp()
	if self.sid  == nil then return end
	-- print("init kcp with session:", self.sid)
	while self.kcp == nil do
		self.kcp = lkcp.create(self.sid, function (buf) 
			-- print("kcp send to:", self.addr, self.port, ' len:', string.len(buf))
			local data = string.pack(">b", 3)..buf
			self:sockSend(data)
			-- print("kcp send ok")
		end)
		if self.kcp then break end

		skynet.sleep(50)
	end
	
	self.kcp:wndsize(200, 200)

	--启动快速模式
	--第二个参数 nodelay-启用以后若干常规加速将启动
	--第三个参数 interval为内部处理时钟，默认设置为 10ms
	--第四个参数 resend为快速重传指标，设置为2
	--第五个参数 为是否禁用常规流控，这里禁止
	self.kcp:nodelay(1, 10, 2, 1)

	self.hUpdateKcp = skynet.cancelable_fork(function()
			self.updatingKcp = true
			local st, err = pcall(self.updateKcp, self)
			if not st then
				skynet.error("update kcp error:"..err)
				--self:exit()
				self:resetKcp()
			end
		end)
end

function m:kcpSendBuf(cmd, buf)
	if not self.connected then return end

	--assert(self.connected)
	--assert(self.kcp)
	EMPTY_BUF = EMPTY_BUF or UdpEncoding.encode(EMPTY_MSG)
	buf = buf or EMPTY_BUF

	local data = string.pack(">B", cmd)..buf

	--[[data = string.pack(">b", 3)..data
	self:sockSend(data)--]]

	local si = self.kcp:send(data)
	if si < 0 then
		print("[gate] kcp send error ")
	end
	self.kcp:flush()
end

function m:kcpSend(cmd, msg)
	if not self.connected then return end

	--assert(self.connected)
	--assert(self.kcp)
	msg = msg or EMPTY_MSG
	print("[gate] kcp send to ", self.sid, cmd, inspect(msg))
	local data = UdpEncoding.encode(msg)
	data = string.pack(">B", cmd)..data

--[[	data = string.pack(">b", 3)..data
	self:sockSend(data)--]]

	local si = self.kcp:send(data)
	if si < 0 then
		print("[gate] kcp send error ")
	end
	self.kcp:flush()

	--statsDB:increment("KCPSend")
end

function m:setRoom(room)
	self.hRoom = room
end

function m:onKcpRecv(len, buf)
	if not self.connected then return end

	local cmd, i = string.unpack(">B", buf)
	-- print("[onKcpRecv] cmd:",cmd)
	if cmd == 1 then
		local data = string.sub(buf, i, len)
		local msg = UdpEncoding.decode(data)
		print("[onKcpRecv] cmd:",cmd, inspect(msg))

		local handler = Dispatcher.handlers[cmd]
		assert(handler)
		cs(handler, self, msg)
		handler(self, msg)
	else
		-- local data = string.sub(buf, i, len)
		-- local msg = UdpEncoding.decode(data)
		-- print('[onKcpRecv] msg:',inspect(msg))

		assert(self.hRoom) 
		skynet.send(self.hRoom, "lua", "message", buf, len)
	end
end


function m:onSockRcvHandShake()
	print("@@@@return sessionID:", self.sid)
	
	local data = string.pack(">B>I", 1, self.sid)
	self:sockSend(data)

	self.hbTime = skynet.now()
	if not self.connected then
		self:onConnect()
		self.connected = true
	end
end


function m:onSockRecvHeartBeat()
	self.hbTime = skynet.now()
	--send back hb
	local data = string.pack(">B>I", 2, self.sid)
	--print("udpclient send back heart beat")
	self:sockSend(data)
end

function m:onSockRecvKcp(buf)
	self.hbTime = skynet.now()
	if not self.connected then return end

	self.kcp:input(buf)
	--self:onKcpRecv(string.len(buf), buf)
end

function m:onSockRecvDD(str)
	--if not self.connected then return end

	local _pid, _op, i = string.unpack(">H>B", str)
	local len = string.len(str)
	self.recvbytes = self.recvbytes + len

  	local buf = string.sub(str, i, len)
  	self:onSockRecv(self.pid, _op, buf)
end

function m:onSockRecvD(data, size)
	--print("udpclient rawrecv ", data, size)
	local str = skynet.tostring(data, size)
	
	self:onSockRecvDD(str)
end

function m:onSockRecv(pid, op, buf)
	if self.connected == false and op ~= 1 then return end

	if op == 1 then	
		self:onSockRcvHandShake()
	elseif op == 2 then
		self:onSockRecvHeartBeat()
	elseif op == 3 then
		assert(self.kcp)
		self:onSockRecvKcp(buf)
	elseif op == 4 then --Client cutoff positive 
		print("[gate] receive cutoff msg")
		self:onDisconnect()
	else
		print("[gate] receive error operation code:", op)
	end
end

function m:stopCheckTimeout()
	print("[gate] stop checkTimeout,", self.hTimeout)
	if self.hTimeout then
		self.hTimeout()
		self.hTimeout = nil
	end
end

function m:getGate()
	return 0--self.hGate
end

function m:checkAlive()
	self:updateNetBytes()
	if self.hbTime == nil then return end

	local now = skynet.now()
	if (now - self.hbTime) > HB_TIMEOUT*100 then
		self:onDisconnect()
	end
end

function m:startKeepAlive()
	--check timeout per 5s
	self.hTimeout = skynet.cancelable_timeout(5*100, function()
			self:checkAlive()
			if self.connected then
				self:startKeepAlive()
			end
		end)
end

function m:onConnect()
	self.connected = true
end

function m:cutOff()
	self:onDisconnect()
end

function m:onDisconnect()
	if self.hRoom then
		skynet.send(self.hRoom, "lua", "player_disconnect", skynet.self(), self.addr, self.port, self.sid)
	end

	print("[gate] udp client disconnect so remove client:", addr, port)

	if isShareAgent == false then		
		--skynet.send(self.hGate, "lua", "removeClient", self.addr, self.port)
		skynet.send(".maintain", "lua", "decConnection")

		socket.udp_removesingleagent(self.addr, self.port)

		self.connected = false
		self:exit()

		collectgarbage("collect")
		skynet.exit()
		return
	end

	--self:onRecycle()
	self.connected = false
	self.updatingKcp = false

	-- statsDB:increment("exit_room")
end

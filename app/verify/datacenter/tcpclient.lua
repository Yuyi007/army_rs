class("TcpClient", function(self) end)

local m = TcpClient

local EMPTY_MSG = {}

function m:init(dcenter, idSock, _addr)
	self.datacenter = dcenter
	self.sock = idSock
	self.addr = _addr --clientip:port
	self.pid = tonumber(skynet.getenv("tcppid"))

	self.pkgindex = 0
	--statsDB:increment("TcpClient.count")
	
	self.roomServices = {}
end

function m:onRecycle()
	self.datacenter = nil
	self.sock = nil
	self.pid = nil
end

function m:updateRoomVfyService(token, serv)
	self.roomServices[token] = serv
end

function m:removeRoomVfyService(token)
	self.roomServices[token] = nil
end

function m:sockSendMsg(msg)
	local data = TcpEncoding.encode(msg)
	self:sockSend(data)
end

function m:sockSend(data)
	local buf = string.pack(">s2", data)

	print("tcpclient send data: ",string.len(data), "byte,", "sock", self.sock)	
 	socket.write(self.sock, buf)
end

function m:verification(token)
	local rm = self.roomServices[token]
	if rm then return rm end

	rm = skynet.call(self.datacenter, "lua", "getRoomVfyService", token)
	self.roomServices[token] = rm
	return rm
end

function m:onRecvData(msg)
	local cmd = tonumber(msg["cmd"])

	if cmd == 2000 then --Room Closed : removeRoomVfyService
		skynet.send(self.datacenter, "lua", "removeRoomVfyService", msg["token"])
	end

	if cmd == 1000 then -- Room Begin
		skynet.send(self.datacenter, "lua", "newRoomVfyService", msg["token"])
	end

	if cmd == 1001 then
		local rm = self:verification(msg["token"])
		if rm then
			skynet.send(rm, "lua", "frameCheck", msg)
		end
	end
end
	

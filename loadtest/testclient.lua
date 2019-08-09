

class("testClient", function(self, options)
	self.testconfig = options
	self.roomno = 0
	self.connectno = 0

	self.udpsock = socket.udp()
	self.udpsock:settimeout(0)
	self.hbTimer = nil
	self.hbTick = socket.gettime()
	self.beginTime = skynet.now()

	self.srvbeginUID = tonumber(skynet.getenv("beginuid"))

	self.kcp = nil
	self.updatingKcp = false
	self.hUpdateKcp = nil

	self.TEST_INTERVAL = 100

	self.sid = nil
	self.fTestLog = nil
	self.startTask = false

	self.uid = 0
	self.name = ""

	self.frmIndex = 0
	self.bGameStart = false

	self.enterroomTick = 0
	self.enterroomTime = 0

	self.connTick = 0
	self.connTime = 0
end)

local m = testClient
local HB_TIME = 50
local EMPTY_MSG = {}

function m:init(cno, rno, uid, name, TestLog)
	self.connectno = cno
	self.roomno = rno
	self.uid = uid
	self.name = name
	self.fTestLog = TestLog
	self:StartTest()
end

function m:getConnectTime()
	return self.connTime
end

function m:getEnterRoomTime()
	return self.enterroomTime
end

function m:restartKcp()
	if self.kcp then return end

	self:stopUpdateKcp()
	self:initKcp()

	if self.startTask == false then 
		
		if self.testconfig.test_type == 1 then
			self:enterroom()
		else

		end

		self.startTask = true
	end
end

function m:exit()
	self:stopUpdateKcp()
	self:StopHeartBeat()
end

function m:initKcp()
	print("init kcp with session:", self.sid)
	self.kcp = lkcp.create(self.sid, function (buf) 
			print(self:loginfo() .. "kcp send len:" .. string.len(buf))

			local data = string.pack(">H>B", self.testconfig.combat_pid, 3)..buf
			self.udpsock:sendto(data, self.testconfig.host, self.testconfig.port)
		end)
	
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
				skynet.error(self:loginfo() .. " update kcp error:"..err)
			end
		end)
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
		if len > 0 then
		 	self:onKcpRecv(len, buf)
		end

    skynet.sleep(0)
	end	
end

function m:kcpSend(cmd, msg)
	assert(self.kcp)

	msg = msg or EMPTY_MSG
	print(self:loginfo() .. "kcp send(session " ..  tostring(self.sid) .. ")", inspect(msg))

	local data = UdpEncoding.encode(msg)
	data = string.pack(">B", cmd)..data

--[[	 data = string.pack(">H>B", self.testconfig.combat_pid, 3)..data
			self.udpsock:sendto(data, self.testconfig.host, self.testconfig.port)--]]

	local si = self.kcp:send(data)
	if si < 0 then
		print(self:loginfo() .. "kcp send error ")
	end

	self.kcp:flush()
end

function m:onKcpRecv(len, buf)
	local cmd, i = string.unpack(">B", buf)
	local data = string.sub(buf, i, len)
	local msg = UdpEncoding.decode(data)

	print(self:loginfo() .. "kcp receive msg:", cmd, inspect(msg))

	if cmd == 1 then --enter room
		if self.enterroomTick > 0 then
			self.enterroomTime = socket.gettime() - self.enterroomTick
			if (self.fTestLog) and (self.testconfig.test_type == 1) then
				self.fTestLog(tostring(self.roomno) .. "," .. tostring(self.enterroomTime))

				--statsDB:gauge("RoomManager.CreateRoom", self.enterroomTime*100, 1)
			end
			self.enterroomTick = 0
		end
		--local handler = Dispatcher.handlers[cmd]
		--assert(handler)
		--cs(handler, self, msg)
		--handler(self, msg)

		--if msg.countDown == 60 then
			--self:sendHeroSelected()
		--end
	elseif cmd == 2 then
		if msg.cmd == "count_down" then
			--[[if msg.data.countDown == 57 then 
				self:sendHeroSelected() 
			end--]]

			if msg.data.countDown == 50 then self:sendPlayerready() end

		elseif msg.cmd == "hero_selected" then
			--self:sendLoadprogress(1.0)
			--self:sendPlayerready()
			--self:sendFrameIndex()
			--self:sendMovemsg()
		elseif msg.cmd == "enter_combat" then
			--self:sendFrameIndex()
			--self:sendMovemsg()
			--self.bGameStart = true
			--self:sendLoadprogress(1.0)
			--self:sendPlayerready()

			
			
		elseif msg.cmd == "game_start" then
			--for i=1,100 do
			--	self:sendMovemsg()
			--end
			skynet.fork(function()
				local i=0
				while true do

					--self:sendFrameIndex()
					--skynet.sleep(20)
					self:sendMovemsg()
					skynet.sleep(20)
					i=i+1
				end
				self:sendDisconnect()

				self:StartTest()
			end)
			--self:sendFrameIndex()
			--self:sendMovemsg()
			--self:sendFrameIndex()
			self.bGameStart = true
		end
		--we redirect messages to room service except enter room
		--assert(self.hRoom) 
		-- print("send to room cmd:", cmd)
		--skynet.send(self.hRoom, "lua", "message", buf, len)
		-- skynet.redirect(self.hRoom, self.hGate, "combat", self.sid, buf, len)
	end
end

function m:stopUpdateKcp()
	if self.hUpdateKcp then
		self.hUpdateKcp()
		self.hUpdateKcp = nil
	end
end

function m:loginfo()
	return "client-" .. tostring(self) .. "## "
end

function m:sendHandShake()
	self.bGameStart = false

	self.connTick = socket.gettime()

	local sendPkg = string.pack(">H>B", self.testconfig.combat_pid, 1);
  self.udpsock:sendto(sendPkg, self.testconfig.host, self.testconfig.port)
  print(self:loginfo() .. "sendHandShake:" .. tostring(self.testconfig.combat_pid) .. ":" .. tostring(self.testconfig.port) .." " .. sendPkg)

  self.hbTick = socket.gettime()
end

function m:sendHeartBeat()
	--if self.testconfig.test_type == 0 then return end

	local sendPkg = string.pack(">H>B", self.testconfig.combat_pid, 2);
  self.udpsock:sendto(sendPkg, self.testconfig.host, self.testconfig.port)

  print(self:loginfo() .. "sendHeartBeat")
end

function m:sendDisconnect()
	local sendPkg = string.pack(">H>B", self.testconfig.combat_pid, 4);
  self.udpsock:sendto(sendPkg, self.testconfig.host, self.testconfig.port)

  print(self:loginfo() .. "sendDisconnect")
end

function m:sendMovemsg()
	local movemsg = {
						__mt__ = 1,
						cmd = "move",
						data = {
								dir = {
										x = -15990,
										y = 0,
										z = 63555
									},
								lr = -1
							},
						sender = self.uid
					}

	self:kcpSend(3, movemsg)
end

function m:sendHeroSelected()
	local msg = {
		__mt__ = 1,
		cmd = "hero_selected",
		data = {
			tid = "car001",
			uid = self.uid
		},
		sender = "refree"
	}

	self:kcpSend(2, msg)
end


function m:sendLoadprogress(pct)
	local msg = {
  	__mt__ = 1,
  	cmd = "load_progress",
  	data = {
    	percent = pct,
    	uid = self.uid
  	},
  	sender = "refree"
	}

	self:kcpSend(2, msg)
end

function m:sendPlayerready()
	local msg = {
  	__mt__ = 1,
  	cmd = "player_ready",
  	data = {},
  	sender = self.uid
	}

	self:kcpSend(2, msg)
end

function m:sendFrameIndex()
	local msg = {
  	frmIndex = self.frmIndex
	}

	m:kcpSend(4, msg)
	self.frmIndex = self.frmIndex + 1
end

function m:StartTest()
  self:sendHandShake()

  self:doSockReceive()
end

function m:StartHeartBeat()
	self:StopHeartBeat()
	self.hbTick = socket.gettime()

	local function doHeartBeat()
		-- check Alive
		if socket.gettime() - self.hbTick >= 30 then
			--self:sendDisconnect()
			--skynet.sleep(10)
			--self:sendHandShake()
			--return
		end

		if skynet.now() - self.beginTime >= 1000 * 60 then
			--self.beginTime = skynet.now()
			--self:sendDisconnect()
			--self:exit()
		end

		if self.bGameStart == true then
			--self:sendMovemsg()
			--self:sendFrameIndex()
		end

		self.hbTick = socket.gettime()
		self:sendHeartBeat()
	end

	self.hbTimer = Scheduler.schedule(HB_TIME, doHeartBeat)
end

function m:StopHeartBeat()
	if not self.hbTimer then return end

	Scheduler.unschedule(self.hbTimer)
	self.hbTimer = nil
end 

function m:enterroom(msg)
	if self.sid == nil then return end
	local ctick = 100

	local t1,t2 = math.modf((self.uid - self.srvbeginUID-1) / 10)
	local beginID = self.srvbeginUID+1 + t1 * 10 

	if msg == nil then 
		msg = {
										loadtest = 1,
               			uid = self.uid,
               			token = "RID:1:".. beginID .. ":" .. tostring(ctick),
               			roomInfo = {
               							creator = beginID,
               							id = "RID:1:".. tostring(beginID) .. ":" .. tostring(ctick),
               							members = { 	
               										{ 
               											{
               												houseCreator = true,
               												name = "test001",
               												ready = true,
               												uid = beginID
               											}, 
               											{
               												houseCreator = false,
               												name = "test002",
               												ready = true,
               												uid = beginID+1
               											}, 
               											{
               												houseCreator = false,
               												name = "test003",
               												ready = true,
               												uid = beginID+2
               											}, 
               											{
               												houseCreator = false,
               												name = "test004",
               												ready = true,
               												uid = beginID+3
               											}, 
               											{
               												houseCreator = false,
               												name = "test005",
               												ready = true,
               												uid = beginID+4
               											} 
               										},
               										{ 
               									 		{
               									 			houseCreator = false,
               												name = "test006",
               												ready = true,
               												uid = beginID+5
               											}, 
               									 		{
               									 			houseCreator = false,
               												name = "test007",
               												ready = true,
               												uid = beginID+6
               											}, 
               									 		{
               									 			houseCreator = false,
               												name = "test008",
               												ready = true,
               												uid = beginID+7
               											}, 
               									 		{
               									 			houseCreator = false,
               												name = "test009",
               												ready = true,
               												uid = beginID+8
               											}, 
               									 		{
               									 			houseCreator = false,
               												name = "test010",
               												ready = true,
               												uid = beginID+9
               											} 
               										} 
               									},
               							time_stamp = os.time(),
               							type = 1
               						}             			
               		}
	end 

	assert(self.kcp)

	self.enterroomTick = socket.gettime()

	self:kcpSend(1, msg)

	self.frmIndex = 0
end

--[[
protocol[Hbs]:
-------------------------------------------
 		pid 				| 		op 				| data
     2                 2            *
-------------------------------------------
op: 1 handshake
		2 heartbeat
		3 package 
		4 reconnect
]]
function m:receive()
	
	local data, addr, port

	while true do
		data, addr, port = self.udpsock:receivefrom()

		if data then
			print(self:loginfo() .. "udp receive from :", addr, port)
			local len = string.len(data)

			if len < 3 then
				print(self:loginfo() .. "discard packet less than 3")
			else
				local _pid, _op, i = string.unpack(">H>B", data)
				local buf = string.sub(data, i, len)

				if _pid ~= self.testconfig.combat_pid then
					print(type(_pid), type(self.testconfig.combat_pid), self.testconfig.combat_pid - _pid)
					print(self:loginfo() .. "discard packet pid wrong self:", self.testconfig.combat_pid, "_pid:", _pid)
				else

					if _op == 1 then
						self.connTime = socket.gettime() - self.connTick
						local sid, i = string.unpack(">I", buf)

						self.sid = sid
						print(self:loginfo() .. "handshake ok, session ID:" .. tostring(self.sid))

						self:restartKcp()
						self:StartHeartBeat()

						if (self.fTestLog) and (self.testconfig.test_type == 0) then

							self.fTestLog(tostring(self.connectno) .. "," .. tostring(self.connTime))
						
							--statsDB:gauge("UdpSocket.ConnectTime", self.connTime*100, 1)
						end
						
					elseif _op == 2 then
						self.hbTick = socket.gettime()
						print(self:loginfo() .. "recv heartbeat pkg, current time: " .. tostring(self.hbTick))
					elseif _op == 3 then
						self.kcp:input(buf)
						--self:onKcpRecv(string.len(buf),buf)
					elseif _op == 4 then
						self:sendHandShake()
					end						
				end
			end
		else
			-- print("udp recv data nil msg:", msg)
		end

		skynet.sleep(0)
		socket.sleep(0.001)
	end
end

function m:doSockReceive()
	skynet.fork(function()
			local st, err =pcall(self.receive, self)
			if not st then
				skynet.error(self:loginfo() .. "socket receive error:"..err)
			end
		end)
end


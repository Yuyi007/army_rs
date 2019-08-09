local msgpack = _G['cmsgpack']

function CombatMessenger:constructByOptionsUDP(opts)
  self.udp = nil
  logd(">>>>>opts:%s", inspect(opts))
  self.addr = opts.ip or "127.0.0.1"
  -- self.addr = socket.dns.toip(self.addr)
  self.port = tonumber(opts.port) or 6668
  self.mtu = opts.mtu or 512
  self.pid = 42789 --protocol id unsigned short
  self.msger = nil
end

  -- local appid = 42789
  -- local addr  = "192.168.31.212"
  -- local port  = "6668"
  -- local rcKey = "!@#%$SFG2esxi09w&()^>?"
  -- local msger = lmessenger.create(appid, addr, port, rcKey)
  -- local h = scheduler.scheduleWithUpdate(function()
  --     local status = msger:checkStatus()
  --     logd("[cm] status:%s", tostring(status))
  --   end, 0.1)

function CombatMessenger:initSocket()
	local function updateMsger()
    if not self.msger then return end
		local status, d = self.msger:checkStatus()
		-- logd("[cm] status:%s d:%s", tostring(status), tostring(d))
		if status == 0 then --error
			local err = d
			logd("[cm] socket error:%s", tostring(err))
			self:signal("error"):fire(err)

		elseif status == 3 then --connected
			if self.lastStatus ~= status then
				logd("[cm] receive kcp connected ")
				self:signal("connected"):fire(self.reconnecting)
				self.lastStatus = status
			end

			local count = d 
			for i=1, count do 
				local cmd, len, data = self.msger:recvMsg()
				if cmd then
					-- logd("[cm] receive kcp msg cmd:%s ", tostring(cmd))
					self:onRecvKcpMsg(cmd, data)
				end
			end
		end 
	end
  logd("[create cm]")
	self.msger = lmessenger.create(self.pid, self.addr, self.port, CombatMsgEncoding.key, 
                                200, 200, 512, 1, 10, 2, 1) --sendWnd, recvWnd, mtu, nodelay, interval, resend, nc
	self.hMsgerUpdate = scheduler.scheduleWithUpdate(updateMsger, 0)
end

function CombatMessenger:isConnected()
  return self.msger ~= nil
end

function CombatMessenger:destroySocket()
	if not self.msger then return end

	self.msger:destroy()
  self.lastStatus = nil
	self.msger = nil
	if self.hMsgerUpdate then
		scheduler.unschedule(self.hMsgerUpdate)
		self.hMsgerUpdate = nil
	end
end

local EMPTY_MSG = {}
function CombatMessenger:kcpSend(cmd, msg)
	if not self.msger then return false end
	-- logd("[cm] send cmd:%s msg:%s", tostring(cmd), inspect(msg))
	msg = msg or EMPTY_MSG
	local data = cmsgpack.pack(msg)

	self.msger:sendMsg(cmd, data)

	return true
end

function CombatMessenger:onRecvKcpMsg(cmd, data)
	if cmd == 1 then --enter room success
		local msg = cmsgpack.unpack(data)
		logd("[cm] receive enter room msg:%s", inspect(msg))
		self:signal("room_enter"):fire(msg)
		
	elseif cmd == 2 then --不是同步的action就直接执行不进入同步模块
		local msg = cmsgpack.unpack(data)
		local action = ActionFactory.make()
    action:fromTable(msg)
    cc:dispatchAction(action)
    ActionFactory.recycle(action)
  
	elseif cmd == 3 then --frame sync action 
    cc:recordAction(data)
		local msg = cmsgpack.unpack(data)
	  -- logd("[cm] receive frame sync action:%s", inspect(msg[1]))
    cc.fs:addRecvedFrame(msg)

  elseif cmd == 4 then --batch frame sync actions
  	logd("[cm] receive batch frames")
  	local msg = cmsgpack.unpack(data)
    cc.fs:addRecvedBatchFrames(msg)

  end
end

function CombatMessenger:onreceiveActionList(frm, lst, sendAck)
  local actions = ActionFactory.makeList()
  if lst then
    for i,v in ipairs(lst) do 
      local act = CombatMsgEncoding.decode(v)
      table.insert(actions, act)
    end
  end
  cc:addInputFrms(frm, actions, sendAck)
end


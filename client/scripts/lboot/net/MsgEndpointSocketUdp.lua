-- MsgEndpointUdpConn.lua

--[[
  Udp connection
]]--

local table = table

function MsgEndpoint:initUdpConn()
  self.udp = nil
  self.mtu = 512

  logd('mp[%d]: init udp socket no. %d', self.id, self.id)
end

function MsgEndpoint:destroyUdpConn()
  if self.udp then
    self.udp:close()
    self.udp = nil
  end
  self:destroyKcp()
end

function MsgEndpoint:closeUdpConn()
  if self.udp then
    self.udp:close()
    self.udp = nil
    self:destroyKcp()
  end
end

function MsgEndpoint:connectUdp()
  local connMsg
  self.udp, connMsg = socket.getconn(self.host, 'udp')

  if self.udp ~= nil then
    logd('mp[%d]: udp socket created', self.id)
    self.udp:settimeout(0)
    return true
  else
    logd('mp[%d]: cannot create udp socket: %s', self.id, tostring(connMsg))
  end

  return false
end

function MsgEndpoint:setPeer(port)
  if not self.udp then return end

  if port == nil then
    logd('mp[%d]: udp disconnected', self.id)
    self.udp:setpeername('*')
    return false
  end

  local res, msg = self.udp:setpeername(self.host, port)

  if res == 1 then
    logd('mp[%d]: udp connected to %s:%d', self.id, self.host, port)
    self.udp:settimeout(0)
    return true
  else
    logd('mp[%d]: udp connect failed: %s', self.id, tostring(msg))
    return false
  end
end

-- use raw udp protocol to send
-- use this wisely for packets that do not need reliable transmit
function MsgEndpoint:sendUdp(data)
  if not self.kcpHandshakeOk then return end

  -- raw udp cannot send larger than mtu size
  local rawData = self.udpDataId .. data
  local rawDataLen = string.len(rawData)
  if rawDataLen > self.mtu then
    loge("mp[%d]: send with udp data=%d too large!", self.id, string.len(data))
    return nil, 'data_too_large'
  end

  local ok, err = self.udp:send(rawData)
  -- logd('mp[%d]: send with udp data=%d ok=%s err=%s', self.id,
  --   string.len(data), tostring(ok), tostring(err))
  return ok, err
end

-- use kcp protocol to send (reliable protocol over udp)
function MsgEndpoint:sendKcp(data)
  if not self.kcpHandshakeOk then return end

  -- logd('mp[%d]: send with kcp data=%d', self.id, string.len(data))
  self.kcp:send(self.kcpDataId .. data)
  self.kcp:flush()
  return 1
end

-- use kcp protocol to receive (reliable protocol over udp)
-- Do note that server always send with kcp to ensure reliable transmit
-- Server will never send a raw udp packet to client
function MsgEndpoint:receiveKcp(packet, recvSize)
  if not self.kcp then return end

  -- use kcp protocol
  local current = (engine.realtime() - self.kcpStartTime) * 1000
  -- logd('mp[%d]: update kcp current=%d', self.id, current)
  self.kcp:update(current)

  local dataNum = 0
  local data, err = self.udp:receive(recvSize)
  while data do
    dataNum = dataNum + 1
    self.kcp:input(data)
    -- logd('mp[%d]: receive kcp data=%d err=%s', self.id, string.len(data), tostring(err))
    data, err = self.udp:receive(recvSize)
  end

  if dataNum > 0 then
    local count, payload = self:kcpRecv()
    if count > 0 then
      local count, payload2 = self:kcpRecv()
      if count > 0 then
        local t = {payload, payload2}
        while true do
          count, payload = self:kcpRecv()
          if count > 0 then
            t[#t + 1] = payload
          else
            break
          end
        end
        return table.concat(t)
      else
        return payload
      end
    else
      return nil, 'timeout'
    end
  else
    return nil, err
  end
end

function MsgEndpoint:kcpRecv()
  local count, payload = self.kcp:recv()
  if payload == 'hskc' then
    logd('mp[%d]: kcp handshake response received', self.id)
    self.kcpHandshakeOkSignal:fire()
    return 0, nil
  else
    -- if count > 0 then
    --   logd('mp[%d]: kcp recv count=%d payload=%s', self.id, count, string.len(payload))
    -- end
    return count, payload
  end
end

-------------------
-- KCP protocol
-------------------

function MsgEndpoint:initKcp(id, key, port)
  local conv = bit.band(4294967295, id)
  logd('mp[%d]: init kcp id=%f conv=%d key=%d port=%d', self.id, id, conv, key, port)

  self.kcp = lkcp.create(conv, function (buf)
    -- logd('mp[%d]: lkcp output buf=%d, udp=%s', self.id, string.len(buf), tostring(self.udp))
    self.udp:send(buf)
  end)
  self.kcp:setmtu(self.mtu)
  self.kcp:nodelay(1, 10, 2, 1)

  local idHi = fixmath.int64_hi(id)
  local idLo = fixmath.int64_lo(id)
  if not isLittleEndian() then
    local temp = idHi; idHi = idLo; idLo = temp
  end
  local dataId = string.pack('>I>I>I', idHi, idLo, key)
  self.kcpDataId = 'kc' .. dataId
  self.udpDataId = 'ud' .. dataId
  logd('mp[%d]: kcp header=%s', self.id, self.kcpDataId:tohex())

  self.kcpStartTime = engine.realtime()
  self.kcpHandshakeOk = nil
  self.kcpHandshakeOkSignal = Signal.new()
  self.kcpPingHandle = nil

  self:setPeer(port)
end

function MsgEndpoint:destroyKcp()
  self.kcp = nil
  self.kcpDataId = nil
  self.udpDataId = nil
  self.kcpStartTime = nil
  self.kcpHandshakeOk = nil

  if self.kcpHandshakeOkSignal then
    self.kcpHandshakeOkSignal:clear()
    self.kcpHandshakeOkSignal = nil
  end

  if self.kcpPingHandle then
    scheduler.unschedule(self.kcpPingHandle)
    self.kcpPingHandle = nil
  end

  self:setPeer(nil)
end

function MsgEndpoint:isKcpInited()
  return self.kcp ~= nil
end

function MsgEndpoint:kcpHandshake(onComplete)
  self:kcpFinish()

  assert(self.kcp ~= nil)
  self.kcp:send('hs' .. self.kcpDataId)
  logd('mp[%d]: kcp handshake request sent', self.id)

  local h = {}
  h.handle = scheduler.performWithDelay(3.0, function ()
    if self.kcpHandshakeOkSignal then
      self.kcpHandshakeOkSignal:clear()
    end
    onComplete(false)
  end)

  self.kcpHandshakeOkSignal:addOnce(function ()
    if h.handle then
      scheduler.unschedule(h.handle)
      h.handle = nil
    end

    logd('mp[%d]: kcp handshake success', self.id)
    self.kcpHandshakeOk = true
    self.kcpPingHandle = scheduler.schedule(function ()
      -- logd('mp[%d]: kcp ping', self.id)
      self.kcp:send('pi' .. self.kcpDataId)
    end, 60)

    onComplete(true)
  end)
end

function MsgEndpoint:kcpFinish()
  if self.kcpHandshakeOk then
    logd('mp[%d]: kcp finish session', self.id)
    self.kcpHandshakeOk = nil
    self.kcpHandshakeOkSignal:clear()
  end

  if self.kcpPingHandle then
    scheduler.unschedule(self.kcpPingHandle)
    self.kcpPingHandle = nil
  end
end

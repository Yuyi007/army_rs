-- MsgEndpointSocket.lua

--[[
  Low level socket ops
  This is a socket implementation built with luasocket
  Combines usage of tcp and udp
  Note that send or receive both blocks the main thread
]]--

local RECV_CHUNK_SIZE = 81920
local string = string
local socket = require('lboot/net/socket/socket')
local floor = math.floor
local Packet = Packet
local engine = engine

function MsgEndpoint:initSocket(host, port)
  self:close()
  self:unscheduleReceive()

  self.host = host
  self.port = port
  logd(">>>>>>>host:%s",inspect(self.host))
  logd(">>>>>>>port:%s",inspect(self.port))
  self.connectTimeout = self.connectTimeout or 3.0
  self.sendTimeout = self.sendTimeout or 10.0

  -- This is the global poll timeout
  -- Each packets can have its own poll timeout value
  self.pollTimeout = self.pollTimeout or 60
  self.pollReceiveInterval = self.pollReceiveInterval or 0

  -- pre-allocated tables
  self.tcpOutTable = {}

  logd('mp[%d]: init socket no. %d', self.id, self.id)

  self:initTcpConn()
  self:initUdpConn()

  self:reinitCodecState()
  self:connect()
end

function MsgEndpoint:destroySocket()
  self:close()
  self:destroyCodecState()
  self:unscheduleReceive()

  self:destroyTcpConn()
  self:destroyUdpConn()
end

-- close the socket without flushing queue or firing signals
function MsgEndpoint:closeSocket()
  self:closeTcpConn()
  self:closeUdpConn()
end

function MsgEndpoint:close()
  if self.conn then
    self:signal('closing'):fire()

    -- flush pending requests to the server
    self:flushSendQueue(self.queueOptsNoMask)

    logd('mp[%d]: closing connection no. %d', self.id, self.id)

    self:closeTcpConn()
    self:closeUdpConn()

    if self:receiveQueueLength() > 0 then
      self:signal('cancelled'):fire()
      self:clearReceiveQueue()
    end

    self:unscheduleReceive()
    self:clearMessageSignals()
  end
end

function MsgEndpoint:connect()
  local success = self:connectTcp()

  if success then
    -- self:connectUdp()

    -- logd('mp[%d]: connected to %s:%d', self.id, self.host, self.port)

    self:scheduleReceive()
    self:clearMessageSignals()

    self:signal('connected'):fire()
  end
end

function MsgEndpoint:reconnect()
  logd('mp[%d]: reconnecting to %s:%d', self.id, self.host, self.port)

  self:signal('reconnect'):fire()

  self:initSocket(self.host, self.port)
end

function MsgEndpoint:isConnected()
  return self.conn ~= nil
end

function MsgEndpoint:onConnected(callBack)
  if self.conn ~= nil then
    if callBack then
      callBack()
    end
  else
    self:signal('connected'):addOnce(callBack)
  end
end

function MsgEndpoint:unscheduleReceive()
  -- logd("mp[%d]: unscheduleReceive handle=%s",
  --   self.id, tostring(self.handleReceive))

  if self.handleReceive then
    scheduler.unschedule(self.handleReceive)
    self.handleReceive = nil
  end
end

function MsgEndpoint:scheduleReceive()
  -- start polling for result
  self:unscheduleReceive()

  local packet = Packet.new()
  local calls = 0
  local maxCalls = self:timeoutToMaxCalls(self.pollTimeout)

  local function pollResult()
    if self:receiveQueueLength() > 0 then
      -- logd(">>>>>>>calls:"..inspect(calls))
      calls = calls + 1

      if not self.lastFlushOpts.silent then
        logd('mp[%d]: calls=%s', self.id, tostring(calls))
      end
    end

    local done, err = self:receivePacket(packet)
    -- logd('mp[%d] pollResult calls=%d done=%s err=%s time=%f', self.id,
    --   calls, tostring(done), tostring(err), engine.realtime())

    if done then
      -- logd('mp[%d]: received time=%f', self.id, engine.realtime())
      self:onPacketReceived(packet)
      packet:resetData()
      calls = 0
      pollResult()
    elseif err then
      if err == 'closed' then
        loge('mp[%d]: receivePacket error: closed', self.id)
        self:unscheduleReceive()
        self:onSocketClosed(packet.number, packet.type)
        self:clearReceiveQueue()
        packet:reset()
        calls = 0
      elseif err ~= 'timeout' then
        loge('mp[%d]: receivePacket error: %s', self.id, tostring(err))
        self:onSocketError(packet.number, packet.type)
        self:clearReceiveQueue()
        packet:reset()
        calls = 0
      else
        local timeout, timeoutPacket = self:leastPollTimeout()
        maxCalls = self:timeoutToMaxCalls(timeout)
        if calls > maxCalls and self:isBusy() then
          if timeoutPacket and timeoutPacket.onPollTimeout == 'ignore' then
            -- ignore this packet on polling timeout
            self:removeFromReceiveQueue(timeoutPacket.number)
            calls = 0
          elseif timeoutPacket and type(timeoutPacket.onPollTimeout) == 'function' then
            self:removeFromReceiveQueue(timeoutPacket.number)
            calls = 0
            timeoutPacket.onPollTimeout(timeoutPacket)
          else
            -- default timeout behaviour: close socket
            loge('mp[%d]: receivePacket error: timeout calls=%d', self.id, calls)
            -- loge('mp[%d]: timeout time=%f', self.id, engine.realtime())
            self:onSocketTimeout(packet.number, packet.type)
            self:clearReceiveQueue()
            packet:reset()
            calls = 0
          end
        end
      end
    else
      -- no data received and no error
    end
  end

  self.handleReceive = scheduler.schedule(function ()
    engine.beginSample('pollResult')

    pollResult()

    engine.endSample()
  end, self.pollReceiveInterval, false, true)

  -- logd("mp[%d]: scheduleReceive handle=%s",
  --   self.id, tostring(self.handleReceive))
end

function MsgEndpoint:timeoutToMaxCalls(timeout)
  return (self.pollReceiveInterval == 0) and
    floor(timeout * 30) or floor(timeout / self.pollReceiveInterval)
end

function MsgEndpoint:sendPackets(packets)
  if self.conn == nil then
    logd('mp[%d]: sendPackets error: not connected, conn is nil', self.id)
    return nil
  end

  local tcpOutTable = self.tcpOutTable
  for i = 1, #tcpOutTable do tcpOutTable[i] = nil end

  for i = 1, #packets do
    local p = packets[i]
    local data = p:generateEncode(nil, self.codecState)
    self:recordSent(data, p)

    -- logd('mp[%d]: sendPacket %s time=%f', self.id, p:toString(true), engine.realtime())

    if p.sockType == 'kcp' then
      local sent, err = self:sendKcp(data)
      if err then
        loge('mp[%d]: sendPackets kcp error: %s', self.id, tostring(err))
        return nil, err
      end
    elseif p.sockType == 'udp' then
      local sent, err = self:sendUdp(data)
      if err then
        loge('mp[%d]: sendPackets udp error: %s', self.id, tostring(err))
        return nil, err
      end
    else
      tcpOutTable[i] = data
    end
  end

  if #tcpOutTable > 0 then
    local allTcpData = table.concat(tcpOutTable)
    local sent, err = self:sendTcp(allTcpData)
    if err then
      logd('mp[%d]: sendPackets tcp error: %s', self.id, tostring(err))
      return nil, err
    end

    return sent, nil
  else
    return 1
  end
end

function MsgEndpoint:receivePacket(packet)
  if self.conn == nil then
    return nil, 'closed'
  end

  local data, partial, err
  local recvSize = RECV_CHUNK_SIZE

  if packet.part then
    local partialSize = string.len(packet.part)
    -- logd('mp[%d]: receivePacket tcp first partial=%d', self.id, partialSize)
    recvSize = recvSize + partialSize
    data, err, partial = self:receiveTcp(packet, recvSize)
  else
    -- logd('mp[%d]: receivePacket kcp first', self.id)
    data, err, partial = self:receiveKcp(packet, recvSize)
    if not data then
      data, err, partial = self:receiveTcp(packet, recvSize)
    end
  end

  if partial and string.len(partial) > 0 then
    if data then
      data = data .. partial
    else
      data = partial
    end
  end

  if data and string.len(data) > 0 then
    -- logd('mp[%d]: received len=%d %s', self.id, string.len(data), data:toHexString())
    
    local ok, err2 = pcall(Packet.parseDecode, packet, data, nil, self.codecState)
    -- logd(">>>receive ok:%s err2:%s", tostring(ok), tostring(err2))
    if ok == false and err2 then
      loge('mp[%d]: packet decode error %s', self.id, tostring(err2))
      return nil, err2
    elseif err2 then
      -- if packet.part and string.len(packet.part) > 0 then
      --   logd('mp[%d]: packet.part %s', self.id, packet.part:toHexString())
      -- end
      self:recordReceived(data, packet)
      return true
    else
      return nil, err
    end
  else
    return nil, err
  end
end

function MsgEndpoint:reinitCodecState(nonce, biNonce)
  logd('mp[%d]: reinitCodecState', self.id)
  self:destroyCodecState()
  self.codecState = ClientEncoding.createCodecState(nonce, false)
  -- logd(">>>init: nonce：%s ", inspect(nonce))
  return self.codecState
end

function MsgEndpoint:destroyCodecState()
  if self.codecState then
    ClientEncoding.destroyCodecState(self.codecState)
    self.codecState = nil
  end
end

-- MsgEndpointQueue.lua

--[[
  Message queue operations
]]--

local engine = engine

function MsgEndpoint:initQueue()
  self.sendQueue = {}     -- the send queue
  self.receiveQueue = {}  -- the receive queue
  self.resendQueue = {}   -- the resend queue
  self.number = 1         -- current packet sequence number
  self.lastFlushOpts = {} -- last flush options
  self.batchQueues = {}

  -- packet pool
  logd(">>>>>>>>>initQueue")
  self.sentPacketPool = Pool.new(function () return Packet.new() end,
    {tag = 'sentPacket', initSize = 1, maxSize = 64, objectMt = Packet})

  -- default option presets
  local pollTimeout = 60
  self.queueOptsNoMask = {pollTimeout = pollTimeout, noMask = false}
  self.queueOptsRecordRTT = {pollTimeout = pollTimeout, recordRTT = true, noMask = true}
  self.queueOptsFrequent = {pollTimeout = 8, silent = true, noMask = true, recordRTT = true}
  self.queueOptsResend = {pollTimeout = pollTimeout, resend = true}
  self.queueOptsDefault = self.queueOptsNoMask
  self.queueOptsHasMask = {pollTimeout = pollTimeout}
end

function MsgEndpoint:destroyQueue()
  if self.sendQueue then
    self:clearSendQueue()
  end
  if self.receiveQueue then
    self:clearReceiveQueue()
  end
  if self.resendQueue then
    self:clearResendQueue()
  end
end

local queueMsgComplete = function(msg)
  if msg.success == false then
    logd('mp[%d]: queueMsg: msg returned is not successful, this may cause BUGS !!!', mp.id)
  end
end

function MsgEndpoint:queueMsg(t, msg, onComplete, opts)
  opts = opts or self.queueOptsDefault

  if type(self.beforeSendMessage) == 'function' then
    self:beforeSendMessage(msg)
  end

  -- build packet
  local packet = self.sentPacketPool:borrow()
  packet.msg = msg
  packet.length = nil
  packet.number = self.number
  packet.type = t
  packet.encoding = opts.encoding or nil
  packet.format = opts.format
  packet.codecState = opts.codecState
  packet.sockType = opts.sockType
  packet.pollTimeout = opts.pollTimeout
  packet.onPollTimeout = opts.onPollTimeout

  -- logd('mp[%d] queuing packet=%s opts=%s', self.id, packet:toString(), peek(opts))

  if game.debug > 0 and not opts.silent then
    -- logd('mp[%d]: queueing %s', self.id, packet:toString())
  end

  -- invoke the callback with the predicted message
  -- at the same time send the request to the server
  local predictMessage = opts.predictMessage
  if type(predictMessage) == 'table' then
    if predictMessage.success ~= false then
      predictMessage.success = true
    end
    onComplete(predictMessage) -- call predicted return message

    packet.onComplete = queueMsgComplete
  else
    packet.onComplete = onComplete
  end

  local sendQueue = self.sendQueue
  sendQueue[#sendQueue + 1] = packet

  if opts.resend then
    local resendQueue = self.resendQueue
    logd('mp[%d]: add to resend queue: n=%d t=%d queue size=%d', self.id, packet.number, t, #resendQueue)
    resendQueue[#resendQueue + 1] = {packet.number, t, msg, onComplete, opts}

    if #resendQueue > 32 then
      loge('mp[%d] resend queue size %d too large! you should call clearResendQueue() sometimes', self.id, #resendQueue)
    end
  end

  self.number = self.number + 1
end

function MsgEndpoint:sendMsg(t, msg, onComplete, opts)
  logd("[MsgEndpointQueue] sendMsg:%s",t)
  self:queueMsg(t, msg, onComplete, opts)
  return self:flushSendQueue(opts)
end

-- flush queue, send all messages in the queue
function MsgEndpoint:flushSendQueue(opts)
  opts = opts or self.queueOptsDefault
  self.lastFlushOpts = opts
  local noMask = opts.noMask or false
  local delayBusy = opts.delayBusy or false
  local silent = opts.silent or false
  local recordRTT = opts.recordRTT or false

  local sendQueue = self.sendQueue
  if #sendQueue == 0 then
    return nil
  end

  if not self.allowSend then
    logd('mp[%d]: allowSend is false trace=%s', self.id, debug.traceback())
    self:handleSendDisallowed()
    return nil
  end

  if self.conn == nil then
    self:showHint('str_reconnecting')
    self:onSocketClosed(self.number, 'flush')
    return nil
  end

  if noMask ~= true and not game.terminating then
    self:showBusy(delayBusy)
  end

  for i = 1, #sendQueue do
    local packet = sendQueue[i]
    self:onPacketWillBeSent(packet)
  end

  -- send the packets
  local sent, err = self:sendPackets(sendQueue)

  if sent then
    local receiveQueue = self.receiveQueue
    for i = 1, #sendQueue do
      local packet = sendQueue[i]
      sendQueue[i] = nil

      packet.busy = (not noMask)
      packet.silent = silent
      packet.inQueueTime = engine.realtime()

      if recordRTT then
        packet.sendTime = packet.inQueueTime
      else
        packet.sendTime = nil
      end

      receiveQueue[#receiveQueue + 1] = packet

      if game.debug > 0 and not silent then
        logd("mp[%d]: send success sent=%d length=%d n=%d t=%d e=%d waiting=%s",
          self.id, sent, packet.length, packet.number, packet.type,
          packet.encoding, self:busyReceiveQueueStr())
      end
    end
  else
    self:onSocketError(0, 'flush')
  end

  return sent, err
end

function MsgEndpoint:onPacketWillBeSent(packet)
  local n = packet.number

  self:signal(n):clear()
  if type(packet.onComplete) == 'function' then
    -- logd('mp[%d]: signal added n=%d t=%d', self.id, n, packet.type)
    self:signal(n):addOnce(packet.onComplete)
    packet.onComplete = nil
  end
end

function MsgEndpoint:handleSendDisallowed()
  local sendQueue = self.sendQueue
  for i = 1, #sendQueue do
    local packet = sendQueue[i]
    sendQueue[i] = nil
    self.sentPacketPool:recycle(packet)
    self:deleteSignal(packet.number)
    logd('mp[%d]: clear sendQueue[%d] because allowSend is false: n=%d t=%d',
      self.id, i, packet.number, packet.type)
  end
end

function MsgEndpoint:onPacketReceived(packet)
  engine.beginSample('onPacketReceived')

  -- logd("mp[%d]: received response %s", self.id, packet:toString(true))
  if packet.number == 0 then
    -- a server push message
    self:onMessageReceived(packet.number, packet.type, packet.msg)
  else
    local inQueue, sentPacket, idx = self:inReceiveQueue(packet.number)
    if inQueue then
      -- a response message

      if game.debug > 0 and not sentPacket.silent then
        -- logd("mp[%d]: received response %s", self.id, packet:toString())
      end

      if sentPacket.sendTime then
        self:recordRTT(sentPacket.sendTime, sentPacket)
      end

      -- catch errors, ensure the buffer is valid
      --[[local status, err2 = pcall(function ()
        self:onMessageReceived(packet.number, packet.type, packet.msg)
      end)]]

      self:claimReceived(packet.number, idx)
      self:onMessageReceived(packet.number, packet.type, packet.msg)
    else
      -- an outdated response message
      logd('mp[%d]: discarding a outdated response, waiting=%s number=%d',
        self.id, self:receiveQueueStr(), packet.number)
    end
  end

  engine.endSample()
end

function MsgEndpoint:inReceiveQueue(n)
  local receiveQueue = self.receiveQueue
  for i = 1, #receiveQueue do
    local sentPacket = receiveQueue[i]
    if sentPacket.number == n then
      return true, sentPacket, i
    end
  end

  return false
end

function MsgEndpoint:claimReceived(n, index)
  local receiveQueue = self.receiveQueue
  if index then
    local sentPacket = receiveQueue[index]
    if sentPacket.number == n then
      table.remove(receiveQueue, index)
      self:cancelResendItem(n, sentPacket)
      self.sentPacketPool:recycle(sentPacket)
      return true
    end
  else
    for i = 1, #receiveQueue do
      local sentPacket = receiveQueue[i]
      if sentPacket.number == n then
        table.remove(receiveQueue, i)
        self:cancelResendItem(n, sentPacket)
        self.sentPacketPool:recycle(sentPacket)
        return true
      end
    end
  end

  self:cancelResendItem(n)
  return false
end

function MsgEndpoint:cancelResendItem(n, sentPacket)
  local resendQueue = self.resendQueue
  for i = #resendQueue, 1, -1 do
    local item = resendQueue[i]
    local n1, t, msg, callback = item[1], item[2], item[3], item[4]
    if n1 == n then
      logd('mp[%d]: resend item received n=%d t=%d', self.id, n, t)
      table.remove(resendQueue, i)
    elseif n1 > n and (sentPacket and sentPacket.msg == msg and sentPacket.onComplete == callback) then
      -- Actually it should never go here
      -- We only flushResendQueue when reconnected, and will never receive a message from the last connection
      logd('mp[%d]: received n=%d cancel following resend item n=%d t=%d', self.id, n, n1, t)
      self:signal(n1):clear()
      self:deleteSignal(n1)
      table.remove(resendQueue, i)
    end
  end
end

function MsgEndpoint:receiveQueueLength()
  return #self.receiveQueue
end

function MsgEndpoint:clearReceiveQueue()
  local receiveQueue = self.receiveQueue
  for i = 1, #receiveQueue do
    local sentPacket = receiveQueue[i]
    receiveQueue[i] = nil
    self.sentPacketPool:recycle(sentPacket)
    self:deleteSignal(sentPacket.number)
  end
end

-- remove unresponsive packets from receive queue, to avoid memory leaks
-- e.g. a lost udp packet should be deleted from the queue after max wait time
function MsgEndpoint:removeFromReceiveQueue(n)
  local receiveQueue = self.receiveQueue
  for i = #receiveQueue, 1, -1 do
    local sentPacket = receiveQueue[i]
    if sentPacket.number == n then
      logd('mp[%d]: removeFromReceiveQueue: i=%d %s',
        self.id, i, sentPacket:toString(true))
      table.remove(receiveQueue, i)
      self.sentPacketPool:recycle(sentPacket)
      self:deleteSignal(sentPacket.number)
      break
    end
  end
end

function MsgEndpoint:receiveQueueStr()
  local t = {}
  local receiveQueue = self.receiveQueue
  for i = 1, #receiveQueue do
    local sentPacket = receiveQueue[i]
    t[#t + 1] = string.format('%d-%d-%s', sentPacket.number,
      sentPacket.type, tostring(sentPacket.pollTimeout))
  end
  return string.format('[%s]', table.concat(t, ', '))
end

function MsgEndpoint:busyReceiveQueueStr()
  return string.format('[%s]', table.concat(self:busyPackets(), ', '))
end

function MsgEndpoint:clearSendQueue()
  local sendQueue = self.sendQueue
  for i = 1, #sendQueue do
    local packet = sendQueue[i]
    sendQueue[i] = nil
    self.sentPacketPool:recycle(packet)
    self:deleteSignal(packet.number)
  end
end

function MsgEndpoint:clearResendQueue()
  -- return if mp is not inited
  if self.id == -1 then
    logd('mp[%d]: clear resend queue but not inited!', self.id)
    return
  end

  local resendQueue = self.resendQueue
  logd('mp[%d]: clear resend queue size=%d', self.id, #resendQueue)

  for i = 1, #resendQueue do
    local item = resendQueue[i]
    resendQueue[i] = nil
  end
end

-- resend all items in the resend queue
--
-- NOTE: this function will not be called automatically
-- you need to call it by yourself at appropriate times
function MsgEndpoint:flushResendQueue(filter)
  local resendQueue = self.resendQueue
  logd('mp[%d]: flush resend queue size=%d', self.id, #resendQueue)

  local t = {}
  for i = 1, #resendQueue do
    t[i] = resendQueue[i]
    resendQueue[i] = nil
  end

  for i = 1, #t do
    local item = t[i]
    local flush = true
    if filter and not filter(item[1], item[2]) then
      flush = false
    end
    logd('mp[%d]: flush=%s resend queue item n=%d t=%d', self.id, tostring(flush), item[1], item[2])
    if flush then
      -- logd('mp[%d]: flush resend queue item opts=%s', self.id, peek(item[5]))
      self:queueMsg(item[2], item[3], item[4], item[5])
    end
  end
  return self:flushSendQueue()
end

function MsgEndpoint:busyPackets()
  local busyPackets = {}
  local receiveQueue = self.receiveQueue
  for i = 1, #receiveQueue do
    local sentPacket = receiveQueue[i]
    if self:isPacketBusy(sentPacket) then
      busyPackets[#busyPackets + 1] = sentPacket.number
    end
  end

  return busyPackets
end

function MsgEndpoint:isBusy()
  local receiveQueue = self.receiveQueue
  for i = 1, #receiveQueue do
    local sentPacket = receiveQueue[i]
    if self:isPacketBusy(sentPacket) then
      return true
    end
  end

  return false
end

function MsgEndpoint:isPacketBusy(packet)
  return (packet.busy or
    (packet.pollTimeout and packet.onPollTimeout ~= 'ignore'))
end

function MsgEndpoint:leastPollTimeout()
  local min = self.pollTimeout
  local minPacket = nil
  local receiveQueue = self.receiveQueue
  for i = 1, #receiveQueue do
    local sentPacket = receiveQueue[i]
    local pollTimeout = sentPacket.pollTimeout
    if pollTimeout and pollTimeout < min then
      min = pollTimeout
      minPacket = sentPacket
    end
  end
  return min, minPacket
end

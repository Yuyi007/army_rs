--[[
  MsgEndpoint - Handling network operations

  External interfaces:
    - MsgEndpoint:messageReceived(n, t, msg)    handle received messages
    - MsgEndpoint:beforeSendMessage(msg)        decorate messages before sending
    - MsgEndpointView                           implement serveral view-related methods

  External signals:
    - signal('init')           initing the MsgEndpoint object
    - signal('destroy')        destroying the MsgEndpoint object
    - signal('connected')      connection established
    - signal('reconnect')      reconnecting
    - signal('reconnected')    connection re-established
    - signal('message')        response received, params: n, t, msg
    - signal(number)           response with message number received
    - signal('cancelled')      requests were cancelled
    - signal('timeout')        requests were timed out
    - signal('closing')        before connection was (intentionally) closed
    - signal('closed')         connection was closed
    - signal('error')          there are errors sending or receiving messages
]]--

require 'lboot/net/ClientEncoding'
require 'lboot/net/socket/socket'
require 'lboot/lib/Signal'

local engine = engine

MsgEndpoint = class("MsgEndpoint", function (self, options)
  self.options = table.merge({
    showReconnectMask = true, -- 是否显示重连画面
  }, options)

  self.signals = {}
  self.id = -1 -- mark -1 as a uninited instance
  self.allowSend = true -- only send packets when allowSend is true

  -- pre-allocated signal pool
  self.signalPool = Pool.new(function () return Signal.new() end,
    {tag = 'mpSignals', initSize = 1, maxSize = 128, objectMt = Signal})
end)

require 'lboot/net/MsgEndpointSocket'
require 'lboot/net/MsgEndpointSocketTcp'
require 'lboot/net/MsgEndpointSocketUdp'
require 'lboot/net/MsgEndpointReconnect'
require 'lboot/net/MsgEndpointQueue'
require 'lboot/net/MsgEndpointResolv'
require 'lboot/net/MsgEndpointRTT'
require 'lboot/net/MsgEndpointStats'
require 'lboot/net/MsgEndpointView'

function MsgEndpoint:init(host, port)
  if MsgEndpoint.connectionId then
    MsgEndpoint.connectionId = MsgEndpoint.connectionId + 1
  else
    MsgEndpoint.connectionId = 1
  end

  self.id = MsgEndpoint.connectionId

  logd('mp[%d]: init', self.id)

  self:signal('init'):fire()

  self:initView()
  self:initRTT()
  self:initStats()
  self:initSocket(host, port)
  self:initReconnect()
  self:initQueue()
end

function MsgEndpoint:destroy()
  logd('mp[%d]: destroy connection', self.id)

  self:signal('destroy'):fire()
  self:clearSignals()

  self:destroyQueue()
  self:destroyReconnect()
  self:destroySocket()
  self:destroyStats()
  self:destroyRTT()
  self:destroyView()
end

function MsgEndpoint:onMessageReceived(n, t, msg)
  engine.beginSample('onMessageReceived')

  -- logd("[message] received: n:%s t:%s msg:%s", tostring(n), tostring(t), tostring(msg))
  self:signal('message'):fire(n, t, msg)

  if n > 0 then
    self:onResponseMessageReceived(n, t, msg)
  end

  self:signal('post_message'):fire(n, t, msg)

  -- after json decode since that can be slow
  -- after signal handlers since that can be time consuming too (loading, errors etc.)
  if not self:isBusy() then
    -- only hide busy when there is no unacknowledged request
    -- (since signal handlers could send other requests)
    self:hideBusy()
  end

  engine.endSample()
end

function MsgEndpoint:onResponseMessageReceived(n, t, msg)
  engine.beginSample('onResponseMessageReceived')

  -- logd('mp[%d]: response received: number=%d msg=%s', self.id, n, tostring(msg))
  self:signal(n):fire(msg, n, t)
  self:deleteSignal(n)

  engine.endSample()
end

function MsgEndpoint:onSocketClosed(n, t)
  logd('mp[%d]: !!!!!!!!!!!!!!!!!!!!!!!!!! onSocketClosed: %s %s %s',
    self.id, self:receiveQueueStr(), tostring(n), tostring(t))

  self:clearSendQueue()
  self:clearReceiveQueue()
  self:hideBusy()
  self:closeSocket()

  self:signal('closed'):fire(n, t)
  self:signal('cancelled'):fire(n, t)
end

function MsgEndpoint:onSocketError(n, t)
  logd('mp[%d]: !!!!!!!!!!!!!!!!!!!!!!!!!! onSocketError: %s %s %s',
    self.id, self:receiveQueueStr(), tostring(n), tostring(t))

  self:clearSendQueue()
  self:clearReceiveQueue()
  self:hideBusy()
  self:closeSocket()

  self:signal('error'):fire(n, t)
  self:signal('cancelled'):fire(n, t)
end

function MsgEndpoint:onSocketTimeout(n, t)
  logd('mp[%d]: !!!!!!!!!!!!!!!!!!!!!!!!!! onSocketTimeout: %s %s %s',
    self.id, self:receiveQueueStr(), tostring(n), tostring(t))

  self:clearSendQueue()
  self:clearReceiveQueue()
  self:hideBusy()
  self:closeSocket()

  self:signal('timeout'):fire(n, t)
  self:signal('cancelled'):fire(n, t)
end

function MsgEndpoint:signal(t)
  local signal = self.signals[t]
  if not signal then
    signal = self.signalPool:borrow()
    self.signals[t] = signal
  end
  return signal
end

function MsgEndpoint:deleteSignal(t)
  local signal = self.signals[t]
  if signal then
    signal:clear()
    self.signalPool:recycle(signal)
    self.signals[t] = nil
  end
end

function MsgEndpoint:clearSignals()
  for k, signal in pairs(self.signals) do
    signal:clear()
    self.signalPool:recycle(signal)
    self.signals[k] = nil
  end
end

function MsgEndpoint:clearMessageSignals()
  for k, signal in pairs(self.signals) do
    if type(k) == 'number' then
      signal:clear()
      self.signalPool:recycle(signal)
      self.signals[k] = nil
    end
  end
end

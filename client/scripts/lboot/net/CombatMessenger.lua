--[[
 CombatMessenger - Handling network operations with combat server
 External signals:
  signal('init')          when object was initialize success
  signal('destroy')       when object was destroy
  signal('connected')     when kcp initialized which means udp connection established
  signal('error')         when error occured
  singal('message')       
]]
require "lboot/lib/Signal"
require "lboot/net/socket/socket"

local engine = engine
class("CombatMessenger", function (self, opts)
  self.id = -1 -- -1 means uninited instance
  self:constructSignals()
  self:constructByOptionsUDP(opts)
end)

require "lboot/net/CombatMsgEncoding"
require "lboot/net/CombatMessengerSocket"
require "lboot/net/CombatMessengerReconnect"

function CombatMessenger:constructSignals()
  self.signals = {}
  local opts =  {tag = 'mpSignals', initSize = 1, maxSize = 32, objectMt = Signal}
  self.signalPool = Pool.new(function () return Signal.new() end, opts)
end

function CombatMessenger:signal(t)
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

function CombatMessenger:clearSignals()
  for k, signal in pairs(self.signals) do
    signal:clear()
    self.signalPool:recycle(signal)
    self.signals[k] = nil
  end
end

function CombatMessenger:initID()
  if CombatMessenger.connectionId then
    CombatMessenger.connectionId = CombatMessenger.connectionId + 1
  else
    CombatMessenger.connectionId = 1
  end
  self.id = CombatMessenger.connectionId
end

function CombatMessenger:init()
  self:initID()
  self:initSocket()
  self:initReconnect()
  self:signal("init"):fire()
end

function CombatMessenger:destroy()
  logd('[cm] cm destroy')
  self:signal('destroy'):fire()
  self:clearSignals()
  self:destroyReconnect()
  self:destroySocket()
end

function CombatMessenger:onSocketError(err)
  self:signal("error"):fire(err)
end





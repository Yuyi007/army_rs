-- MsgEndpointReconnect.lua

--[[
  Handles reconnect stuff
]]--

local reconnectHandle = 0
local initialDelay = 0.5
local maxDelay = 5
local defaultMaxRetry = 4
local defaultFailOp = '2manual' --'2login', '2manual', 'retry'

function MsgEndpoint:getMaxRetry()
  self.maxRetryCount = self.maxRetryCount or defaultMaxRetry
  return  self.maxRetryCount
end

function MsgEndpoint:setMaxRetry(num)
  -- logd(">>>>>>>set max reconnect count: "..inspect(num))
  self.maxRetryCount = num
end

function MsgEndpoint:setRetryFailOp(op)
  self.retryFailOp = op
end

function MsgEndpoint:getRetryFailOp()
  self.retryFailOp = self.retryFailOp or defaultFailOp
  return self.retryFailOp
end

function MsgEndpoint:initReconnect()
  self.reconnectDelay = initialDelay

  self:uninstallReconnect()

  if self:isConnected() then
    self:setupReconnect()
  else
    self:tryReconnect()
  end
end

function MsgEndpoint:destroyReconnect()
  self:uninstallReconnect()
end

function MsgEndpoint:setupReconnect()
  logd("mp[%d]: setupReconnect", self.id)

  self._retryFunc = function()
    if self:getMaxRetry() > 0 then
      self:tryReconnect()
    else
      self:showConfirmReconnect()
    end
  end

  -- setup reconnect when a request is timeout
  if not self:signal('timeout'):added(self._retryFunc) then
    self:signal('timeout'):add(self._retryFunc)
  end

  -- setup reconnect when the connection is closed
  if not self:signal('closed'):added(self._retryFunc) then
    self:signal('closed'):add(self._retryFunc)
  end

  -- setup reconnect when data error
  if not self:signal('error'):added(self._retryFunc) then
    self:signal('error'):add(self._retryFunc)
  end
end

function MsgEndpoint:uninstallReconnect()
  logd("mp[%d]: uninstallReconnect", self.id)

  self:cancelReconnect()

  if self._retryFunc then
    self:signal('timeout'):remove(self._retryFunc)
  end

  if self._retryFunc then
    self:signal('closed'):remove(self._retryFunc)
  end

  if self._retryFunc then
    self:signal('error'):remove(self._retryFunc)
  end
end

function MsgEndpoint:onEnterBackground()
  self:close()
  self.reconnectDelay = initialDelay
  self.retryCount = 0
end

function MsgEndpoint:onEnterForeground()
  if self.host and self.port then
    if self:isConfirmReconnectShown() then
      logd('mp[%s]: onEnterForeground and hide ConfirmReconnect', self.id)
      self:hideConfirmReconnect()
    end
    self:tryReconnect()
  else
    logd('mp[%s]: onEnterForeground but no host or port', self.id)
  end
end

function MsgEndpoint:cancelReconnect()
  if reconnectHandle ~= 0 then
    scheduler.unschedule(reconnectHandle)
    reconnectHandle = 0
  end
end

function MsgEndpoint:tryReconnect(opts)
  if self.reconnecting and self.retryCount == 0 then return end

  self.reconnecting = true
  self:hideConfirmReconnect()

  opts = opts or {}

  -- Ensure your reconnectDelay is not too small, or new connection could have
  -- problem when old connection is still processing unbinding
  logd("mp[%d]: start tryReconnect opts=%s traceback:%s", self.id, peek(opts), debug.traceback())

  -- If there are packet sent during reconnecting period, error could be triggered
  -- with the invalid socket, and may trigger another reconnection, effectively
  -- postpone reconnection until when no message is being sent.
  self.allowSend = false

  self:cancelReconnect()
  self:hideBusy()

  if self.options.showReconnectMask then
    self:showReconnecting()
  else
    self:hideReconnecting()
  end

  local doReconnect = function ()
    self.retryCount = self.retryCount or 0
    self.retryCount = self.retryCount + 1
    -- logd(">>>>>>>reconnect times: "..inspect(self.retryCount))


    scheduler.unschedule(reconnectHandle)
    reconnectHandle = 0

    self:reconnect()

    if self:isConnected() then
      logd("mp[%d]: reconnected", self.id)
      -- connected, setup for future reconnection
      self.reconnecting = false
      self:uninstallReconnect()
      self:setupReconnect()
      self.allowSend = true
      self.retryCount = 0
      self:clearSendQueue()
      self:clearReceiveQueue()
      self:onReconnectSuccess()
    else
      -- not connected
      logd("mp[%d]: reconnect failed !", self.id)
      self:onReconnectFailed()
      if self.retryCount >= self:getMaxRetry() then
        self.reconnecting = false
        self.retryCount = 0
        self.reconnectDelay = initialDelay
        self:uninstallReconnect()
        self:onReconnectMaxRetry()
        self:hideReconnecting()
      end
    end
  end

  if opts.immediately then
    doReconnect()
  else
    logd('mp[%d]: reconnect delay=%f', self.id, self.reconnectDelay)
    reconnectHandle = scheduler.schedule(doReconnect, self.reconnectDelay, false, true)
    self:easeReconnectDelay()
  end
end

function MsgEndpoint:easeReconnectDelay()
  if self.reconnectDelay < maxDelay then
    self.reconnectDelay = self.reconnectDelay * 2.0 -- backoff
  end
end

function MsgEndpoint:onReconnectSuccess()
  logd("mp[%d]: onReconnectSuccess", self.id)

  self.reconnectDelay = initialDelay
  self:hideReconnecting()

  self:signal('reconnected'):fire()
end

function MsgEndpoint:onReconnectFailed()
  logd("mp[%d]: onReconnectFailed", self.id)

  self:tryReconnect()
end

function MsgEndpoint:onReconnectMaxRetry()
  local op = self:getRetryFailOp()
  -- logd(">>>>>>>on reconnect max reached !!! operate code:"..tostring(op))
  if op == "2login" then
    returnToLogin(function (view)
      if view then
        local canvas = view.gameObject:getComponent(Canvas)
        canvas:set_enabled(true)
      end
      self:showConfirmReconnect()
    end)
  elseif op == "2manual" then
    self:showConfirmReconnect()
  elseif op == "retry" then
    self:tryReconnect()
  end
end

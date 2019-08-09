local hReconnect = nil
local initialDelay = 0.5
local maxDelay = 5
local defMaxRetry = 3

function CombatMessenger:getMaxRetry()
	self.maxRetry = self.maxRetry or defMaxRetry
	return self.maxRetry 
end

function CombatMessenger:setMaxRetry(num)
	self.maxRetry = num
end

function CombatMessenger:initReconnect()
	self.reconnectDelay = initialDelay

	self:uninstallReconnect()

	if self:isConnected() then
		self:setupReconnect()
	else
		self:tryReconnect()
	end
end

function CombatMessenger:setupReconnect()
	logd("CombatMessenger[%d]: setupReconnect", self.id)

	self._retryFunc = function()
		if self:getMaxRetry() <= 0 then
			return 
		end
		self:tryReconnect()
	end


	if not self:signal('timeout'):added(self._retryFunc) then
    self:signal('timeout'):add(self._retryFunc)
  end

  if not self:signal('closed'):added(self._retryFunc) then
    self:signal('closed'):add(self._retryFunc)
  end

  if not self:signal('error'):added(self._retryFunc) then
    self:signal('error'):add(self._retryFunc)
  end
end

function CombatMessenger:uninstallReconnect()
	logd("CombatMessenger[%d]: uninstallReconnect", self.id)
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

function CombatMessenger:cancelReconnect()
  if hReconnect then
    scheduler.unschedule(hReconnect)
    hReconnect = nil
  end
end

function CombatMessenger:destroyReconnect()
  self:uninstallReconnect()
end

function CombatMessenger:onEnterBackground()
	self:destroySocket()

  self.reconnectDelay = initialDelay
  self.retryCount = 0
  self.reconnecting = false
end

function CombatMessenger:onEnterForeground()
	if self.addr and self.port then
		self:tryReconnect()
	else
		logd('CombatMessenger[%s]: onEnterForeground but no addr or port', self.id)
	end
end

function CombatMessenger:onReconnectMaxRetry()
	logd("CombatMessenger[%d]: retry max but failed", self.id)
	self.reconnecting = false
  self.retryCount = 0
  self:uninstallReconnect()
  returnToLogin()
end

function CombatMessenger:onReconnectSuccess()
	logd("CombatMessenger[%d]: reconnect success", self.id)
	self.reconnecting = false
	self.retryCount = 0
	self:uninstallReconnect()
	self:setupReconnect()
end

function CombatMessenger:tryReconnect()
	if self.reconnecting and self.retryCount == 0 then return end
	logd("[cm] try reconnect count:%s", tostring(self.retryCount))
	self.reconnecting = true

	self:cancelReconnect()

	self.retryCount = self.retryCount or 0
	if self.retryCount >= self:getMaxRetry() then
  	self:onReconnectMaxRetry()
	end

	local doReconnect = function()
		logd('CombatMessenger[%d]: doReconnect retry count:%d', self.id, self.retryCount)
    self.retryCount = self.retryCount + 1

    self:cancelReconnect()

    self:reconnect()

    self.hConnected = self:signal("connected"):addOnce(function()
    		self:onReconnectSuccess()
    		self.hConnected = nil
    	end)
	end

	logd('CombatMessenger[%d]: reconnect delay=%f', self.id, self.reconnectDelay)
	hReconnect = scheduler.schedule(doReconnect, self.reconnectDelay, false, true)
	self:easeReconnectDelay()
end

function CombatMessenger:reconnect()
	self:initSocket()
end

function CombatMessenger:easeReconnectDelay()
  if self.reconnectDelay < maxDelay then
    self.reconnectDelay = self.reconnectDelay * 2.0 
  end
end







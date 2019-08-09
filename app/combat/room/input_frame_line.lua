-- require "statsd"

class("InputFrameLine", function(self, broadcaster)
	self.curFrm = 1
	self.hTimer = nil
	self.interval = nil
	self.frmRate = nil
	self.initialized = false
	
	self.frameReady = true
	self.broadcaster = broadcaster
end)


local m = InputFrameLine


function m:init(frmRate)
	self.frmRate = frmRate
	self.interval = math.floor(100 / frmRate)
	self.initialized = true
end

function m:start()
	if not self.initialized then return end
	self.hTimer = Scheduler.schedule(self.interval, function()
			self:onFrame()
		end)
end

function m:onFrame()
	self.lastTime = self.lastTime or skynet.time()
	local now = skynet.time()
	local dur = now - self.lastTime
	self.lastTime = now
	-- print(">>>>>frame duration:%s", tostring(dur), " interval:", self.interval)
	-- print(">>>>input frame line onFrame paused:", self.paused)
	-- if not self.paused then
	-- 	self.paused = true
	self:broadcast()
	-- else
	-- 	self.frameReady = true
	-- end
end

function m:frmLstAck(frmIndex)
	print(">>>>input frame line receive ack:", frmIndex, " curFrm:", self.curFrm)
	if self.paused and frmIndex == (self.curFrm - 1) then
		self.paused = false
		if self.frameReady then
			self:broadcast()
		end
	end
end

function m:pushInput(action)
	local lst = self.broadcaster:getActionLst(self.curFrm)
--[[	if #lst >= 1000 then
		skynet.error("frame actions overflow!!", #lst)
		return
	end--]]

	table.insert(lst, action)
end

function m:broadcast() 
	-- print("input frm line broadcast frm:", self.curFrm)
	local lst = self.broadcaster:getActionLst(self.curFrm)

	self.broadcaster:broadcast(self.curFrm)

	self.curFrm = self.curFrm + 1
	self.frameReady = false
end


function m:exit()
	if self.hTimer then
		Scheduler.unschedule(self.hTimer)
		self.hTimer = nil
	end
end

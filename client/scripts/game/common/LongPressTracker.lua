class("LongPressTracker", function(self, options)
  self.rctrans = options.rctrans
  self.interval = options.interval or 0.2
  self.triggerTime = options.triggerTime or 1
  self.slideCancelVector = options.slideCancelVector
  self.intervalFunc = options.intervalFunc
  self.startFunc = options.startFunc
  self.stopFunc = options.stopFunc
  self.cancelFunc = options.cancelFunc
  self.enabled = true
  self:init()
  self.nowPos = nil
end, TouchTracker)

local m = LongPressTracker

function m:init()
  self:base_init()
  self:makeRect()
end

function m:makeRect()
  self.rects = {}
  TouchUtil.getRect(self.rects, self.rctrans)
end

function m:isTouchInside(pos)
  return UIUtil.pointInCtrlRects(self.rects, pos)
end

function m:setEnabled(enable)
  self.enabled = enable
  self.pressTime = nil
  self.startInterval = false
  self.lastTime = nil
end

function m:onUpdate()
  if not self.enabled then return end
  self:base_update()
  self:checkInterval()
end

function m:checkInterval()
  if not self.pressTime then return end
  if not self.startInterval then
    local now = engine.realtime()
    if (now - self.pressTime) >= self.triggerTime then
      self.startInterval = true
      self.cancelled = nil
      if self.startFunc then
        self.startFunc(self)
      end
      if self.intervalFunc then
        self.intervalFunc(self)
        self.lastTime = now
      end
    end
  else
    if self.cancelled then return end
    if self.lastTime then
      local now = engine.realtime()
      local span = now - self.lastTime
      if span >= self.interval then
        if self.intervalFunc then
          self.intervalFunc(self)
          self.lastTime = now
        end
      end
    end
  end
end

function m:onTouchBegan(pos)
  self.nowPos = pos
  self.pressTime = engine.realtime()
  self.beginPos = Vector2.new(pos)
end

function m:onTouchMoved(pos, deltaPos)
  if self.cancelled then return end
  self.nowPos = pos
  local slideCancelVector = self.slideCancelVector
  if slideCancelVector then
    local delta = pos - self.beginPos
    if (math.abs(delta[1]) > math.abs(slideCancelVector[1])) or
      (math.abs(delta[2]) > math.abs(slideCancelVector[2])) then
      logd('LongPressTracker: cancelled delta=%s', tostring(delta))
      self.cancelled = true
      if self.cancelFunc then
        self.cancelFunc(self)
      end
    end
  end
end

function m:onTouchEnded(pos)
  if self.cancelled then
    logd('LongPressTracker: onTouchEnded but already cancelled')
  else
    self.nowPos = pos
    if self.stopFunc then
      self.stopFunc(self)
    end
  end
  self.pressTime = nil
  self.startInterval = false
  self.lastTime = nil
end

function m:start()
  self:stop()
  self.hUpdate = scheduler.scheduleWithUpdate(function(deltaTime)
      self:onUpdate()
  end)
end

function m:stop()
  if self.hUpdate then
    scheduler.unschedule(self.hUpdate)
    self.hUpdate = nil
  end
end

function m:exit()
  self:stop()
end

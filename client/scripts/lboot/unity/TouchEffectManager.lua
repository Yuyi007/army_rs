class('TouchEffectManager', function(self)
  self:init()
end)

local m = TouchEffectManager
m.instance = nil

function m:init()
  if m.instance then m.instance:exit() end
  m.instance = self

  self:initTouchEffectHandler()
end

function m:exit()
  self:exitTouchEffectHandler()
  self:clear()
end

function m:initTouchEffectHandler()
  -- logd('TouchEffectManager: initTouchEffectHandler self=%s trace=%s', tostring(self), debug.traceback())

  self.touchEffectTracker = TouchEffectTracker.new({
    cbTouchEnded = function(pos)
      -- logd('TouchEffectManager: cbTouchEnded self=%s', tostring(self))
      if not self.touchEffectView then
        self.touchEffectView = ViewFactory.make('TouchEffectView')
      end
      if not self.touchEffectView.destroyed then
        self.touchEffectView:showWithPosition(pos)
      end
    end,
  })

  self:exitTouchEffectHandler()
  self.touchEffectHandle = scheduler.scheduleWithUpdate(function(deltaTime)
    if self.touchEffectTracker then
      self.touchEffectTracker:onUpdate()
    end
  end)
end

function m:exitTouchEffectHandler()
  if self.touchEffectHandle then
    scheduler.unschedule(self.touchEffectHandle)
    self.touchEffectHandle = nil
  end
end

function m:clear()
  if self.touchEffectView then
    self.touchEffectView:destroy()
    self.touchEffectView = nil
  end
end

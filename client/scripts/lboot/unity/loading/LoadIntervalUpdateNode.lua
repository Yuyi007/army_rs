class("LoadIntervalUpdateNode", function(self, options)
end, LoadTaskNode)

local m = LoadIntervalUpdateNode
local unity = unity

function m:construct()
  LoadTaskNode.construct(self)

  self.host = self.options.host
  self.func = self.options.func
  self.tips = self.options.tips
  self.interval = self.options.interval or 0
end

function m:startLoad()
  unity.beginSample('LoadIntervalUpdateNode.startLoad %s', tostring(self.name))
  LoadTaskNode.startLoad(self)
  -- logd("<<<<<<<< LoadIntervalUpdateNode start, name:%s", tostring(self.name))
  self.handle = scheduler.scheduleWithUpdate(function()
      if self.scheduleFinished then
        loge('LoadIntervalUpdateNode: name=%s scheduleFinished!', tostring(self.name))
        return
      elseif self.host then
        self.func(self.host, self)
      else
        self.func(self)
      end
    end, self.interval)

  unity.endSample()
end

function m:finish()
  -- logd("<<<<<<<< LoadIntervalUpdateNode finish, name:%s", tostring(self.name))
  scheduler.unschedule(self.handle)
  self.handle = nil
  self.scheduleFinished = true
  LoadTaskNode.finish(self)
end

function m:getTaskInfo()
  return {tips = self.tips}
end
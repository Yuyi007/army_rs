class("LoadRoutineNode", function(self, options)
end, LoadTaskNode)

local m = LoadRoutineNode
local unity = unity

function m:construct()
  LoadTaskNode.construct(self)

  self.host = self.options.host
  self.func = self.options.func
  self.tips = self.options.tips
  self.args = self.options.args
end

function m:startLoad()
  unity.beginSample('LoadRoutineNode.startLoad %s', tostring(self.name))
  LoadTaskNode.startLoad(self)
  if self.host then
    self.func(self.host, self, self.args)
  else
    self.func(self, self.args)
  end

  unity.endSample()
end

function m:getTaskInfo()
  return {tips = self.tips}
end
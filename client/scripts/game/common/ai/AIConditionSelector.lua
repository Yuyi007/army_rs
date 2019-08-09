class('AIConditionSelector', function(self)
end, BranchNode)

local m = AIConditionSelector

function m:success()
  BranchNode.success(self)
  if self.actualTask == 1 then
    self.actualTask = 2
    self:_run(self.object)
  else
    if aidbg.debug then
      aidbg.log(0, "...AIConditionSelector success", 1)
    end
    self.control:success()
    self:resetActualTask()
  end
end

function m:fail()
  BranchNode.fail(self)
  if self.actualTask == 1 then
    self.actualTask = 3
    self:_run(self.object)
  else
    if aidbg.debug then
      aidbg.log(0, "...AIConditionSelector fail", 1)
    end
    self.control:fail()
    self:resetActualTask()
  end
end
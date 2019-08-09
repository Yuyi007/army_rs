class('AISequence', function(self)
end, BranchNode)

local m = AISequence

function m:success()
  BranchNode.success(self)
  self.actualTask = self.actualTask + 1
  if self.actualTask <= #self.nodes then
    self:_run(self.object)
  else
    if aidbg.debug then
      aidbg.log(0, "...AISequence success", 1)
    end
    self.control:success()
    self:resetActualTask()
  end
end

function m:fail()
  if aidbg.debug then
    aidbg.log(0, "...AISequence fail", 1)
  end
  BranchNode.fail(self)
  self.control:fail()
  self:resetActualTask()
end


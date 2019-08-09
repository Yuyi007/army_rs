class('Sequence', function(self, config)
end, BranchNode)

local m = Sequence

function m:success()
  BranchNode.success(self)
  self.actualTask = self.actualTask + 1
  if self.actualTask <= #self.nodes then
    self:_run(self.object)
  else
    self.control:success()
    self:resetActualTask()
  end
end

function m:fail()
  BranchNode.fail(self)
  self.control:fail()
  self:resetActualTask()
end

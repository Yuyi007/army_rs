class('Priority', function(self, config)
end, BranchNode)

local m = Priority

function m:success()
  BranchNode.success(self)
  self.control:success()
  self:resetActualTask()
end

function m:fail()
  BranchNode.fail(self)
  self.actualTask = self.actualTask + 1
  if self.actualTask <= #self.nodes then
    self:_run(self.object)
  else
    self.control:fail()
    self:resetActualTask()
  end
end

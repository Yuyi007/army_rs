class('RandomSelector', function(self, config)
end, BranchNode)

local m = RandomSelector

function m:start(object)
  BranchNode.start(self, object)
  self.actualTask = math.floor(math.random() * #self.nodes+1)
end

function m:success()
  BranchNode.success(self)
  self.control:success()
  self:resetActualTask()
end

function m:fail()
  BranchNode.fail(self)
  self.control:fail()
  self:resetActualTask()
end
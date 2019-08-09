class('AIRandomSequence', function(self)
end, BranchNode)

local m = AIRandomSequence

function m:_shuffle()
  local nodes = {}
  local len = #self.nodes
  while len > 0 do
    local index = math.floor(math.random() * len + 1)
    nodes[#nodes + 1] = self.nodes[index]
    table.remove(self.nodes, index)
    len = #self.nodes
  end
  self.nodes = nodes
end

function m:start(object)
  if not self.nodeRunning then
    self:setObject(object)
    self:resetActualTask()
  end
end

function m:resetActualTask()
  self:_shuffle()
  self.actualTask = 1
end

function m:success()
  BranchNode.success(self)
  self.actualTask = self.actualTask + 1
  if self.actualTask <= #self.nodes then
    self:_run(self.object)
  else
    if aidbg.debug then
      aidbg.log(0, "...AIRandomSequence success", 1)
    end
    self.control:success()
  end
end

function m:fail()
  if aidbg.debug then
    aidbg.log(0, "...AIRandomSequence fail", 1)
  end
  BranchNode.fail(self)
  self.control:fail()
end




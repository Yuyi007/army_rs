class('BranchNode', function(self, config)
  self.isBranch = true
end, Node)

local m = BranchNode

function m:forceKill()
  Node.finish(self)
  if self.nodeRunning and self.node then
    self.nodeRunning = false
    self.node:forceKill()
    self.node = nil
    self:resetActualTask()
  end  
end

function m:resetActualTask()
  self.actualTask = 1
end

function m:start(object)
  if not self.nodeRunning then
    self:setObject(object)
    self:resetActualTask()
  end
end

function m:run(object)
  if aidbg.debug then
    aidbg.changeLineColor(self, true)
  end
  
  --logd("self.actualTask:"..tostring(self.actualTask).." #self.nodes:"..tostring(#self.nodes))

  if self.actualTask <= #self.nodes then
    self:_run(object)
  end
end

function m:_run(object)
  if not self.nodeRunning then
    self.node = self.nodes[self.actualTask]
    self.node:setControl(self)
    self.node:start(object)
  end

  if self.node then
    self.node:run(object)
  end
end

function m:running()
  self.nodeRunning = true
  self.control:running()
end

function m:success()
  self.nodeRunning = false
  if self.node then
    self.node:finish(self.object)
  end
  self.node = nil
end

function m:fail()
  self.nodeRunning = false
  if self.node then
    self.node:finish(self.object);
  end
  self.node = nil
end

function m:forceReset()
  self:forceKill()
end

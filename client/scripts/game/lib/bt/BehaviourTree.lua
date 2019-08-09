class('BehaviourTree', function(self, config)
end, Node)

local m = BehaviourTree

function m:run(object)
  if aidbg.debug then
    aidbg.changeLineColor(self, true)
  end

  if self.started then
    Node.running(self) --call running if we have control
  else
    self.started = true
    self.object = object or self.object
    self.rootNode = self.tree
    self.rootNode:setControl(self)
    self.rootNode:start(self.object)
    self.rootNode:call_run(self.object)
  end
end

function m:running()
  --Node.running(self)
  self.started = false
end

function m:success()
  if self.rootNode then
    self.rootNode:finish(self.object);
  end

  self.started = false
  Node.success(self)
end

function m:fail()
  if self.rootNode then
    self.rootNode:finish(self.object);
  end
  self.started = false
  Node.fail(self)
end


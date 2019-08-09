class('Node', function(self, config)
  self.config = config or {}
  self:initialize()
  self.uid = Node.genid()
end)

local m = Node
m.uid = 0
m.genid = function()
  m.uid = m.uid + 1
  return m.uid
end

function m:initialize()
  for k, v in pairs(self.config) do
    self[k] = v
  end
end

function m:start() end
function m:finish() end
function m:run() end

function m:forceKill()
  self:finish(self.object)
end

function m:forceReset()
  self:finish(self.object)
end

function m:call_run(object)
  self:run(object)
end

function m:setObject(object)
  self.object = object
end

function m:setControl(control)
  self.control = control
end

function m:running()
  if self.control then
    self.control:running(self)
  end
end

function m:success()
  if self.control then
    self.control:success()
  end
end

function m:fail()
  if self.control then
    self.control:fail()
  end
end
class("LoadTaskNode", function(self, options)
  self.options = options
  self:construct()
end)

local m = LoadTaskNode
local unity = unity

function m:construct()
  self.leafNode = true
  self.finished = false
  self.yield = self.options.yield
  self.name = self.options.name
  self.count = self.options.count or 1
  self.parentNode = self.options.parentNode
  self.finishFuncs = {}
  self:registerOnFinish(self.options.onFinished)
end

function m:registerOnFinish(func)
  if func ~= nil then
    table.insert(self.finishFuncs, func)
  end
end

function m:setParentNode(node)
  self.parentNode = node
end

function m:finish()
  local now = socket.gettime() 
  local elapse = now - self.startTime
  logd("[load] %s - %s", tostring(self.name), tostring(elapse))
  --如果已经跑过了就不用通知父节点了
  --原因是存在重联的时候直接调用entergame node 的function
  if self.finished then
    return
  end

  logd("[LoadTaskNode] finish %s", tostring(self.name))

  self.finished = true
  local function _doFinish()
    if self.stopped then return end

    if self.parentNode and self.parentNode.onChildNodeFinish then
      self.parentNode:onChildNodeFinish(self)
    end

    for i,v in pairs(self.finishFuncs) do
      v(self)
    end
  end

  if self.yield then
    scheduler.performWithDelay(0, _doFinish)
  else
    _doFinish()
  end
end

function m:startLoad()
  self.startTime = socket.gettime()
  -- error("You must override start method in derive class")
end

function m:getTaskInfo()
  error("You must override getTaskInfo method in derive class")
end

function m:stopLoad()
  logd('[%s] stopLoad', self.class.classname)
  self.stopped = true
end

class('AILogic', function(self, config)
  self.res = {}
  self.logic = 1 --1=and 0=or
end, BranchNode)

local m = AILogic

function m:init(cfg)
  local l =  cfg["logic"]

  if tostring(l):lower() == "and" then
    self.logic = 1
  elseif tostring(l):lower() == "or" then
    self.logic = 0
  else
    error("Invalid logic attr:"..l, 3)
  end
end

function m:start(agent)
  BranchNode.start(self, agent)
  self.res = {}
end

function m:_judge()
  local l = false
  if self.logic == 0 then
    l = (self.res[1] or self.res[2])
  else
    l = (self.res[1] and self.res[2])
  end
  if l then
    BranchNode.success(self)
    if aidbg.debug then
      aidbg.log(0, "...AILogic success", 1)
    end
    self.control:success()
    self:resetActualTask()
  else
    BranchNode.fail(self)
    if aidbg.debug then
      aidbg.log(0, "...AILogic fail", 1)
    end
    self.control:fail()
    self:resetActualTask()
  end
end

--如果有running状态节点直接强制失败
function m:running()
  if self.node then
    self.node:fail()
    self.node:finish(self.object)
  end
end

function m:success()
  self.res[self.actualTask] = true
  self.actualTask = self.actualTask + 1
  if self.actualTask <= #self.nodes then
    self:_run(self.object)
  else
    self:_judge()
  end
end

function m:fail()
  self.res[self.actualTask] = false
  self.actualTask = self.actualTask + 1
  if self.actualTask <= #self.nodes then
    self:_run(self.object)
  else
    self:_judge()
  end
end

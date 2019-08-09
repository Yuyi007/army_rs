class('AIParallel', function(self, config)
  self.childState = {}
  self.failMode = nil         --失败条件 "all"：全失败为失败 "one"：一个失败就失败
  self.successMode = nil      --成功条件 "all"：全成功为成功 "one"：一个成功就成功
  self.childLoopMode = nil    --子节点结束后，下次调用是否再次执行 "n":不执行 "y"：执行
  self.stopRunning = nil      --运行结束动作 "n"：不结束运行节点 "y":结束运行节点
end, BranchNode)

local m = AIParallel

function m:init(cfg)
  local mode = cfg["failmode"]
  if mode == "all" then
    self.failMode = 1
  elseif mode == "one" then
    self.failMode = 0
  else
    error("Invalid failmode attr:"..tostring(mode), 3)
  end

  mode = cfg["successmode"]
  if mode == "all" then
    self.successMode = 1
  elseif mode == "one" then
    self.successMode = 0
  else
    error("Invalid successmode attr:"..tostring(mode), 3)
  end

  mode = cfg["childloopmode"]
  if mode == "y" then
    self.childLoopMode = true
  elseif mode == "n" then
    self.childLoopMode = false
  else
    error("Invalid childloopmode attr:"..tostring(mode), 3)
  end

  mode = cfg["stoprunning"]
  if mode == "y" then
    self.stopRunning = true
  elseif mode == "n" then
    self.stopRunning = false
  else
    error("Invalid stoprunning attr:"..tostring(mode), 3)
  end
end

function m:start(agent)
  BranchNode.start(self, agent)
  BranchNode.resetActualTask(self)
end

function m:_geRealRunable()
  local res = self.actualTask
  for i = self.actualTask,#self.nodes do
    res = i
    if self.childState[i] == nil then
      break
    end
    if self.childState[i] ~= 2 then
      if self.childLoopMode then
        break
      end
    else
      break
    end
  end
  return res
end

function m:run(agent)
  if aidbg.debug then
    aidbg.changeLineColor(self, true)
  end

  self.nodeRunning = false
  self.actualTask = self:_geRealRunable()
  
  if self.actualTask <= #self.nodes then
    self.node = self.nodes[self.actualTask]
    self.node:start(agent)
    self.node:setControl(self)
    self.node:run(agent)
  end
end

function m:finish(agent)
  BranchNode.finish(self, agent)
  table.clear(self.childState)
end

function m:forceKill()
  Node.finish(self)
  if self.nodeRunning then
    self.nodeRunning = false
    self.node = nil
    for i=1, #self.nodes do
      if self.childState[i] == 2 then
        self.nodes[i]:forceKill()
      end
    end
  end
end

function m:_finish()
  for i=1, #self.nodes do
    --logd(">>>>>stoprunning:"..tostring(self.stopRunning).." state:"..tostring(self.childState[i]))
    if self.childState[i] == 2 then
      if self.stopRunning then
        self.nodes[i]:forceKill()
      end
    end
  end
end

function m:_judge()
  local hasSuc  = false
  local hasFail = false
  local hasRun  = false
  for i=1, #self.childState do
    if self.childState[i] == 0 then
      hasSuc = true
    elseif self.childState[i] == 1 then
      hasFail = true
    else
      hasRun = true
    end
  end

  --logd(">>>>self.failMode:"..self.failMode.." successMode:"..self.successMode.." hasFail:"..tostring(hasFail).." self.hasSuc:"..tostring(hasSuc))
  if (self.failMode == 1 and not hasSuc and not hasRun) or -- 全失败才失败模式， 没有成功 没有在运行
     (self.failMode == 0 and hasFail and self.successMode == 1) or -- 一个失败就失败模式，有失败的，成功模式为全成功
     (self.failMode == 0 and hasFail and (self.successMode == 0 and not hasSuc and not hasRun)) then -- 一个失败就失败模式，有失败的，成功模式为一个成功就成功，没有成功的, 并且没有在运行的
    self:_finish()

    BranchNode.fail(self)
    if aidbg.debug then
      aidbg.log(0, "...AIParallel fail", 1)
    end
    self.control:fail()
    self:resetActualTask()
    return
  end

  if (self.successMode == 1 and not hasFail and not hasRun) or -- 全成功才成功模式，没有失败，没有在运行的
     (self.successMode == 0 and hasSuc and self.failMode == 1) or -- 一个成功就成功模式，有成功的，失败模式为全失败
     (self.successMode == 0 and (hasSuc and self.failMode == 0 and not hasFail and not hasRun))then -- 一个成功就成功模式，有成功的，失败模式为一个失败就失败，没有失败的, 并且没有在运行的
    self:_finish()

    BranchNode.success(self)
    if aidbg.debug then
      aidbg.log(0, "...AIParallel success", 1)
    end
    self.control:success()
    self:resetActualTask()
    return
  end

  --没有正在运行的情况
  if not hasRun then
    BranchNode.fail(self)
    if aidbg.debug then
      aidbg.log(0, "...AIParallel fail", 1)
    end
    self.control:fail()
    self:resetActualTask()
    return
  end

  --有正在运行的
  BranchNode.running(self)
  if aidbg.debug then
    aidbg.log(0, "...AIParallel running", 1)
  end
  self.actualTask = 1
end

function m:running()
  self.childState[self.actualTask] = 2
  self.actualTask = self.actualTask + 1
  self.actualTask = self:_geRealRunable()
  if self.actualTask <= #self.nodes then
    self:_run(self.object)
  else
    self:_judge()
  end
end

function m:success()
  BranchNode.success(self)
  self.childState[self.actualTask] = 0
  self.actualTask = self.actualTask + 1
  self.actualTask = self:_geRealRunable()
  if self.actualTask <= #self.nodes then
    self:_run(self.object)
  else
    self:_judge()
  end
end

function m:fail()
  BranchNode.fail(self)
  self.childState[self.actualTask] = 1
  self.actualTask = self.actualTask + 1
  self.actualTask = self:_geRealRunable()
  if self.actualTask <= #self.nodes then
    self:_run(self.object)
  else
    self:_judge()
  end
end






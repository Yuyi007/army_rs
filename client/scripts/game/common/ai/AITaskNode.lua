class('AITaskNode', function(self, config)
    self.agent_method = nil
  end, BT.Task)

local m = AITaskNode

function m:init(cfg)
  self.agent_method = cfg["method"]
  for i=1,9 do
    self["arg"..i] = cfg["arg"..i]
    --logd("....arg:"..i..tostring(cfg["arg"..i]))
  end
end

function m:finish(agent)
  BT.Task.finish(self, agent)
  if self.onFinish then
    self.onFinish(agent)
  end
end

function m:registerFinish(f)
  if not self.onFinish then
    self.onFinish = f
  end
end

function m:run(agent)
  if aidbg.debug then
    aidbg.changeLineColor(self, true)
  end

  local func = agent[self.agent_method]
  if not func then
    error("Not exist agent method:"..tostring(self.agent_method), 3)
  end

  local res = func(agent, self, self["arg1"], self["arg2"], self["arg3"], self["arg4"], self["arg5"], self["arg6"], self["arg7"], self["arg8"], self["arg9"])

  if res == AIAgent.success then
    if aidbg.debug then
      aidbg.log(0, "...AITaskNode success:"..tostring(self.agent_method), 1)
    end
    self:success()
  elseif res == AIAgent.fail then
    if aidbg.debug then
      aidbg.log(0, "...AITaskNode fail"..tostring(self.agent_method), 1)
    end
    self:fail()
  elseif res == AIAgent.running then
    if aidbg.debug then
      aidbg.log(0, "...AITaskNode running"..tostring(self.agent_method), 1)
    end
    self:running()
  else
    error("Error return value!!! plz fix it! res:"..tostring(res).." method name:"..tostring(self.agent_method))
  end
end
class('AIMonitor', function(self, config)
    self.agent_method = nil
    self.revert = false
  end, BT.Monitor)

local m = AIMonitor

function m:init(cfg)
  self.agent_method = cfg["method"]
  for i=1,9 do
    self["arg"..i] = cfg["arg"..i]
  end
  self.revert = cfg["revert"]
end

function m:valid(agent)
  local func = agent[self.agent_method]
  if not func then
    error("Not exist agent method:"..tostring(self.agent_method), 3)
  end

  local res = func(agent, self, self["arg1"], self["arg2"], self["arg3"], self["arg4"], self["arg5"], self["arg6"], self["arg7"], self["arg8"], self["arg9"])
  --logd(">>>>>AIMonitor run:"..tostring(self.agent_method).." res:"..inspect(res))
  local success = (res == AIAgent.success) 
  if self.revert then
    success = not success
  end
  if success then
    if aidbg.debug then
      aidbg.log(0, "...AIMonitor true", 1)
    end
    return true
  else
    if aidbg.debug then
      aidbg.log(0, "...AIMonitor false", 1)
    end
    return false
  end
end
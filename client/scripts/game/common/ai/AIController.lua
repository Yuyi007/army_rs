require 'game/fight3d/ai/BTFactory'
require 'game/fight3d/ai/AIAgent'
require 'game/fight3d/ai/AIEnemyAgent'
require 'game/fight3d/ai/AIPlayerAgent'
require 'game/fight3d/ai/AIExecutor'

class('AIController', function (self)
  self.bts = {}
end)

local m = AIController
local unity = unity

function m:add(id, cfg, agent)
  local bt = BTF.gen(cfg)
  if aidbg.debug then
    aidbg.genDbgInfo(bt)
  end
  bt:setObject(agent)
  agent.btid = id
  local it = {
      bt = bt,
      interval = cfg.interval or 0.2
    }
  self.bts[id] = it
  if self.started then
    self:_startOne(it)
  end
end

function m:get(id)
  return self.bts[id]
end

function m:remove(id)
  local it = self.bts[id]
  if it and it.handle then
    scheduler.unschedule(it.handle)
    it.handle = nil
  end
  self.bts[id] = nil
end

function m:stop()
  self:pause()
  self.bts = {}
end

function m:manualStep(id)
  local it = self.bts[id]
  if not it then return end

  self:onStep(it.bt)
end

function m:onStep(bt)
  if not bt then return end
  unity.beginSample('AIController.onStep')

  -- if true then return end
  if aidbg.debug then
    aidbg.resetAllLineColor(bt.tree)
  end

  -- Fail-safe check keyState correctness
  -- When rebalance, the state machine (keyState) of fighter may have changed to another kind
  local agent = bt.object
  if agent then
    local fighter = agent.fighter
    if not fighter then
      logd('AIController.onStep: skipping! fighter is nil')
      return
    end
    local keyState = fighter.keyState
    if keyState.class ~= AIExecutor and
       keyState.class ~= UserInputState then
      logd('AIController.onStep: skipping! agent=%s keyState=%s', fighter.id, keyState.class.classname)
      unity.endSample()
      return
    end
  end

  bt:run()

  unity.endSample()
end

function m:_startOne(it)
  if not it.handle then
    it.handle = scheduler.schedule(function()
      if cc.scene and cc.scene.online == false then return end
      local bt = it.bt
      self:onStep(bt)
    end, it.interval)
  end
end

function m:start()
  --avoid multiple start
  if self.started or self.handleStart then
    return
  end

  self.handleStart = coroutineStart(function (delta)
      for i,v in pairs(self.bts) do
        self:_startOne(v)
        coroutine.yield()
      end
    end)
  self.started = true
end

function m:pause()
  if self.handleStart then
    scheduler.unschedule(self.handleStart)
    self.handleStart = nil
  end

  for i,v in pairs(self.bts) do
    if v.handle then
      scheduler.unschedule(v.handle)
      v.handle = nil
    end
  end
  self.started = false
end

class('FloatingTextManager', function(self, player)
  self.player = player
  self.pid = self.player.id
  self:init()
end)

local m = FloatingTextManager
local unity = unity

local txtIntervalTime = 0.4

function m:init()
  self.floatingTxts = {}
  self.floatingTxts['info'] = {}

  self.lastAddTime = {}
  self.lastAddTime['info'] = -1*txtIntervalTime

  self.elapsedTime = 0

  self.perFrameCounter = {}
  self.cacheLst = {}
  self.frameCount = 0
end

function m:addText(action)
  if self.stopped then return end
  self:cacheAction(action)
  -- if not self:checkNum(action) then return false end
  -- self:createText(action)
end

function m:cacheAction(action)
  local dt = self:getDisplayType(action)
  self.cacheLst[dt] = self.cacheLst[dt] or {}
  -- logd('[%s] FloatingTextManager.cacheAction list=%d action=%s data=%s', self.pid,
  --   #self.cacheLst[dt], action.class.classname, peek(action.data))
  -- logd('[%s] FloatingTextManager.cacheAction list=%d action=%s trace=%s', self.pid,
  --   #self.cacheLst[dt], action.class.classname, debug.traceback())
  action:retain()
  table.insert(self.cacheLst[dt], action)
end

function m:getDisplayType(action)
  return 'framed'
end

function m:checkNum(action)
  local t = FloatingTextFactory.getFloatingType(action)
  if t == nil then return false end

  local clz = action.class
  local floatingTxts = self.floatingTxts
  if clz == BuffDmgAction or clz == SkillDmgAction then
    --logd("<<<<<<<<<<<<<<<<<< #(floatingTxts[t]):%s", tostring(#(floatingTxts[t])))
    if #(floatingTxts[t]) >= 5 then
      return false
    end
  elseif clz == BuffAddAction then
    --logd("<<<<<<<<<<<<<<<<<< #(floatingTxts[t]):%s", tostring(#(floatingTxts[t])))
    if #(floatingTxts[t]) >= 1 then
      return false
    end
  end
  return true
end

function m:update(deltaTime)
  unity.beginSample('FloatingTextManager.update')

  self.elapsedTime = self.elapsedTime + deltaTime
  self.frameCount = self.frameCount or 0
  self.frameCount = self.frameCount + 1
  for dt, lst in pairs(self.cacheLst) do
    if #lst > 0 then
      if dt == 'framed' and ((not self.lastFrame) or (self.frameCount - self.lastFrame) > 2) then
        local action = table.remove(lst, 1)
        -- logd('[%s] FloatingTextManager.update list=%d action=%s', self.pid, #lst, action.class.classname)
        local floating = self:createText(action)
        action:release()
        if floating then self.lastFrame = self.frameCount end
      end
    end
  end
--[[
  for _, value in pairs(self.floatingTxts) do
    for i = 1, #value do
      local v = value[i]
      if type(v.onUpdate) == 'function' then
        v:onUpdate(deltaTime)
      end
    end
  end
  ]]

  unity.endSample()
end

function m:clearFrameTextCounter()
  self.perFrameCounter = {}
end

function m:createText(action)
  local t = FloatingTextFactory.getFloatingType(action)
  if t == nil then return false end

  local now = self.elapsedTime
  local floatingTxts = self.floatingTxts
  local floating = FloatingTextFactory.makeFromAction(action, self.player, function(txt)
    local txts = floatingTxts[txt.type]
    if txts then
      local index = nil
      for i = 1, #txts do
        local v = txts[i]
        if v.id == txt.id then
          index = i
          break
        end
      end
      if index then table.remove(txts, index) end
    end
  end)


  if floating then
    self.lastAddTime[floating.type] = self.elapsedTime
    table.insert(floatingTxts[floating.type], floating)
  end
  return floating
  --end
end

function m:resume()
  self.stopped = false
end

function m:exit()
  --if self.handler then
  --  scheduler.unschedule(self.handler)
  --end

  for _, value in pairs(self.floatingTxts) do
    for i = 1, #value do
      local v = value[i]
      v:unscheduleAll()
      v:destroy()
    end
  end

  self.floatingTxts = {}
  self.floatingTxts['dmg'] = {}
  self.floatingTxts['buff'] = {}
  self.floatingTxts['info'] = {}

  self.lastAddTime = {}

  self.elapsedTime = 0
  self.stopped = true
end
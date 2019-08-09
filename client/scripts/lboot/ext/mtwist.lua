--[[
Mersenne Twister PRNG lua binding
]]--

local _mtwist = require 'mtwist'

local mtwist = {traceEnabled = nil}
local meta = {}
meta.__index = meta

function meta:init(seed)
  -- logd('mtwist: init seed=%.0f trace=%s', seed, debug.traceback())
  self.mt:init(seed)
  self.seed = seed
  self.genCount = 0
  self.lastValue = -1.0
end

function meta:u32rand()
  local r = self.mt:u32rand()
  self.genCount = self.genCount + 1
  if mtwist.traceEnabled then
    logd('mtwist: u32rand seed=%.0f count=%d val=%d trace=%s', self.seed, self.genCount, r, debug.traceback())
  end
  self.lastValue = r
  return r
end

function meta:drand()
  local r = self.mt:drand()
  self.genCount = self.genCount + 1
  if mtwist.traceEnabled then
    logd('mtwist: drand seed=%.0f count=%d val=%f trace=%s', self.seed, self.genCount, r, debug.traceback())
  end
  self.lastValue = r
  return r
end

function meta:seedFromSystem()
  return self.mt:seed_from_system()
end

-- FIXME simply mods the max value, the quality can improve
function meta:rand(a, b)
  if b == nil then
    if a ~= nil then
      -- generate random number between [1, max]
      local max = a
      if max < 1 then error('interval is empty!') end
      local r = self:u32rand()
      return (r % max) + 1
    else
      error('invalid args!')
    end
  else
    -- generate random number between [min, max]
    local min, max = a, b
    if min > max then error('interval is empty!') end
    local r = self:u32rand()
    return (r % (max - min + 1)) + min
  end
end

function meta:genCount()
  return self.genCount
end

function meta:lastValue()
  return self.lastValue
end

----

function mtwist.instanceNum()
  return _mtwist.instance_num()
end

function mtwist.new(seed)
  local t = setmetatable({
    mt = _mtwist.new(),
    seed = nil,
    genCount = 0,
    lastValue = -1.0
    }, meta)
  if seed then t:init(seed) end
  return t
end

return mtwist

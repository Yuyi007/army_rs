class('GoTweenChainDecorator')

local m = GoTweenChainDecorator
local Go, GoTween, GoTweenConfig = Go, GoTween, GoTweenConfig
local assert, type, pairs, unpack = assert, type, pairs, unpack

function m.decorate(o)
  local mt = getmetatable(o)
  local t = m.funcs()
  for k, v in pairs(t) do
    rawset(mt, k, v)
  end

  -- decorate Go
  local typeMt = getmetatable(Go)
  local t = m.typeFuncs()
  for k, v in pairs(t) do
    rawset(typeMt, k, v)
  end

end

function m.typeFuncs()
  local mt = {}

  function mt.RemoveTween(tween)
    Go.removeTween(tween)
    tween:destroy()
  end

  function mt.AddTween(tween)
    Go.addTween(tween)
  end

  return mt
end

function m.funcs()
  local mt = {}

  --use GoTween:append() directly
  --[[
  -- optimize this to use less cpu cycles
  -- chain:appendTween(transform, duration, config, onComplete)
  -- chain:appendTween{ transform, duration, config, onComplete }
  -- onComplete is optional
  -- config can be a GoTweenConfig or a table
  function mt.appendTween(self, ...)
    local args = {...}
    -- assert(#args >= 3 or #args == 1, 'appendTween: wrong number of args')

    local t = args
    if #args == 1 then t = args[1] end

    local transform, duration, config, onComplete = t[1], t[2], t[3], t[4]

    -- assert(transform and duration and config)

    -- local configType = type(config)
    -- if configType == 'userdata' then
    --   self:append(GoTween(transform, duration, config, onComplete))
    -- elseif configType == 'table' then
      local goConfig = GoTweenConfig()
      for k, v in pairs(config) do
        -- logd('config k=%s v=%s goConfig=%s', tostring(k), tostring(v), tostring(goConfig[k]))
        if k == 'delay' then
          goConfig:set_delay(v)
        elseif k == 'iterations' then
          goConfig:set_iterations(v)
        elseif k == 'timeScale' then
          goConfig:set_timeScale(v)
        elseif k == 'loopType' then
          goConfig:set_loopType(v)
        elseif k == 'easeType' then
          goConfig:set_easeType(v)
        elseif k == 'position' then
          goConfig:position(v[1], v[2])
        elseif k == 'onUpdate' then
          goConfig:onUpdate(v)
        else
          error('goConfig: attribute not supported k=%s v=%s', tostring(k), tostring(v))
        end
      end
      self:append(GoTween(transform, duration, goConfig, onComplete))
    -- end
    return self
  end
  ]]

  return mt

end


setmetatable(m, {__call = function(t, ...) m.decorate(...) end })


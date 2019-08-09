class('AnimatorDecorator')

local m = AnimatorDecorator

function m.decorate(o)
  local mt = getmetatable(o)
  local t = m.funcs()
  for k, v in pairs(t) do
    rawset(mt, k, v)
  end
end

function m.funcs()
  local mt = {}

  function mt.curAnimLength(self, layer)
    layer = layer or 0
    local stateInfo = self:GetCurrentAnimatorStateInfo(layer)
    return stateInfo:get_length()
  end

  return mt
end

setmetatable(m, {__call = function(t, ...) m.decorate(...) end })
class('NicerOutlineDecorator')

local m = NicerOutlineDecorator

function m.decorate(o)
  local mt = getmetatable(o)
  local t = m.funcs()
  for k, v in pairs(t) do
    rawset(mt, k, v)
  end
end

function m.funcs()
  local mt = {}

  function mt.setEffectColor(self, color)
    self:set_effectColor(color)
  end

  function mt.setEffectDistance(self, distance)
    self:set_effectDistance(distance)
  end




  return mt
end

setmetatable(m, {__call = function(t, ...) m.decorate(...) end })
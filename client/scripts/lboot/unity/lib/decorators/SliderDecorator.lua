class('SliderDecorator')

local m = SliderDecorator

function m.decorate(o)
  local mt = getmetatable(o)
  local t = m.funcs()
  for k, v in pairs(t) do
    rawset(mt, k, v)
  end
end

function m.funcs()
  local mt = {}

  function mt.setProgress(self, percent)
    self:set_value(percent)
  end

  function mt.getProgress(self)
    return self:get_value()
  end

  function mt.setVisible(self, visible)
    self:get_gameObject():setVisible(visible)
  end

  return mt
end

setmetatable(m, {__call = function(t, ...) m.decorate(...) end })
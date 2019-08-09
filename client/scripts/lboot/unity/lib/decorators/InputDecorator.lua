class('InputDecorator')

local m = InputDecorator

function m.decorate(o)
  local mt = getmetatable(o)
  local t = m.funcs()
  for k, v in pairs(t) do
    rawset(mt, k, v)
  end
end

function m.funcs()
  local mt = {}

  function mt.setString(self, ...)
    self:set_text(loc(...))
  end

  function mt.setFontSize(self, size)
    self:set_fontSize(size)
  end

  function mt.setFontColor(self, color)
    self:set_color(color)
  end

  function mt.getFontSize(self)
    return self:get_fontSize()
  end

  function mt.getString(self)
    return self:get_text()
  end

  function mt.setVisible(self, visible)
    self:get_gameObject():setVisible(visible)
  end

  function mt.unblockClick(self)
    local canvasGroup = self:get_gameObject():addComponent(UnityEngine.CanvasGroup)
    canvasGroup:set_blocksRaycasts(false)
  end

  return mt
end

setmetatable(m, {__call = function(t, ...) m.decorate(...) end })
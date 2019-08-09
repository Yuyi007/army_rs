class('ScrollRectDecorator')

local m = ScrollRectDecorator

function m.decorate(o)
  local mt = getmetatable(o)
  local t = m.funcs()
  for k, v in pairs(t) do
    rawset(mt, k, v)
  end
end

function m.funcs()
  local mt = {}

  function mt.setVisible(self, visible)
    self:get_gameObject():setVisible(visible)
  end

  function mt.onDrag(self, e)
    self:OnDrag(e)
  end

  function mt.onBeginDrag(self, e)
    self:OnBeginDrag(e)
  end

  function mt.onEndDrag(self, e)
    self:OnEndDrag(e)
  end

  function mt.setToTop(self)
    self:set_verticalNormalizedPosition(1)
  end

  function mt.setToBottom(self)
    self:set_verticalNormalizedPosition(0)
  end

  function mt.setToLeft(self)
    self:set_horizontalNormalizedPosition(0)
  end

  function mt.setToRight(self)
    self:set_horizontalNormalizedPosition(1)
  end

  return mt
end

setmetatable(m, {__call = function(t, ...) m.decorate(...) end })
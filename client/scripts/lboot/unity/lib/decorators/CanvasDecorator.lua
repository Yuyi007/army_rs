class('CanvasDecorator')

local m = CanvasDecorator

function m.decorate(o)
  local mt = getmetatable(o)
  local t = m.funcs()
  for k, v in pairs(t) do
    rawset(mt, k, v)
  end
end

function m.funcs()
  local mt = {}

  function mt.setDepth(self, depth)
    local enabled = self:get_enabled()
    self:setEnabled(false)
    self:set_sortingOrder(depth)
    self:setEnabled(enabled)
  end

  function mt.refresh(self)
    local enabled = self:get_enabled()
    self:setEnabled(false)
    self:setEnabled(enabled)
  end

  function mt.setEnabled(self, val)
    -- loge('%s canvas setEnabled %s %s', self.gameObject:getName(), peek(val), debug.traceback())
    -- if val ~= self:get_enabled() then
      self:set_enabled(val)
    -- end
  end

  function mt.depth(self)
    return self:get_sortingOrder()
  end

  function mt.overrideDepth(self, val)
    self:set_overrideSorting(val)
  end

  return mt
end

setmetatable(m, {__call = function(t, ...) m.decorate(...) end })
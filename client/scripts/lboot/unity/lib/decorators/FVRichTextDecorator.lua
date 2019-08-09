class('FVRichTextDecorator')

local m = FVRichTextDecorator

function m.decorate(o)
  local mt = getmetatable(o)
  local t = m.funcs(mt)
  for k, v in pairs(t) do
    rawset(mt, k, v)
  end
end

function m.funcs(oldMt)
  local mt = {}

  function mt.setString(self, ...)
    local ok, ret = pcall(oldMt.set_OriginText, self, loc(...))
    if ok then
      return ret
    else
      loge('set_OriginText failed! ret=%s', tostring(ret))
      return self:set_OriginText('')
    end
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
    return self:get_OriginText()
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
class('ButtonDecorator')

local m = ButtonDecorator

function m.decorate(o)
  local mt = getmetatable(o)
  local t = m.funcs()
  for k, v in pairs(t) do
    rawset(mt, k, v)
  end
end

local colorDisabled = nil

function m.funcs()
  local mt = {}

  function mt.setEnabled(self, enabled)
    self:set_interactable(enabled)
    self:set_enabled(enabled)
  end

  function mt.setVisible(self, visible)
    self:get_gameObject():setVisible(visible)
  end

  function mt.setString(self, ...)
    local txt = self:get_gameObject():GetComponentInChildren(UI.Text)
    if txt then
      txt:setString(...)
    end
    return txt
  end

  function mt.setTxtColor(self, color)
    local txt = self:get_gameObject():GetComponentInChildren(UI.Text)
    if txt then
      local str = txt.text
      if str == "" then return end

      local b,e = string.find(str, ">.*<")
      if b and e then
        str = string.sub(str, b+1, e-1)
      end
      str = ColorUtil.getColorString(str, color)
      txt:setString(str)
    end
  end

  function mt.setOn(self, isOn)
    local btnToggle = self:get_gameObject():getComponent(Game.ToggleButton)
    if not btnToggle then return end
    btnToggle:SetOn(isOn)
  end

  function mt.setImage(self, img, path)
    local image = self.gameObject:GetComponentInChildren(UI.Image)
    local mat = nil
    if image then
      mat = image:setSprite(img, path)
    end
    return image, mat
  end

  return mt
end

setmetatable(m, {__call = function(t, ...) m.decorate(...) end })

class('ToggleDecorator')

local m = ToggleDecorator

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

  function mt.setString(self, ...)
    local txt = self:get_gameObject():GetComponentInChildren(UI.Text)
    if txt then txt:setString(...) end
  end

  function mt.setTxtColor(self, color)
    local txt = self:get_gameObject():GetComponentInChildren(UI.Text)
    if txt then
      local str = txt.text
      str = ColorUtil.getColorString(str, color)
      txt:setString(str)
    end
  end

  function mt.setOn(self, isOn)
    self:set_isOn(not isOn)
    self:set_isOn(isOn)
  end

  function mt.setSprite(self, normal, press, sheetPath)
    local bg = self:get_transform():find("Background")
    if bg then
      local bgImg = bg:getComponent(UI.Image)
      if bgImg then
        bgImg:setSpriteAsync(normal, sheetPath, function(mat)
          if mat then
            bgImg:set_material(mat)
          end
        end)
      end
    end

    local cm = self:get_transform():find("Background/Checkmark")
    if cm then
      local cmImg = cm:getComponent(UI.Image)
      if cmImg then
        cmImg:setSpriteAsync(press, sheetPath, function(mat)
          if mat then
            cmImg:set_material(mat)
          end
        end)
      end
    end
  end

  return mt
end

setmetatable(m, {__call = function(t, ...) m.decorate(...) end })


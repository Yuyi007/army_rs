View('FloatingText', "prefab/ui/common/floating_icon_text", function(self)
end)

local m = FloatingText
local Outline = UnityEngine.UI.Outline
local NicerOutline = UnityEngine.UI.Extensions.NicerOutline


function m:init()
  local canvas = self.gameObject:getComponent(Canvas)
  canvas:setDepth(32767)
  self.nicerOutline = self.txt.gameObject:getComponent(NicerOutline)
  self.txt:setRaycastEnabled(false)
end

function m:reopenInit()
end

function m:reopenExit()
end

function m:show(options)
  if options.simple then
    if self.nicerOutline then
      self.nicerOutline:set_enabled(false)
    end
  else
    if self.nicerOutline then
      self.nicerOutline:set_enabled(true)
    end
  end

  self.txt:setString(options.text)
  self.txt:setColor(ColorUtil.white)
  if options.extOptions then
    if options.extOptions.color then
      self.txt:setColor(options.extOptions.color)
    end
  end

  if options.overflow then
    self.txt.textField:set_verticalOverflow(1)
  else
    self.txt.textField:set_verticalOverflow(0)
  end

  local duration = options.duration or 1
  self:performWithDelay(duration, function()
    if options.onComplete then
      options.onComplete()
    end
    self:destroy()
  end)

  self:setVisible(true)
end
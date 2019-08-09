View('FloatingIconText', "prefab/ui/common/floating_icon_text", function(self)
end)

local m = FloatingIconText


function m:init()
  self.image = self.color_bg.gameObject:getComponent("Image")
  self.image2 = self.color_bg2.gameObject:getComponent("Image")

  self.canvasRenderer = self.txt.gameObject:getComponent("CanvasRenderer")
  self.canvasRenderer:SetAlpha(0)
  self.animator = self.gameObject:getComponent("Animator")
  self.animControlNode = ViewNode.new(self.gameObject, 'node', self)
  self.animControlNode.onAnimEvent = function(param)
    if param == "finish" then
      self.canvasRenderer:SetAlpha(0)
      self:destroy()
    elseif param ~= "" then
      local alhpa = tonumber(param)
      self.canvasRenderer:SetAlpha(alhpa)
    else
      sm:playSound("ui028")
      if self.onComplete then
        self.onComplete()
        self.onComplete = nil
      end
    end
  end

  local canvas = self.gameObject:getComponent(Canvas)
  canvas:setDepth(32767)

  UIUtil.removeRaycastTargets(self.gameObject, {self.txt})
end

function m:reopenInit()
end

function m:reopenExit()
end

function m:show(options)
  self.onComplete = options.onComplete

  local color = ColorUtil.gradeColor(options.grade)
  self.image:set_color(color)
  self.image2:set_color(color)

  self.txt:setString(options.text)
  if options.bonusId then
    Util.setIcon(options.bonusId, self.icon)
    -- if options.bonusId == "ite8000004" and md.chief.hasLevelup then
    --   md.chief.hasLevelup = false
    --   md:signal('hero_levelup'):fire()
    -- end
  else
    self.icon:setSprite(options.iconName)
  end

  self:setVisible(true)
end

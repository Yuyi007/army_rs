View('FramedFloatingText', "prefab/ui/common/floating_ui", function(self)
end)

local m = FramedFloatingText

m.instance = nil
m.showId = 0

local FROM_POS = Vector3.new(0, -20, 0)
local TO_OFFSET = Vector3.new(0, 15, 0)
local COLOR = Color.new(Color.white)

function m:init()
  self.txtbg:setRaycastEnabled(false)
  self.txtbg_frame.gameObject:getComponent("Image"):set_raycastTarget(false)
  self.txtbg_frame_txtFloating:setRaycastEnabled(false)
  self.textField = self.txtbg_frame_txtFloating.textField

  self.initPos = Vector3.new(self.transform:get_position())

  local canvas = self.gameObject:getComponent(Canvas)
  canvas:setDepth(32767)

  self:mayCreateChain()
end

function m:mayCreateChain(popupDuration, stayDuration, toOffset)
  popupDuration = popupDuration or 0.2
  stayDuration = stayDuration or 1
  toOffset = toOffset or TO_OFFSET

  -- try to reuse the chain
  if self.stayDuration == stayDuration and self.popupDuration == popupDuration and self.toOffset == toOffset then
    return
  end

  toOffset = Vector3.new(toOffset)

  local chain = unity.createTweenChain()
  chain:append(GoTween(self.txtbg_frame.transform, popupDuration, GoTweenConfig()
    :localPosition(toOffset, true)
    :setEaseType(GoEaseType.SineOut)))
  chain:append(GoTween(self.transform, stayDuration, GoTweenConfig()))
  chain:set_autoRemoveOnComplete(false)

  self.chain = chain
  self.popupDuration = popupDuration
  self.stayDuration = stayDuration
  self.toOffset = toOffset
end

function m:reopenInit()
end

function m:reopenExit()
  -- logd('reopenExit %s visible=%s', tostring(self), tostring(self.visible))
end

function m:show(options)
  if m.instance ~= self then
    m.deleteTipView()
  end

  m.instance = self
  m.showId = m.showId + 1
  -- logd('show %s (%s) options=%s', tostring(self), game.frameCount, peek(options))

  self.uiMask = options.uiMask or ui:cullingMask('default')
  self.onComplete = options.onComplete

  local fromPos = options.fromPos or FROM_POS
  local fontSize = options.fontSize or 18

  self.txtbg_frame:setPosition(fromPos)
  self.transform:set_position(self.initPos)

  -- local width = string.len(options.text)
  -- local rcTran = self.frame.gameObject:getComponent(RectTransform)
  -- rcTran.sizeDelta = Vector2(7*width+40, rcTran.sizeDelta.y)
  -- local textRcTran = frame_txtFloating.gameObject:getComponent(RectTransform)
  -- textRcTran.sizeDelta = Vector2(7*width+40, textRcTran.sizeDelta.y)

  self.textField:set_fontSize(fontSize)
  self.txtbg:setString(options.text)
  self.txtbg_frame_txtFloating:setString(options.text)
  
  local canvas = self.gameObject:getComponent(Canvas)
  canvas:setEnabled(true)

  self:setVisible(true)

  self:mayCreateChain(options.popupDuration, options.stayDuration, options.toOffset)

  local showId = m.showId
  self.chain:setOnCompleteHandler(function ()
    -- logd('onComplete (%s) self=%s instance=%s', game.frameCount, tostring(self), tostring(m.instance))
    if m.instance == self and m.showId == showId then
      m.deleteTipView()
    end
  end)
  self.chain:prepareAllTweenProperties()
  self.chain:restart(true)
end

function m:deleteView()
  -- logd('deleteView %s (%s) trace=%s', tostring(self), game.frameCount, debug.traceback())
  if self.onComplete then
    self.onComplete()
    self.onComplete = nil
  end
  self:destroy()
end

function m.deleteTipView()
  local instance = m.instance
  if instance and not instance.destroyed then
    instance:deleteView()
    instance = nil
  end
end

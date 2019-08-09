local unity = unity

class('ViewNode', function(self, go, varname, view)
  unity.beginSample('ViewNode.new')

  self.varname = varname
  self.view = view
  self.btnDelay = 0.5
  --- act like a normal component or gameObject, with names conforming to unity api
  self.gameObject = go
  self.transform = go:get_transform()
  self.signals = {}
  self:init()

  unity.endSample()
end)

local m = ViewNode
local Component = UnityEngine.Component
local EventSystems = UnityEngine.EventSystems
local Plane = UnityEngine.Plane
local unity = unity
local ParticleSystem  = UnityEngine.ParticleSystem

local splitAlphaShaderName = 'SpriteWithMask'

function m:getBindMethod(name)
  m.bindMethods = m.bindMethods or {
    Button                 = m.bindButton,
    Toggle                 = m.bindToggle,
    Text                   = m.bindTextField,
    InputField             = m.bindInputField,
    TextWithIcon           = m.bindTextWithIcon,
    Image                  = m.bindImage,
    Slider                 = m.bindSlider,
    RectTransform          = m.bindRectTransform,
    ScrollSnap             = m.bindScrollSnap,
    ScrollRect             = m.bindScrollRect,
    UI3D                   = m.bindUI3D,
    Animator               = m.bindAnimator,
    Canvas                 = m.bindCanvas,
    LayoutElement          = m.bindLayoutElement,
    Text_Extend            = m.bindTextExtend,
    FVRichText             = m.bindFVRichText,
    NicerOutline           = m.bindNicerOutline,
    ToggleButton           = m.bindToggleButton,
    AnimCallbackBehaviours = m.bindAnimCallback,
    RawImage               = m.bindRawImage,
    UICircle               = m.bindUICircle,
    ParticleSystem         = m.bindParticleSystem,
  }

  return m.bindMethods[name]
end

function m:reopenInit(go, varname, view)
  unity.beginSample('ViewNode.reopenInit')

  self.varname = varname
  self.view = view
  self.gameObject = go
  self.transform = go:get_transform()
  self.signals = self.signals or {}

  self:init()
  unity.endSample()
end

function m:init()
  local comps = gp:getComponents(self.gameObject)
  self.categories = self.categories or {}
  table.clear(self.categories)

  for k, c in pairs(comps) do
    local bind = self:getBindMethod(k)
    if bind then
      table.insert(self.categories, k)
      bind(self, c, k)
    end
  end

  self:checkIsSplitAlphaImage()
end

function m:checkIsSplitAlphaImage()
  if not self.image or self.splitAlphaMaterial then return end

  local mat = self.image:get_material()
  if mat and mat:get_shader():get_name() == splitAlphaShaderName then
    self.splitAlphaMaterial = mat
  end
end

function m:signal(...)
  local t = table.concat({...}, '_')
  if not self.signals[t] then
    self.signals[t] = Signal.new()
  end
  return self.signals[t]
end

function m:setVisible(visible)
  visible = op.truth(visible)
  if not self.gameObject then return end
  if self.visible ~= visible then
    self.gameObject:setVisible(visible)
    self.visible = visible
  end
end

function m:schedule(func, interval, num)
  return self.view:schedule(func, interval, num)
end

function m:scheduleWithLateUpdate(func, interval, num)
  return self.view:scheduleWithLateUpdate(func, interval, num)
end

function m:performWithDelay(delay, func)
  -- logd('performWithDelay view=%s self=%s trace=%s', tostring(self.view), tostring(self), debug.traceback())
  return self.view:performWithDelay(delay, func)
end

function m:unschedule(handler)
  self.view:unschedule(handler)
end

function m:stopUniformScale()
  -- CombatController.removeUniformScaleUpdate(self._camera, self)

  if self.initScale then self.transform:set_localScale(self.initScale) end
end

function m:startUniformScale(options)
  self:stopUniformScale()
  self.initScale = self.initScale or Vector3.new(self.transform:get_localScale())
  self.camera = self.camera or ui:mainCam()

  if self.camera:get_orthographic() then
    loge('camera is orthographic')
    return
  end

  -- CombatController.addUniformScaleUpdate(self._camera, self, options)
end

function m:cleanup()
  -- logd('ViewNode cleanup varname=%s trace=%s', tostring(self.varname), debug.traceback())
  if self.entries then
    -- NOTE entries is not an array
    for id, entry in pairs(self.entries) do
      self.view:removeAllListeners(entry:get_callback())
    end
  end

  if self.trigger then
    self.trigger.triggers:Clear()
  end

  if self.setStringBefore then
    self:setString('')
    self.setStringBefore = nil
  end

  self.entries = nil
  self.trigger = nil

  if self.input then
    self.view:removeAllListeners(self.input:get_onEndEdit())
    self.input = nil
  end

  if self.grayed then
    self:setNormal()
  end

  if self.rawImage then
    self.rawImage = nil
  end

  if self.button then
    self.button:set_interactable(true)
    self.button:set_enabled(true)
    self.view:removeAllListeners(self.button:get_onClick())
    self.button = nil
    self._onBtnClick = nil
  end

  if self.toggle then
    self.view:removeAllListeners(self.toggle:get_onValueChanged())
    self.toggle = nil
    self._onToggleClick = nil
  end

  if self.tipTouchHandler then
    self:unschedule(self.tipTouchHandler)
    self.tipTouchHandler = nil
  end

  if self.uniformScaleHandler then
    self:unschedule(self.uniformScaleHandler)
    self.uniformScaleHandler = nil
  end

  if self.scrollRect then
    self.view:removeAllListeners(self.scrollRect:get_onValueChanged())
    self.scrollRect = nil
  end

  if self.scrollSnap then
    self.scrollSnap.onPageChange = nil
    self.scrollSnap:FirstScreen()
    self.scrollSnap = nil
  end

  if self.textExt then
    self.textExt:ClearLinkCallbacks()
    self.textExt = nil
  end

  if self.textField then
    self.textField = nil
  end

  if self.textWithIcon then
    self.textWithIcon = nil
  end

  if self.richText then
    self.richText:ClearLinkCallbacks()
    self.richText = nil
  end

  if self.nicerOutLine then
    self.nicerOutLine = nil
  end

  self:stopProgressAnim()

  if self.slider then
    self.slider = nil
  end

  if self.image then
    if self.setSpriteBefore then
      self.image:set_sprite(nil)
      self.image:set_material(nil)
      self.setSpriteBefore = nil
    end

    self.image = nil
  end

  self.splitAlphaMaterial = nil

  if self.animator then
    self.animator = nil
    self.onAnimEvent = nil
  end

  if self.animCallbackBehaviour then
    unity.forceExit(self.animCallbackBehaviour)
    self.animCallbackBehaviour = nil
  end

  if self.uiCircle then
    self.uiCircle = nil
  end

  for k, v in pairs(self.signals) do
    v:clear()
  end

  self:stopUniformScale()

  self.view = nil
  self.touchRegistered = nil
  self.visible = nil
end

function m:destroy()
  self:cleanup()
  self.view[self.varname] = nil
  self.view._nodes[self.varname] = nil
  self.view = nil
  unity.destroy(self.gameObject)
end

function m:progressBar()
  return self.slider or self.image
end

-------------------- Component methods ---------------------

function m:setProgress(percent, direction)
  local p = self:progressBar()
  if p then p:setProgress(percent, direction) end
end

function m:select()
  if self.button then
    self.button:select()
  end
end

function m:getProgress()
  local p = self:progressBar()
  if p then return p:getProgress() end
  return 0
end

function m:setButtonDelay(delay)
  self.btnDelay = delay
end

function m:setOn(val)
  val = not not val

  if self.toggleButton then
    self.toggleButton:SetOn(val)
  elseif self.button then
    self.button:setOn(val)
  elseif self.toggle then
    self.toggle:setOn(val)
  end

end

function m:setColor(color)
  if not color then return end

  local typeColor = type(color)
  if typeColor == 'string' or typeColor == 'number' then
    color = hexToColor(color)
  end

  if self.image then
    self.image:set_color(color)
  end

  if self.textField then
    self.textField:set_color(color)
  end

  if self.textExt then
    self.textExt:set_color(color)
  end

  if self.richText then
    self.richText:set_color(color)
  end

  if self.textMesh then
    self.textMesh:set_color(color)
  end

  if self.uiCircle then
    self.uiCircle:set_color(color)
  end

  if self.rawImage then
    self.rawImage:set_color(color)
  end

end

function m:setOutLineColor(color)
  if self.nicerOutLine then
    self.nicerOutLine:set_effectColor(color)
  end
end

function m:setGray()
  self.grayed = true

  if self.splitAlphaMaterial then
    if self.image then
      self.image:set_material(ui:splitAlphaGrayMaterial(self.splitAlphaMaterial))
    end
  else
    if self.image then self.image:set_material(ui:grayMat()) end
  end

  if self.textField then self.textField:setGray() end
end

function m:setUseSceneDepth()
  if self.image then self.image:setUseSceneDepth() end
end

function m:setNormal()
  self.grayed = nil

  if self.splitAlphaMaterial then
    if self.image then
      self.image:set_material(self.splitAlphaMaterial)
    end
  else
    if self.image then self.image:set_material(nil) end
  end

  if self.textField then self.textField:setNormal() end
end

function m:setMaterial(mat)
  if self.image then self.image:set_material(mat) end
  if self.textField then self.textField:set_material(mat) end
  if self.richText then self.richText:set_material(mat) end
end

function m:setString(...)
  self.setStringBefore = true
  if self.richText then
    self.richText:setString(...)
  elseif self.textExt then
    self.textExt:setString(...)
  elseif self.input then
    self.input:setString(...)
  elseif self.textField then
    self.textField:setString(...)
  elseif self.textWithIcon then
    self.textWithIcon:setString(...)
  elseif self.button then
    return self.button:setString(...)
  end
end

function m:play()
  local particles = self.particles
  if particles then
    for i = 1, #particles do
      particles[i]:Play()
    end
  end

  local animators = self.animators
  if animators then
    for i = 1, #animators do
      animators[i]:set_enabled(true)
    end
  end
end

function m:onEditEnd(callback)
  if self.input then
    local onEndEdit = self.input:get_onEndEdit()
    self.view:removeAllListeners(onEndEdit)
    self.view:addListener(onEndEdit, callback)
  end
end

function m:setReadOnly(readOnly)
  if self.input then
    readOnly = not not readOnly
    self.input:set_readOnly(readOnly)
  end
end

function m:onLinkClicked(linkType, callback)
  if self.richText then
    self.richText:set_raycastTarget(true)
    self.richText:SetLinkCallback(linkType, callback)
  elseif self.textExt then
    self.textExt:set_raycastTarget(true)
    self.textExt:SetLinkCallback(linkType, callback)
  end
end

function m:getLinks()
  if self.hyperText then
    return self.hyperText:getLinks()
  end
end

function m:getString()
  if self.textField then
    return self.textField:getString()
  elseif self.input then
    return self.input:getString()
  elseif self.richText then
    return self.richText:getString()
  elseif self.textExt then
    return self.textExt:getString()
  elseif self.textWithIcon then
    return self.textWithIcon:getString()
  end
  return ''
end

function m:setEnabled(enabled)
  if self.button then
    self.button:setEnabled(enabled)
    if self.image then
      if enabled then
        self:setNormal()
      else
        self:setGray()
      end
    end
  end
end


function m:setBtnSound(sound)
  self.btnSound = sound
  -- logd("[sound] self.btnSound 333:%s", tostring(self.btnSound))
end

function m:setToggleSound(sound)
  self.toggleSound = sound
end

function m:refreshImageMaterial(mat)
  self.splitAlphaMaterial = mat
end

function m:setBtnImage(img, path)
  if self.button then
    local image, mat = self.button:setImage(img)
    if image == self.image then
      self:refreshImageMaterial(mat)
      if self.grayed then
        self:setGray()
      else
        self:setNormal()
      end
    elseif mat then
      image:set_material(mat)
    end
  end
end

function m:setSprite(spriteName, sheetPath)
  if self.image then
    local mat = self.image:setSprite(spriteName, sheetPath)
    self:refreshImageMaterial(mat)
    if self.grayed then
      self:setGray()
    else
      self:setNormal()
    end
  end
end

function m:setNativeSize()
  if self.image then
    self.image:setNativeSize()
  end
end

function m:setSpriteAsync(spriteName, sheetPath)
  if self.image then
    self.setSpriteBefore = true
    self.image:setSpriteAsync(spriteName, sheetPath, function(mat)
      self:refreshImageMaterial(mat)
      if self.grayed then
        self:setGray()
      else
        self:setNormal()
      end
    end)
  end
end

local function fillEntries(trigger)
  local entries = {}
  local triggers = trigger:get_triggers()
  for t in Slua.iter(triggers) do
    entries[t:get_eventID()] = t
  end
  return entries
end

local function getEventId(triggerType)
  if type(triggerType) == 'string' then
    return EventSystems.EventTriggerType[triggerType]
  end

  return triggerType
end

local function createEntry(trigger, eventId)
  local entry = EventSystems.EventTrigger.Entry()
  entry:set_eventID(eventId)
  trigger.triggers:Add(entry)
  return entry
end

function m:onClick(callback)
  self:addEventTrigger('PointerClick', callback)
end

function m:unregisterClick()
  self:removeEventTrigger('PointerClick')
end

function m:addEventTrigger(triggerType, callbackFunc)
  self.graphic = self.graphic or self.gameObject:getComponent(unity.UI.Graphic)
  if self.graphic then self.graphic:set_raycastTarget(true) end
  self.trigger = self.gameObject:addComponent(EventSystems.EventTrigger)
  self.entries = self.entries or fillEntries(self.trigger)
  local eventId = getEventId(triggerType)
  local entry = self.entries[eventId] or createEntry(self.trigger, eventId)
  local callback = entry:get_callback()
  self.view:removeAllListeners(callback)
  self.view:addListener(callback, callbackFunc)
  self.entries[eventId] = entry
end

function m:removeEventTrigger(triggerType)
  self.trigger = self.gameObject:addComponent(EventSystems.EventTrigger)
  self.entries = self.entries or fillEntries(self.trigger)
  local eventId = getEventId(triggerType)
  local entry = self.entries[eventId]
  if entry then
    self.view:removeAllListeners(entry:get_callback())
  end
end

function m:setRaycastEnabled(enabled)
  self.graphic = self.graphic or self.gameObject:getComponent(unity.UI.Graphic)
  if self.graphic then self.graphic:set_raycastTarget(op.truth(enabled)) end
end

function m:registerTouch(onTouch, param)
  if not self.touchRegistered then
    local onClick = function(event) onTouch('click', event, param) end
    local onMove  = function(event) onTouch('move', event, param) end
    local onBegin = function(event) onTouch('begin', event, param) end
    local onEnd   = function(event) onTouch('end', event, param) end

    self:addEventTrigger('PointerClick', onClick)
    self:addEventTrigger('Drag', onMove)
    self:addEventTrigger('PointerDown', onBegin)
    self:addEventTrigger('PointerUp', onEnd)
    self:addEventTrigger('Cancel', onEnd)
    self.touchRegistered = true
  end
end

function m:unregisterTouch()
  self:removeEventTrigger('PointerClick')
  self:removeEventTrigger('Drag')
  self:removeEventTrigger('PointerDown')
  self:removeEventTrigger('PointerUp')
  self:removeEventTrigger('Cancel')
  self.touchRegistered = false
end

function m:addDragCallBack(options, scrollNode)
  local onBegin = function(event)
    self.beganTouchPoint = Vector2.new(event.position[1], event.position[2])
  end
  local onEnd = function(event)
    if event.position[1] < self.beganTouchPoint[1] then
      if options.leftCallBack and self.dragHorizontal == true then options.leftCallBack() end
    elseif event.position[1] > self.beganTouchPoint[1] then
      if options.rightCallBack and self.dragHorizontal == true then options.rightCallBack() end
    end
    self.beganTouchPoint = nil
  end
  self:addEventTrigger('PointerDown', onBegin)
  self:addEventTrigger('PointerUp', onEnd)
  if options.clickCallBack then  self:addEventTrigger("PointerClick", options.clickCallBack) end
  self:addEventTrigger('Drag', function(e)
    if self.beganTouchPoint then
      if options.dragDisCallBack and self.dragHorizontal == true then
        options.dragDisCallBack(e.position[1] - self.beganTouchPoint[1])
      end
      if self.dragHorizontal == false and scrollNode then
        scrollNode:onDrag(e)
      end
    end
  end)
  self:addEventTrigger('BeginDrag', function(e)
    if math.abs(self.beganTouchPoint[1] - e.position[1]) < math.abs(self.beganTouchPoint[2] - e.position[2]) then
      self.dragHorizontal = false
    else
      self.dragHorizontal = true
    end
    if scrollNode then scrollNode:onBeginDrag(e) end
  end)
  self:addEventTrigger('EndDrag', function(e)
    if scrollNode then scrollNode:onEndDrag(e) end
    self.dragHorizontal = false
  end)
end

-- forward the drags to other drag listeners
function m:forwardDrag(...)
  local dragListeners = {...}
  if #dragListeners == 0 then return end

  self:addEventTrigger('Drag', function(e)
    each(function(listener) listener:onDrag(e) end, dragListeners)
  end)

  self:addEventTrigger('BeginDrag', function(e)
    each(function(listener) listener:onBeginDrag(e) end, dragListeners)
  end)

  self:addEventTrigger('EndDrag', function(e)
    each(function(listener) listener:onEndDrag(e) end, dragListeners)
  end)
end

function m:onBeginDrag(e)
  if self.scrollSnap then self.scrollSnap:onBeginDrag(e); return end
  if self.scrollRect then self.scrollRect:onBeginDrag(e) end
end

function m:onEndDrag(e)
  if self.scrollSnap then self.scrollSnap:onEndDrag(e); return end
  if self.scrollRect then self.scrollRect:onEndDrag(e) end
end

function m:onDrag(e)
  if self.scrollSnap then self.scrollSnap:onDrag(e); return end
  if self.scrollRect then self.scrollRect:onDrag(e) end
end

function m:onScroll(onChange)
  if self.scrollRect then
    local onValueChanged = self.scrollRect:get_onValueChanged()
    self.view:removeAllListeners(onValueChanged)
    self.view:addListener(onValueChanged, onChange)
  end
end

function m:onScrollPageChange(onChange)
  if self.scrollSnap then
    self.scrollSnap:set_onPageChange(onChange)
  end
end

function m:setItemSize(size)
  if self.scrollSnap then self.scrollSnap:SetItemSize(size) end
end

function m:curScrollerPage()
  if self.scrollSnap then return self.scrollSnap:CurrentPage() end
  return 0
end

function m:resetScrollPage()
  if self.scrollSnap then
    self.scrollSnap:FirstScreen()
  end
end

function m:setScrollMoveType(t)
  if self.scrollRect then
    self.scrollRect:set_movementType(t)
  end
end

function m:registerTipTouch(onHide)
  if not self.tipTouchHandler then
    self.visibleTick = 0
    self.tipTouchHandler = self:schedule(function(deltaTime)
      local visible = self.visible
      if not visible then self.visibleTick = 0; return end
      self.visibleTick = self.visibleTick + 1
      if self.visibleTick > 2 then
        TouchUtil.detectTipTouch(self, function()
            self:unschedule(self.tipTouchHandler)
            self.tipTouchHandler = nil
            self:setVisible(false)
            if onHide then
              onHide()
            end
          end, true)
      end
    end)
  end
end

function m:unregisterTipTouch()
  if self.tipTouchHandler then
    self:unschedule(self.tipTouchHandler)
    self.tipTouchHandler = nil
  end
end

function m:unblockClick()
  self.canvasGroup = self.gameObject:addComponent(UnityEngine.CanvasGroup)
  self.canvasGroup:set_blocksRaycasts(false)
end

function m:setPosition(pos)
  -- assert(pos[1] and pos[2] and pos[3], 'pos must be a Vector3!')

  self.transform:set_localPosition(pos)
end

function m:position()
  return self.transform:get_localPosition()
end

function m:setEulerAngles(angles)
  -- assert(angles[1] and angles[2] and angles[3], 'angles must be a Vector3!')

  self.transform:set_eulerAngles(angles)
end

function m:eulerAngles()
  return self.transform:get_eulerAngles()
end

-- Quaternion.Euler is slow, avoid using this
--
-- function m:setLocalRotation(angles)
--   assert(angles[1] and angles[2], and angles[3], 'rot must be a Vector3!')
--   self.transform.localRotation = Quaternion.Euler(angles[1], angles[2], angles[3])
-- end

function m:GetComponent(t)
  return self.gameObject:getComponent(t)
end

function m:getComponent(t)
  return self.gameObject:getComponent(t)
end

function m:AddComponent(t)
  return self.gameObject:addComponent(t)
end

function m:addComponent(t)
  return self.gameObject:addComponent(t)
end

function m:runProgressAnim(options)
  if self.progressHandler then
    self:stopProgressAnim(self)
  end

  options.node = self
  local p = self:progressBar()
  if p then p:runProgressAnim(options) end
end

function m:stopProgressAnim()
  if self.progressHandler then
    local p = self:progressBar()
    if p then p:stopProgressAnim(self) end
    self.progressHandler = nil
  end
end

function m:playAnim()
  if self.animator then
    self.animator:set_enabled(true)
    self.animator:Play('play')
  end
end

function m:stopAnim()
  if self.animator then
    self.animator:set_enabled(false)
  end
end

function m:setInputLength(length)
  if self.input then
    self.input:set_characterLimit(length)
  end
end

-------------------- Binds ---------------------

function m:bindButton(button)
  if not button then return end
  
  if self.button then
    self.view:removeAllListeners(self.button:get_onClick())
  end
  self.button = button
  self.btnSound = 'ui_common/button006'
  -- logd("[sound] self.btnSound:%s", tostring(self.btnSound))
  local view = self.view
  local callback = 'on'.. self.varname:gsub('^%w', string.upper, 1)
  unity.decorateButton(button)

  self._onBtnClick = function()
    -- logd("[sound] self.button 222:%s", tostring(self.btnSound))
    if self.btnSound then
      sm:playSound(self.btnSound)
    end

    local btnToggle = gp:getComponent(self.gameObject, 'ToggleButton')
    if btnToggle then btnToggle:SetOn(true) end
    self.button:set_interactable(false)
    view[callback](view)

    -- use scheduler, because the view may be pooled
    scheduler.performWithDelay(self.btnDelay, function()
      if self.button then
        self.button:set_interactable(true)
      end
    end)
  end

  if view[callback] then
    view:removeAllListeners(button:get_onClick())
    view:addListener(button:get_onClick(), self._onBtnClick)
  else
    -- logd('%s not defined', callback)
  end
end

function m:bindToggle(toggle)
  if not toggle then return end

  if self.toggle then
    self.view:removeAllListeners(self.toggle:get_onValueChanged())
  end

  self.toggle = toggle
  self.toggleSound = 'ui_common/button001'

  local view = self.view
  local callback = 'on'.. self.varname:gsub('^%w', string.upper, 1)
  unity.decorateToggle(toggle)

  self._onToggleClick = function()
    sm:playSound(self.toggleSound)
    view[callback](view)
  end

  if view[callback] then
    local onValueChanged = toggle:get_onValueChanged()
    view:removeAllListeners(onValueChanged)
    view:addListener(onValueChanged, self._onToggleClick)
  else
    -- logd('%s not defined', callback)
  end
end

function m:bindImage(image)
  if not image then return end
  self.image = image
  unity.decorateImage(image)
end

function m:bindRawImage(rawImage)
  if not rawImage then return end
  self.rawImage = rawImage
end

function m:bindTextField(textField, compName)
  if not textField then return end
  self.textField = textField
  if not self:bindedBefore(textField) then
    textField:set_text(loc(textField:get_text()))
    unity.decorateLabel(textField)
    self:markBinded(textField)
  end
end

function m:bindTextWithIcon(textWithIcon, compName)
  if not textWithIcon then return end
  self.textWithIcon = textWithIcon
  if not self:bindedBefore(textWithIcon) then
    textWithIcon:set_OriginText(loc(textWithIcon:get_OriginText()))
    unity.decorateTextWithIcon(textWithIcon)
    self:markBinded(textWithIcon)
  end
end

function m:bindInputField(input, compName)
  if not input then return end

  if self.input then
    self.view:removeAllListeners(self.input:get_onEndEdit())
  end

  self.input = input

  if not self:bindedBefore(input) then
    input:set_shouldHideMobileInput(false)
    -- this will auto loc the text if the content is a string id
    input:set_text(loc(input:get_text()))
    unity.decorateInput(input)
    self:markBinded(input)
  end
end

function m:bindedBefore(comp)
  return UIMapper.hasBinded(comp)
end

function m:markBinded(comp)
  UIMapper.markBinded(comp)
end

function m:setInteractable(...)
  if self.button then
    self.button:set_interactable(...)
  end
  if self.input then
    self.input:set_interactable(...)
  end
end

function m:bindSlider(slider, compName)
  if not slider then return end

  self.slider = slider
  if not self:bindedBefore(slider) then
    self.slider:set_maxValue(1)
    self.slider:set_minValue(0)
    unity.decorateSlider(slider)
    self:markBinded(slider)
  end
end

function m:bindScrollSnap(scrollSnap, compName)
  if not scrollSnap then return end
  self.scrollSnap = scrollSnap
  if not self:bindedBefore(scrollSnap) then
    scrollSnap:set_useFastSwipe(true)
    scrollSnap:set_fastSwipeThreshold(2)
    unity.decorateScrollSnap(scrollSnap)
    self:markBinded(scrollSnap)
  end
end

function m:bindRectTransform(rectTransform)
  if not rectTransform then return end
  self.rectTransform = rectTransform
end

function m:bindScrollRect(scrollRect)
  if not scrollRect then return end

  if self.scrollRect then
    self.view:removeAllListeners(self.scrollRect:get_onValueChanged())
  end
  logd("[node] bind scroll rect")
  self.scrollRect = scrollRect
  unity.decorateScrollRect(scrollRect)
end

function m:bindUI3D(ui3d)
  if not ui3d then return end
  self.ui3d = ui3d
  unity.decorateUI3D(ui3d)
end

function m:bindParticleSystem(ps)
  if not ps then return end

  local go = self.gameObject
  self.particles = go:getComponentsInChildren(ParticleSystem)
  self.animators = go:getComponentsInChildren(Animator)
end

function m:bindAnimator(animator)
  if not animator then return end
  self.animator = animator
  unity.decorateAnimator(animator)
end

function m:bindCanvas(canvas)
  if not canvas then return end
  self.canvas = canvas
  unity.decorateCanvas(canvas)
end

function m:bindLayoutElement(le)
  if not le then return end
  self.layout = le
end

function m:bindToggleButton(toggleButton)
  if not toggleButton then return end
  self.toggleButton = toggleButton
end

function m:bindTextExtend(text)
  if not text then return end
  self.textExt = text
  -- self.textExt.raycastTarget = true
  unity.decorateTextExtend(text)
end

function m:bindFVRichText(text)
  if not text then return end
  self.richText = text
  -- self.textExt.raycastTarget = true
  unity.decorateFVRichText(text)
end

function m:bindNicerOutline(outLine)
  if not outLine then return end
  self.nicerOutLine = outLine
  -- self.textExt.raycastTarget = true
  unity.decorateNicerOutline(outLine)
end



function m:bindAnimCallback(animCallbackBehaviour)
  self.animCallbackBehaviour = animCallbackBehaviour
  animCallbackBehaviour:set_Lua(self)
end

function m:bindUICircle(uiCircle)
  self.uiCircle = uiCircle
end

-------------------- Others ---------------------

function m:playClick()
  local chain = unity.createTweenChain()
  chain:append(GoTween(self.transform, 0.1, GoTweenConfig():scale(Vector3(1.1, 1.1, 1.1), false)))
  chain:append(GoTween(self.transform, 0.03, GoTweenConfig():scale(Vector3(1, 1, 1), false)))
  chain:play()
end

function m:OnAnimEvent(event)
  -- logd("ViewNode %s get node anim event: %s", tostring(self.gameObject), event)
  if self.onAnimEvent then
    self.onAnimEvent(event)
  end
end

function m:OnAnimFinish(event)
  -- logd("ViewNode %s get node anim event: %s", tostring(self.gameObject), event)
  if self.onAnimFinish then
    self.onAnimFinish(event)
  end
end

function m:get_transform()
  return self.transform
end









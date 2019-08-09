
local tracemem = rawget(_G, 'TRACE_MEM')
local GraphicRaycaster = UnityEngine.UI.GraphicRaycaster
local CanvasGroup = UnityEngine.CanvasGroup
local CanvasRenderer = UnityEngine.CanvasRenderer
local unity = unity

local function callctor(o, ctor, super, ...)
  if super then callctor(o, nil, super.super, ...) end
  if ctor then ctor(o, ...) end
end

local enableUIMapper = false

-- 2d ui view
function View(classname, bundleFile, ctor, super, clzOps)
  local cls = ViewBase(classname, bundleFile, ctor, super, clzOps)

  -- By default, 2d ui view should bind nodes
  cls.__bindNodes = true

  local UIMapper = UIMapper
  local BundlePathCacher = BundlePathCacher
  local match = string.match

  local _bundleFile = cls.__bundleFile or cls.__refBundle
  -- logd('%s _bundleFile = %s', classname, tostring(_bundleFile))

  local isEditor = game.platform == 'editor'
  local isDebugFolder = game.script == 'debug folder'

  local function canUseUIMapper(refBundle)
    if not enableUIMapper then return false end
    -- login ui do not use mapper as it might be loaded after restart
    -- where the sql dbs are being unloaded
    if refBundle == 'prefab/ui/login/login_ui' then return false end

    if type(refBundle) ~= 'string' then return false end
    if not match(refBundle, 'prefab/ui') then return false end
    if game.shouldLoadAssetInEditor() then return false end

    return true
  end

  if canUseUIMapper(_bundleFile) then
    local refBundle = _bundleFile:lower()
    local refRoot = cls.__refRoot or '$root'

    cls.__useMapper = false
    local function cacheValue(self, varname, value)
      local nilCache = self.__nilCache
      if value == nil then
        nilCache[varname] = 'nil'
      else
        nilCache[varname] = value
        if not isDebugFolder then
          rawset(self, varname, value)
        end
      end

      return value
    end

    function cls.getRootMapper()
      local mapper = cfg.uimapper[refBundle]
      if not mapper then
        return nil
      end

      local rootMapper = mapper[refRoot]
      return rootMapper
    end

    function cls.__index(self, varname)
      if varname == nil then return nil end
      local value = rawget(cls, varname)

      local nilCache = self.__nilCache

      if nilCache[varname] ~= nil then
        return value
      end

      if not cfg.uivarnames[varname] then
        return cacheValue(self, varname, value)
      end

      local rootMapper = cls.getRootMapper()

      if not rootMapper then
        return cacheValue(self, varname, value)
      end

      local varpath = rootMapper[varname]
      if not varpath then
        return cacheValue(self, varname, value)
      end

      local gameObject = rawget(self, 'gameObject')
      if not gameObject then
        return value
      end

      local go = gameObject:find(varpath)

      if go then
        local node = self:bindViewNode(go, varname)
        return node
      else
        -- loge('[%s.__find] node trans %s not found', classname, varname)
      end

      return cacheValue(self, varname, value)
    end
  end

  function cls.bind(self, bundleFile, bindOptions)
    --print('binding %s - %s', classname, tostring(bundleFile))
    if self.__async then
      bindOptions = bindOptions or {}
      bindOptions.async = true
    end
    self:__bind(bundleFile, bindOptions)
  end

  local EMPTY = {}

  function cls.__bind_nodes(self)
    unity.beginSample('View2D.__bind_nodes %s uimapper=%s', classname, not not cls.__useMapper)

    -- logd('__bind_nodes: class=%s __bindNodes=%s', classname, tostring(cls.__bindNodes))

    if not cls.__bindNodes then
      unity.endSample()
      return
    end

    self._nodes = {}

    if cls.__useMapper then
      -- intially bind buttons only to get the callbacks
      local bundleFile = cls.__bundleFile or cls.__refBundle
      local refRoot = cls.__refRoot or '$root'

      local bindableNodes, paths = UIMapper.getInitBindingNodes(bundleFile, refRoot, self.gameObject, self)
      for i = 1, #bindableNodes do
        self:bindViewNode(bindableNodes[i], paths[i])
      end
    else
      local bindableNodes, paths = BundlePathCacher.get(self.bundleFile, self.transform)
      -- local bindableNodes, paths = BindTree.getBindableNodes(self.gameObject, cls, self)
      for i = 1, #bindableNodes do
        self:bindViewNode(bindableNodes[i], paths[i])
      end
    end

    self.node = self:bindViewNode(self.gameObject, 'node')
    unity.endSample()
  end

  function cls.bindViewNode(self, go, varname)
    unity.beginSample('View2D.bindViewNode %s', classname)
    local node = self._nodes[varname] or UIMapper.bindViewNode(self, go, varname)
    unity.endSample()
    return node
  end

  local WorldSpace = RenderMode.WorldSpace
  local ScrOverLay = RenderMode.ScreenSpaceOverlay
  local ScrOverCam = RenderMode.ScreenSpaceCamera
  local RectMask2D = UnityEngine.UI.RectMask2D
  local LayerUI    = unity.layerBit("UI")

  function cls.on_post_bind(self)
    local transform = self.transform
    self.rectTransform = transform:getComponent(RectTransform)

    if transform:get_parent() == nil then
      self.canvas = transform:getComponent(Canvas)
      if self.canvas then
        self.canvasScaler = transform:getComponent(UI.CanvasScaler)
        ui:joinRoot(self)
      end
    end

    if self.initModal then
      self:initModal()
    end

    if not self.__worldSpace__ then
      ui:adjustRenderMode(self)
    end
    -- loge(">>>>>>>>>>> end time:%s", tostring(Time.get_realtimeSinceStartup()))
  end

  function cls.joystickFunctions(self)
    return jbt:commonViewJoystickFunction()
  end

  function cls.on_post_init(self)
    -- add onBtnClose for joystick
    jbt:addBtnToFunction(self, self:joystickFunctions())

    self:updateCanvasVisibility()
    self:signal('viewInited'):fire()
  end


  function cls.updateCanvasVisibility(self, uiMask)
    uiMask = uiMask or ui.mask
    if self.canvas and self.canvas:get_renderMode() ~= WorldSpace then
      local realVisible = self.visible and self:validMask(uiMask)

      if self.gameObject then
        self.gameObject:updateUI3dCamerasVisibility(realVisible)
      end

      self.canvas:setEnabled(realVisible)
    end
  end

  function cls.onViewInitialized(self, onComplete)
    if self.__inited then
      onComplete()
    else
      self:signal('viewInited'):addOnce(onComplete)
    end
  end

  function cls.showTransform(self, path)
    local node = self.transform:find(path)
    if node then node:get_gameObject():setVisible(true) end
  end

  function cls.hideTransform(self, path)
    local node = self.transform:find(path)
    if node then node:get_gameObject():setVisible(false) end
  end

  function cls.disableNodeInteraction(self, path)
    local node = self.transform:find(path)
    if node then
      local cg = node:get_gameObject():addComponent(unity.CanvasGroup)
      cg:set_interactable(false)
    end
  end

  function cls.enableNodeInteraction(self, path)
    local node = self.transform:find(path)
    if not_null(node) then
      local cg = node:get_gameObject():getComponent(unity.CanvasGroup)
      if cg then cg:set_interactable(true) end
    end
  end

  function cls.cleanup(self)
    unity.beginSample('View2D.cleanup')

    self:setInteractable(true)
    self:baseCleanup()

    if self._nodes then
      for varname, v in pairs(self._nodes) do
        v:cleanup()
      end
    end

    if self.node then
      self.node:cleanup()
    end

    if self.tipTouchHandler then
      scheduler.unschedule(self.tipTouchHandler)
      self.tipTouchHandler = nil
    end

    unity.endSample()
  end

  -- the order of functions calls for LuaBinderBehaviour cleanups callback:
  -- 1. cleanup (normally not overrided by view)
  -- 2. exit (overridable by view)
  -- 3. onDestroy (should not be overrided by view)
  -- since some nodes are still referenced in the exit functions
  -- the var table should be cleared in onDestroy
  function cls.onDestroy(self)
    unity.beginSample('View2D.onDestroy')

    -- logd('onDestroy go=%s self=%s trace=%s', tostring(self.gameObject),
    --   tostring(self), debug.traceback())
    self:baseOnDestroy()

    -- this is causing trouble
    -- if self._nodes then
    --   for varname, v in pairs(self._nodes) do
    --     v.view = nil
    --     self[varname] = nil
    --     self._nodes[varname] = nil
    --   end
    -- end

    self._nodes = nil
    self.node = nil

    if self.isModal then
      monoGCWithInterval()
    end

    unity.endSample()
  end

  function cls.setModal(self, isModal, hideMaskLayer, alphaVale)
    isModal = op.truth(isModal)
    self.isModal = isModal
    if self.gameObject then
      if not hideMaskLayer then
        self.mask = self.gameObject:addComponent(UI.Image)
        self.mask:set_type(UI.Image.Type.Simple)
        -- self.mask:setSprite('empty')
        local value = alphaVale or 0.3
        local color = Color(0, 0, 0, value)
        if self.backGroundColor then
          color = self.backGroundColor
        end
        self.mask:set_color(color)
      end

      if not isModal then
        if self.canvasGroup then
          self.gameObject:delComponent(canvasGroup)
          self.canvasGroup = nil
        end
        if self.mask then
          self.gameObject:delComponent(UI.Image)
          self.mask = nil
        end

        -- remove possible CanvasRenderer added by UI.Image
        -- leave this alone will cause pointInCtrl always return true
        -- touch to change camera direction will never work
        self.gameObject:delComponent(CanvasRenderer)
      else
        self.canvasGroup = self.gameObject:addComponent(CanvasGroup)
        self.canvasGroup:set_blocksRaycasts(isModal)
        if self.mask then
          self.mask:set_enabled(isModal)
        end
      end

    end
  end

  function cls.resetRootRect(self)
    unity.resetRectTransform(self.rectTransform)
  end

  local WorldSpace = RenderMode.WorldSpace
  function cls.baseSetVisible(self, visible)
    -- logd(">>>>>>>self.classname"..inspect(self.classname))
    -- logd(">>>>>>>self.visible"..inspect(self.visible))
    -- logd(">>>>>>>visible"..inspect(visible))
    if self.visible ~= visible then
      if not_null(self.canvas) and self.canvas:get_renderMode() ~= WorldSpace then
        local realVisible = (visible and self:validMask(ui.mask))

        if self.gameObject then
          self.gameObject:updateUI3dCamerasVisibility(realVisible)
        end
        self.gameObject:setVisible(visible)
        -- self.canvas:setEnabled(realVisible)
        self:setInteractable(visible)

        -- logd("baseSetVisible %s visible:%s realVisible:%s", tostring(self.classname), tostring(visible), tostring(realVisible))
        local animators = self.gameObject:GetComponentsInChildren(Animator)

        for i = 1, #animators do local v = animators[i]
          if visible then
            v:Rebind()
          else
            -- v:Stop()
          end
        end

      else
        if self.gameObject then
          self.gameObject:setVisible(visible)
          -- if self.canvas then
          --   self.canvas:set_enabled(visible)
          -- else
          --   self.gameObject:setVisible(visible)
          -- end
          self:setInteractable(visible)
        end
      end

      self.visible = visible

      if not visible then
        self:stopUniformScale()
      elseif self._uniformScale then
        self:startUniformScale()
      end

      if visible then
        self:signal('set_to_visible'):fire()
      end
    end
  end

  function cls.setVisible(self, visible)
    -- logd('%s setVisible for view %s old=%s, %s', self.classname,
    --   tostring(visible), tostring(self.visible), debug.traceback())
    self:baseSetVisible(visible)
  end

  function cls.playTrigger(self, animName)
    
    if self.animator then
      -- if self.curAnim == animName then return end
      self.animator:SetTrigger(animName)
      self.curAnim = animName
    end
  end

  function cls.playAnim(self, anim, time, onComplete)
    self.curAnim = anim

    if self.animator then
      if time == nil then
        self.animator:Play(anim)
      else
        self.animator:Play(anim, 0, time)
      end

      if onComplete then
        local length = self.animator:curAnimLength()
        self:performWithDelay(length, onComplete)
      end
    else
      if onComplete then onComplete() end
    end
  end

  function cls.setDepth(self, depth)
    if self.canvas then
      depth = math.clamp(depth, -32768, 32767)
      self.canvas:setDepth(depth)
      self._maxDepth = self._maxDepth or depth
    end
  end

  function cls.getRootAnimator(self)
    local t = self.transform:find("anim_control")
    if t then
      return t:GetComponent(Animator)
    else
      return nil
    end
  end

  function cls.setToScrenctSpaceOverlay(self)
    self.canvas:set_renderMode(ScrOverLay)
  end

  function cls.maxDepth(self)
    return self._maxDepth or self.canvas:depth()
  end

  function cls.incrMaxDepth(self)
    self._maxDepth = self._maxDepth or self.canvas:depth()
    self._maxDepth = self._maxDepth + 1
  end

  function cls.setToScrenceSpaceCamera(self)
    if not self.canvas then return end

    self.canvas:set_renderMode(ScrOverCam)
    self.canvas:set_worldCamera(ui.camera)
    self.canvas:set_sortingLayerID(LayerUI)
  end

  function cls.unregisterTipTouch(self)
    self.om:exit()
  end

  function cls.registerTipTouch(self)
    require 'lboot/unity/views/OutsideEvtMonitor'
    self.om = OutsideEvtMonitor.new(self)
  end

  function cls.onPopFront()
  end

  function cls.onPushFront()
  end

  function cls.bringToFront(self)
    self:_prepare()
    self.transform:SetAsLastSibling()
    self:_pushAnimation()
  end


  function cls._prepare(self)
  end

  function cls._pushAnimation(self)
    if self.pushFun and self.delayPush == nil then
      self.pushFun()
    end
  end


  function cls._popAnimation(self, onPopComplete)
    onPopComplete(self)
  end

  function cls.greenText(text)
    return "<color='#24b93d'>".. text .."</color>"
  end

  function cls.redText(text)
    return "<color='#bb3925'>".. text .."</color>"
  end

  function cls.setPosition(self, position)
    self.node:setPosition(position)
  end

  function cls.validMask(self, mask)
    if not self.uiMask then self.uiMask = ui:layerBit('default') end
    return bit.band(mask, self.uiMask) > 0
  end

  function cls.fullscreen(self)
    return op.truth(self._fullscreen)
  end

  function cls.reverseFixedRatio(self)
    return not not self._reverseFixedRatio
  end

  function cls.hideScene(self)
    return op.truth(self._hideScene)
  end

  return cls
end

View2D = View


local tracemem = rawget(_G, 'TRACE_MEM')
local LuaBinderBehaviour = LBoot.LuaBinderBehaviour
local unity = unity

local function callctor(o, ctor, super, ...)
  if super then callctor(o, nil, super.super, ...) end
  if ctor then ctor(o, ...) end
end

local optAsync = {async = true}

function ViewBase(classname, bundleFile, ctor, super, clzOpts)
  declare(classname)

  local cls
  if super then
    cls = clone(super)
  else
    cls = {}
  end

  if clzOpts then
    for k, v in pairs(clzOpts) do
      cls[k] = v
    end
  end

  if super then
    cls.super = super
    for k, v in pairs(super) do cls[k] = v end
  end

  cls.super      = super
  cls.classname  = classname
  cls.ctor       = ctor
  cls.__index    = cls
  cls.__bundleFile = bundleFile

  function cls.newAsync(...)
    if cls.checkUnique and not cls.checkUnique() then
      return nil
    end

    local o = setmetatable({}, cls)
    o.schedulers = {}
    o.eventDelegates = {}
    o.visible = true
    o.__nilCache = {}

    o.class = cls
    callctor(o, ctor, super, ...)

    if bundleFile then
      o:bind(bundleFile, optAsync)
    end

    return o
  end

  function cls.new(...)
    -- loge(">>>>>>>>>>> start time:%s", tostring(Time.get_realtimeSinceStartup()))
    if tracemem then traceMemory('view %s new', classname) end
    if cls.checkUnique and not cls.checkUnique() then
      return nil
    end

    local o = setmetatable({}, cls)
    o.schedulers = {}
    o.eventDelegates = {}
    o.visible = true
    o.__nilCache = {}

    o.class = cls
    callctor(o, ctor, super, ...)
    if tracemem then traceMemory('view %s after constructor', classname) end

    if bundleFile then
      o:bind(bundleFile)
    else
      -- o:init()
    end

    if tracemem then traceMemory('view %s after bind', classname) end
    return o
  end

  function cls.getRootMapper()
    return nil
  end

  function cls.__goto(self, doNotLoadEmpty)
    return self:baseGoto(doNotLoadEmpty)
  end


  local function doGotoDone(self)
    self.__gotoDone = true
    self:signal('gotoDone'):fire()
  end

  function cls.baseGoto(self, doNotLoadEmpty)
    unity.beginSample('ViewBase.baseGoto')

    ui:addChild(self.gameObject)
    ui:clearUIRoot({ self.gameObject })

    -- for subsequent goto's to properly destroy this view
    ui:setCurView(self)

    if unity.isLoadingLevel then
      logd('ViewBase.baseGoto: skip empty scene because is loading level')
      doGotoDone(self)
    elseif not doNotLoadEmpty then
      unity.loadLevelAsync('scenes/game/empty', function()
        doGotoDone(self)
      end)
    else
      doGotoDone(self)
    end

    unity.endSample()
  end

  function cls.onGotoDone(self, onComplete)
    if self.__gotoDone then
      onComplete()
    else
      self:signal('gotoDone'):addOnce(onComplete)
    end
  end

  function cls.startFrameUpdate(self)
    -- stop the frame handler first
    if self.frameHandler then
      self:stopFrameUpdate()
    end

    if is_null(self.gameObject) then return end

    self.frameHandler = self:schedule(function(deltaTime)
      unity.beginSample('frame_update')

      if self.destroyed then
        unity.endSample()
        return
      end
      self:onFrame(deltaTime)

      unity.endSample()
    end)
  end

  function cls.stopFrameUpdate(self)
    if self.frameHandler then
      self:unschedule(self.frameHandler)
      self.frameHandler = nil
    end
  end

  function cls.startFrameLateUpdate(self)
    -- stop the frame handler first
    if self.frameLateHandler then
      self:stopFrameLateUpdate()
    end

    if is_null(self.gameObject) then return end

    self.frameLateHandler = self:scheduleWithLateUpdate(function(deltaTime)
      unity.beginSample('frame_late_update')

      if self.destroyed then
        unity.endSample()
        return
      end
      self:onFrame(deltaTime)

      unity.endSample()
    end)
  end

  function cls.stopFrameLateUpdate(self)
    if self.frameLateHandler then
      self:unschedule(self.frameLateHandler)
      self.frameLateHandler = nil
    end
  end

  function cls.schedule(self, func, interval, num, runInstantly)
    if not self.schedulers then return end
    if runInstantly then func() end
    local handle = scheduler.scheduleWithUpdate(func, interval, false, false, num)
    table.insert(self.schedulers, handle)
    return handle
  end

  function cls.scheduleWithUpdate(self, func, interval, num)
    if not self.schedulers then return end
    local handle = scheduler.scheduleWithUpdate(func, interval, false, false, num)
    table.insert(self.schedulers, handle)
    return handle
  end

  function cls.scheduleWithLateUpdate(self, func, interval, num)
    if not self.schedulers then return end
    local handle = scheduler.scheduleWithLateUpdate(func, interval, false, false, num)
    table.insert(self.schedulers, handle)
    return handle
  end

  function cls.scheduleWithFixedUpdate(self, func, interval, num)
    if not self.schedulers then return end
    local handle = scheduler.scheduleWithFixedUpdate(func, interval, false, false, num)
    table.insert(self.schedulers, handle)
    return handle
  end

  function cls.performWithDelay(self, delay, func)
    if not self.schedulers then return end
    local handle = scheduler.performWithDelay(delay, func)
    table.insert(self.schedulers, handle)
    return handle
  end

  function cls.unscheduleAll(self)
    if not self.schedulers then return end

    for i = 1, #self.schedulers do local v = self.schedulers[i]
      scheduler.unschedule(v)
    end
    table.clear(self.schedulers)
  end

  function cls.unschedule(self, handler)
    scheduler.unschedule(handler)
  end


  function cls.addChild(self, go, preservePos)
    self.transform:addChild(go, preservePos)
  end

  --[[
  function cls.setParentWithName(self, goName, preservePos)
    local parent = unity.findCreateGameObject(goName)
    if parent then self:setParent(parent) end
  end
  ]]

  function cls.setParent(self, go, preservePos)
    -- logd('setParent trans=%s go=%s preservePos=%s',
    --   tostring(self.transform), tostring(go), tostring(preservePos))
    if not_null(self.transform) and not_null(go) then
      self.transform:setParent(go, preservePos)
    end
  end


  -- make this private
  local function bindGameObject(self, go)
    unity.beginSample('bindGameObject %s', classname)

    local binder = go:addComponent(LuaBinderBehaviour)
    if binder then
      self.binder = binder
      uoc:getCustomAttrCache(go).luaTable = self
      binder:Bind(self)
      self.__loaded = true
    end

    unity.endSample()
  end

  function cls.__bind(self, bundleFile, options)
    unity.beginSample('ViewBase.__bind %s uimapper=%s', classname, not not cls.__useMapper)

    self.bundleFile = bundleFile
    local async = false

    if options then
      async = options.async
    end

    if bundleFile then
      local tBundleFile = type(bundleFile)
      if tBundleFile == 'string' then
        if async then
          gp:createAsync(bundleFile, function(go)
            bindGameObject(self, go)

            unity.beginSample('ViewBase.loaded')
            self:signal('loaded'):fire(self)
            unity.endSample()
          end, options)
        else
          local go = gp:create(bundleFile)
          if go then
            bindGameObject(self, go)
          else
            loge('%s __bind %s failed', self.classname, tostring(bundleFile))
          end
        end
      elseif tBundleFile == 'userdata' then
        bindGameObject(self, bundleFile)
      elseif bundleFile.gameObject then
        bindGameObject(self, bundleFile.gameObject)
      end
    end

    unity.endSample()
  end

  function cls.__binded(self)
    unity.beginSample('ViewBase.__binded %s', classname)

    if not self.__inited then
      self.visible = self.gameObject:isVisible()
      self:on_post_bind()

      unity.beginSample('ViewBase.init %s', classname)
      self:init()
      unity.endSample()

      self.__inited = true
      self:on_post_init()
    end

    unity.endSample()
  end

  function cls.onBinded(self, func)
    if self.__loaded then
      func(self)
    else
      self:signal('loaded'):addOnce(func)
    end
  end

  if not cls.init then
    function cls.init(self)
      -- prt('$$ %s init not defined', classname)
    end
  end

  if not cls.inited then
    function cls.inited(self)
      return self.__inited
    end
  end

  if not cls.exit then
    function cls.exit(self)
      -- prt('$$ %s exit not defined', classname)
    end
  end

  if not cls.update then
    function cls.update(self)
      -- prt('$$ %s update not defined', classname)
    end
  end

  if not cls.onFrame then
    function cls.onFrame(self)
      -- prt('$$ %s onFrame not defined', classname)
    end
  end

  function cls.OnMouseUpAsButton(self)
    self:onMouseDown()
  end

  if not cls.onMouseDown then
    function cls.onMouseDown(self)
      -- prt('$$ %s onMouseDown not defined', classname)
    end
  end

  function cls.cleanup(self)
    unity.beginSample('ViewBase.cleanup %s', classname)

    self:baseCleanup()

    unity.endSample()
  end

  function cls.baseCleanup(self)
    -- logd('%s baseCleanup %s', classname, tostring(self.gameObject))
    self:stopUniformScale()
    self:unscheduleAll()
    self:stopFrameUpdate()
  end

  function cls.baseOnDestroy(self)
    self.destroyed = true
    -- logd('%s baseOnDestroy', classname)
    if self.signals then
      for k, v in pairs(self.signals) do
        v:clear()
      end

      self.signals = nil
    end

    TransformCollection.removeFromAll(self.gameObject)

    self.gameObject = nil
    self.transform = nil
    self.bundleFile = nil
    self.binder = nil
    self.schedulers = nil
    self.__loaded = nil
    self.__inited = nil

    table.clear(self.__nilCache)
    self:clearCondReady()

    for k, v in pairs(self) do
      if type(v) == 'userdata' then
        -- logd('%s baseOnDestroy k=%s', classname, tostring(k))
        self[k] = nil
      end
    end

    if self.eventDelegates then
      for event, callbacks in pairs(self.eventDelegates) do
        for callback, _v in pairs(callbacks) do
          LBoot.LuaUtils.DisposeLuaDelegate(callback)
        end
      end
      self.eventDelegates = nil
    end
  end

  function cls.onDestroy(self)
    unity.beginSample('ViewBase.onDestroy %s', classname)

    -- loge('onDestroy %s', self.classname)
    self:baseOnDestroy()

    unity.endSample()
  end

  function cls.baseDestroy(self, purge)
    -- logd('baseDestroy go=%s purge=%s', tostring(self.gameObject), tostring(purge))
    self.destroyed = true
    if not_null(self.gameObject) then
      if purge then
        local go = self.gameObject
        -- 2017-9-21 : exitBinders in go:destroy
        -- gp:exitBinders(go)
        go:destroy()
      else
        unity.destroy(self.gameObject)
      end
      self.gameObject = nil
    else
      self.gameObject = nil
    end
  end

  if not cls.destroy then
    function cls.destroy(self, purge)
      unity.beginSample('ViewBase.destroy %s', classname)

      self:baseDestroy(purge)

      unity.endSample()
    end
  end

  --[[
    It is observed that unity 5.3.5f1 has a bug that
    after a button is clicked, its action is never garbage
    collected (in Mono Runtime). When a button never gets clicked
    its action is collected correctly.

    Because the button action is never collected,
    the corresponding lua delegate in __LuaDelegates table
    will not be disposed, resulting the delegate and its upvalues
    being leaked in lua.

    It's yet unknown how to fix the unity bug of action leakage,
    but we fix here in lua to manually dispose all lua delegates
    related when removing listeners of a unity event.

    As a resulting convention, always use addListener(), removeListener(),
    removeAllListeners() instead of the raw event functions. And
    make sure all listeners are properly removed.
  ]]--

  function cls.addListener(self, event, callback)
    event:AddListener(callback)

    local delegates = self.eventDelegates
    delegates[event] = delegates[event] or setmetatable({}, {__mode = 'k'})
    delegates[event][callback] = true
  end

  function cls.removeListener(self, event, callback)
    event:RemoveListener(callback)

    local delegates = self.eventDelegates
    if delegates[event] then
      LBoot.LuaUtils.DisposeLuaDelegate(callback)
      delegates[event][callback] = nil
    end
  end

  function cls.removeAllListeners(self, event)
    event:RemoveAllListeners()

    local delegates = self.eventDelegates
    if delegates and delegates[event] then
      for callback, _v in pairs(delegates[event]) do
        LBoot.LuaUtils.DisposeLuaDelegate(callback)
        delegates[event][callback] = nil
      end
      delegates[event] = nil
    end
  end

  function cls.setLayer(self, layer, recursive)
    unity.setLayer(self.gameObject, layer, recursive)
  end

  if not cls.getLayer then
    function cls.getLayer(self)
      return self.gameObject:get_layer()
    end
  end

  function cls.setLayerOpt(self, layer, recursive)
    unity.setLayerOpt(self.gameObject, layer, recursive)
  end

  function cls.setSkinnedMeshRendererLayers(self, layer)
    unity.setSkinnedMeshRendererLayers(self.gameObject, layer)
  end

  function cls.zDepth(self)
    return self.transform:get_position()[3]
  end

  function cls.setZDepth(self, zDepth)
    local pos = self.transform:get_position()
    self.transform:set_position(Vector3(pos[1], pos[2], zDepth))
  end

  -- set the whole view to be interactable (or not)
  function cls.setInteractable(self, interactable)
    -- logd('setInteractable self=%s go=%s interactable=%s %s', tostring(self),
    --   tostring(self.gameObject), tostring(interactable), debug.traceback())
    if not_null(self.gameObject) then
      self.raycaster = self.gameObject:getComponent(UI.GraphicRaycaster)
      if self.raycaster then
        self.raycaster:set_enabled(interactable)
      end
    end
  end

  function cls.baseSetVisible(self, visible)
    if not self.gameObject then return end

    -- logd('baseSetVisible self=%s %s self.visible=%s visible=%s',
    --   self.class.classname, tostring(self), self.visible, visible)
    if self.visible ~= visible then
      cls.setInteractable(self, visible)

      self.gameObject:setVisible(visible)
      self:signal('visible_change'):fire(visible)
      self.visible = visible
      if not visible then
        self:stopUniformScale()
      elseif self._uniformScale then
        self:startUniformScale()
      end
    end
  end

  function cls.setVisible(self, visible)
    self:baseSetVisible(visible)
  end

  function cls.isVisible(self)
    return self.visible
  end

  local Plane = unity.Plane

  function cls.stopUniformScale(self)
    -- local cc = rawget(_G, 'cc')
    -- if cc then
    --   cc:removeUniformScaleUpdate(self._camera, self)
    -- end

    if self._initScale then
      if not_null(self.transform) then
        self.transform:set_localScale(self._initScale)
      end
      self.scaleFactor = nil
    end

    self._camera = nil
  end

  function cls.startUniformScale(self, options)
    if self.canvas and self.canvas.renderMode ~= 2 then
      loge("non worldspace ui shouldn't use unitformscale")
      return
    end

    self:stopUniformScale()
    self._initScale = self._initScale or Vector3.new(self.transform:get_localScale())
    self._camera = self._camera or ui:mainCam()

    if not self._camera then
      logd('cls.startUniformScale camera is nil')
      return
    end

    if self._camera.orthographic then
      loge('cls.startUniformScale camera is orthographic')
      return
    end

    cc:addUniformScaleUpdate(self._camera, self, options)
    --here should update instantly, or compass view vill show in big scale
    --local cg = cc.uniformScales[self._camera]
    --cc:updateSingleUniformScale(cg, self)
    --cc:updateSingleUniformScale(self._camera, self)

  end

  function cls.signal(self, ...)
    self.signals = self.signals or {}
    local t = table.concat({...}, '_')
    if not self.signals[t] then
      self.signals[t] = Signal.new()
    end
    return self.signals[t]
  end

  function cls.coroutineStart(self, func, duration, onComplete)
    duration = duration or 0

    local co = coroutine.create(func)
    local _loop
    local _handle
    local _resume = function(delta)
      local success, msg = coroutine.resume(co, delta)
      if not success then
        error(debug.traceback(co, msg))
      end
    end
    _resume(1)
    _loop = function(delta)
      if coroutine.status(co) ~= 'dead' then
        _resume(delta)
      else
        -- "self" may have been destroyed
        scheduler.unschedule(_handle)

        if onComplete ~= nil then
          onComplete()
        end
      end
    end

    _handle = self:schedule(_loop, duration)
    return _handle
  end

  function cls.onLoadComplete(self, onComplete)
    if self.__loaded then
      onComplete(self)
    else
      self:signal('loaded'):addOnce(onComplete)
    end
  end

  function cls.setCondReady(self, condition)
    self.__conditions = self.__conditions or {}
    self.__conditions[condition] = true
    self:signal(condition):fire()
  end

  function cls.reverseFixedRatio(self)
    return false
  end

  function cls.clearCondReady(self)
    if self.__conditions then
      table.clear(self.conditions)
    end

    self.__conditions = nil
  end

  function cls.onCondReady(self, condition, onComplete)
    if self.__conditions and self.__conditions[condition] then
      onComplete()
    else
      self:signal(condition):addOnce(onComplete)
    end
  end

  if not cls.getViewStackIndex then
    function cls.getViewStackIndex(self)
      return self.__vsIndex or 1
    end
  end

  if not cls.setViewStackIndex then
    function cls.setViewStackIndex(self, vsIndex)
      self.__vsIndex = vsIndex
    end
  end

  rawset(_G, classname, cls)
  return cls
end

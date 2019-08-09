
local unity = unity

local function callctor(o, ctor, super, ...)
  if super then callctor(o, nil, super.super, ...) end
  if ctor then ctor(o, ...) end
end

-- A scene view
-- Requires a _SceneRoot GameObject in the hierachy
function ViewScene(classname, bundleFile, ctor, super)
  local cls = View2D(classname, bundleFile, ctor, super)

  -- By default, view scene do not bind nodes
  cls.__bindNodes = nil
  cls.__useMapper = false

  cls.__index = cls

  function cls.new(...)
    local o = setmetatable({}, cls)
    callctor(o, ctor, super, ...)
    o.class = cls
    o.schedulers = {}
    o.eventDelegates = {}
    o.__nilCache = {}
    return o
  end

  function cls.bind(self, level)
    level = level or bundleFile
    self:__bind(level)
  end

  function cls.__goto(self, showLoading)
    return self:baseGoto(showLoading)
  end

  function cls.baseGoto(self, showLoading)
    unity.beginSample('ViewScene.baseGoto')

    if not showLoading then
      ui:clearUIRoot()
    end
    self:bind()

    -- 2017-5-5 : ViewScene now supports gotoDone
    self.__gotoDone = true
    self:signal('gotoDone'):fire()

    unity.endSample()
  end

  --[[
  function cls.loadAdditiveAsync(self, scenePath, onComplete, onProgress)
    unity.LightmapSettings.lightmaps = {}
    scenePath = scenePath:lower()
    unity.loadLevelAdditiveAsync(scenePath, onComplete, onProgress)
  end
  ]]

  function cls.destroy(self)
    self:baseDestroy()
  end

  function cls.baseDestroy(self)
    -- destroying the root gameObject should trigger the exit
    self.destroyed = true

    if self.gameObject then
      -- Force exit the binder, as the OnDestroy callback might be delayed
      local go = self.gameObject

      if self.binder then
        unity.forceExit(self.binder)
      end

      GameObject.Destroy(go)
    end
  end

  function cls.__bind(self, level)
    level = level or bundleFile
    if level then
      if type(level) == 'string' then
        unity.recordTime('ViewScene.startBinding %s', classname)
        self.startBindingTime = engine.realtime()
        level = self.subScene or level
        level = level:lower()
        self.bundleFile = level
        local onLoadComplete = function()
          logd('__bind: onLoadComplete %s', classname)

          local function doBind()
            logd('__bind: doBind %s', classname)
            local root = GameObject.Find('/_SceneRoot')
            if not root then
              root = GameObject('_SceneRoot')
              -- This will force the _SceneRoot to be parented to UIRoot
              -- This fixes init GameObject in OnDestroy error
              ui:addChild(root)
            end
            if root then self:bind(root) end
          end

          self:signal('sceneReady'):addOnce(function()
            self.__sceneReady = true
            ui:removeLoading()
            unity.recordTime('ViewScene.sceneReady %s', classname)
            unity.recordTime('ViewScene.sceneReady %s', classname, engine.realtime() - self.startBindingTime)
          end)

          doBind()
        end

        local onLoadProgres = function(t, p)
          self:signal('scene_loading'):fire(t, p)
        end

        logd('__bind: loadLevelAsync %s', classname)

        if self.__preloaded then
          logd('level %s is already loaded', level)
          onLoadComplete()
        else
          unity.loadLevelAsync(level, onLoadComplete, onLoadProgres)
        end
      elseif type(level) == 'userdata' then
        logd('__bind: Bind %s', classname)
        local go = level
        self.binder = go:addComponent(LuaBinderBehaviour)
        uoc:getCustomAttrCache(go).luaTable = self
        self.binder:Bind(self)
        unity.recordTime('ViewScene.bind_done %s', classname)
        unity.recordTime('ViewScene.bind_done %s', classname, engine.realtime() - self.startBindingTime)
      end
    end
  end

  function cls.onDestroy(self)
    self:baseOnDestroy()
    self.__sceneReady = nil
  end

  -- -- uncomment me to profile
  -- function cls.__binded(self)
  --   if not self.__inited then
  --   profile(function ()
  --     logd('__binded start')
  --     self.visible = self.gameObject:isVisible()
  --     self:on_post_bind()
  --     self:init()
  --     self.__inited = true
  --     self:signal('binded'):fire()
  --     self:on_post_init()
  --     logd('__binded finish')
  --   end)
  --   end
  -- end
  function cls.sceneReady(self)
    return self.__sceneReady
  end

  function cls.onSceneReady(self, onComplete)
    if self.destroyed then return end

    if self.__sceneReady then
      onComplete()
    else
      self:signal('sceneReady'):addOnce(onComplete)
    end
  end

  function cls.on_post_init(self)
    logd('[%s] on_post_init', self.class.classname)

    -- create GoKit gameObject to update pooled tweens
    local go = Go:get_instance()

    self:signal('sceneInited'):fire()
  end

  function cls.sceneInited(self)
    return self.__inited
  end

  function cls.onSceneInitialized(self, onComplete)
    if self.destroyed then
      -- logd('[%s] onSceneInitialized: destroyed', self.class.classname)
      return
    end

    if self.__inited then
      -- logd('[%s] onSceneInitialized: __inited', self.class.classname)
      onComplete()
    else
      self:signal('sceneInited'):addOnce(onComplete)
    end
  end

  return cls
end

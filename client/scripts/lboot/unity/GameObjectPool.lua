-- GameObject pooling for dynamically creating game objects from asset bundles.
-- You should always prefer gp:create(uri) and unity.destroy(go)
-- to make use of the pooling.
-- The pooling is needed because instantiating and destroying gameobjects
-- are very expensive operations
class('GameObjectPool', function(self, old)
  self:init(old)
end)

local m = GameObjectPool

local GameObject         = UnityEngine.GameObject
local LuaBinderBehaviour = LBoot.LuaBinderBehaviour
local LuaBaseBehaviour   = LBoot.LuaBaseBehaviour
local Component          = UnityEngine.Component

local unity = unity

local TTL = 60
local DEFAULT_WAKE_OPTIONS = {}
local DEFAULT_CREATE_OPTIONS = {}
local MAX = 10

function m:init(old)
  if old then
    self.PoolRoot = old.PoolRoot or TransformCollection.create('PoolRoot')
    self.PoolRootGlobal = old.PoolRootGlobal or TransformCollection.create('PoolRootGlobal')
  else
    self.PoolRoot = TransformCollection.create('PoolRoot')
    self.PoolRootGlobal = TransformCollection.create('PoolRootGlobal')
  end

  if not game.editor() then
    self.PoolRoot:setVisible(false)
    self.PoolRootGlobal:setVisible(false)
  end

  if not old then
    self.pool        = {}
    self.poolOptions = {}
    self.uri         = {}
    self.comps       = {}
    self.slepted     = {}
    self.prefabs     = {}
    self.asyncs      = {}
    self.rootUri     = {}
  else
    -- logd('GameObjectPool transfer old %s', peek(old.pool))
    self.pool        = old.pool or {}
    self.poolOptions = old.poolOptions or {}
    self.uri         = old.uri or {}
    self.comps       = old.comps or {}
    self.slepted     = old.slepted or {}
    self.prefabs     = {}
    self.asyncs      = old.asyncs or {}
    self.rootUri     = old.rootUri or {}
  end

  self:clearLoaders()
end

function m:setMax(uri, max)
  self.poolOptions[uri] = self.poolOptions[uri] or {}
  local opt = self.poolOptions
  opt.max = max
end

function m:exitBinders(root, checkRecycle)
  -- logd('exitBinders root=%s checkRecycle=%s trace=%s',
  --   tostring(root), tostring(checkRecycle), debug.traceback())
  if is_null(root) then return end

  local binders = root:GetComponentsInChildren(LuaBinderBehaviour, true)
  local count = #binders
  for i = count, 1, -1 do
    local binder = binders[i]
    unity.forceExit(binder)
    local go = binder:get_gameObject()
    -- logd('exitBinders root=%s go=%s', tostring(root), tostring(go))
    if checkRecycle and self:shouldRecycle(go) then
      self:sleep(go)
    end
  end

  local luaBehaviours = root:GetComponentsInChildren(LuaBaseBehaviour, true)
  local count = #luaBehaviours
  for i = count, 1, -1 do
    local b = luaBehaviours[i]
    unity.forceExit(b)
  end
end

function m:exitBindersAndClearPrefab(root)
  self:exitBinders(root)
  local uri = self:getTag(root)
  if uri then
    self.prefabs[uri] = nil
  end
end

function m:clearLoaders()
  each(function(_, v) v:clear() end, self.asyncs)
  table.clear(self.asyncs)
end

function m:clear()
  unity.beginSample('GameObjectPool.clear')

  self:purgePoolRoot(self.PoolRoot)
  self:stopAllAnimations(self.PoolRootGlobal)
  self:purgePrefabs()

  for instanceId, comps in pairs(self.comps) do
    -- if not self:isGlobalInstance(instanceId) then
      table.clear(comps)
      self.comps[instanceId] = nil
      self.rootUri[instanceId] = nil
    -- end
  end

  self:clearLoaders()

  local globalUriCounts = {}
  for goId, uri in pairs(self.uri) do
    local uriOptions = self.poolOptions[uri]
    if uriOptions and uriOptions.global then
      -- Keep pool total under self.poolOptions[uri].total
      -- Or a leak is possible
      globalUriCounts[uri] = globalUriCounts[uri] or #self.pool[uri]
      if globalUriCounts[uri] > uriOptions.total then
        globalUriCounts[uri] = globalUriCounts[uri] - 1
        self.uri[goId] = nil
      end
    else
      self.uri[goId] = nil
    end
  end

  for uri, list in pairs(self.pool) do
    if self:isGlobal(uri) then
      for i = #list, 1, -1 do
        local go = list[i]
        if self:hasTag(go) then
          self:sleep(go)
        else
          table.remove(list, i)
          self:purge(go)
        end
      end
    else
      for i = #list, 1, -1 do
        local go = list[i]
        self:delSlepted(go)
      end
      self.pool[uri] = nil
      -- self.poolOptions[uri] = nil
    end
  end

  unity.endSample()
end

function m:stopAllAnimations(poolRoot)
  local animators = poolRoot:GetComponentsInChildren(Animator)
  for i = 1, #animators do
    local v = animators[i]
    v:Stop()
  end
end

function m:clearAll()
  self:purgePoolRoot(self.PoolRoot)
  self:purgePrefabs()

  self:clearLoaders()
  table.clear(self.comps)
  table.clear(self.pool)
  table.clear(self.poolOptions)
  table.clear(self.slepted)
  table.clear(self.uri)
  table.clear(self.rootUri)
end

function m:clearGlobal()
  self:purgePoolRoot(self.PoolRootGlobal)
  self:clearAll()
end

function m:purgePoolRoot(poolRoot)
  -- logd('purgePoolRoot')
  if poolRoot then
    -- The objects that have never been active might not have the OnDestroy callback upon scene switch
    -- Force exit to ensure the cleanup of the views
    self:exitBinders(poolRoot)
    local tempList = {}
    for v in poolRoot:iter() do
      tempList[#tempList + 1] = v
      -- logd('purgePoolRoot v=%s', tostring(v))
    end

    for _, v in ipairs(tempList) do
      v:destroy()
    end

    table.clear(tempList)
  end
end

function m:purgePrefabs(destroy)
  -- logd('GameObjectPool: purgePrefabs destroy=%s', tostring(destroy))
  local prefabs = self.prefabs
  for uri, prefab in pairs(prefabs) do
    if destroy then
      Destroy(prefab)
    end
    prefabs[uri] = nil
  end
end

function m:purge(go)
  -- logwarn('purge gameObject in pool %s(%s)', go:GetInstanceID(), go:getName())
  self:delTag(go)
  self:delSlepted(go)
  self:delComps(go)
  go:destroy()
end

function m:tag(go, uri)
  self.uri[go:GetInstanceID()] = uri
end

function m:hasTag(go)
  if is_null(go) then return false end
  return self.uri[go:GetInstanceID()] ~= nil
end

function m:getTag(go)
  return self.uri[go:GetInstanceID()]
end

function m:getRootTag(go)
  return self.rootUri[go:GetInstanceID()]
end

function m:getTagByInstanceId(instanceId)
  return self.uri[instanceId] or self.rootUri[instanceId]
end

function m:delTag(go)
  local instanceId = go:GetInstanceID()
  self.uri[instanceId] = nil
end

function m:delComps(go)
  self.comps[go:GetInstanceID()] = nil
end

function m:delSlepted(go)
  self.slepted[go:GetInstanceID()] = nil
end

function m:hasSlepted(go)
  return self.slepted[go:GetInstanceID()] ~= nil
end

function m:sleep(go, preloading)
  if is_null(go) then return end
  if is_null(self.PoolRoot) or is_null(self.PoolRootGlobal) then
    return -- fix editor exception
  end

  if self:hasSlepted(go) then return end
  self.slepted[go:GetInstanceID()] = true

  local uri = self:getTag(go)
  -- logd('go sleep go=%s uri=%s trace=%s', tostring(go), tostring(uri), debug.traceback())

  if not uri then
    self:purge(go)
    return
  end

  self.pool[uri] = self.pool[uri] or {}
  local max = MAX

  local poolOption = self.poolOptions[uri]

  if poolOption and poolOption.max then
    max = poolOption.max
  end

  if #self.pool[uri] >= max and not preloading then
    -- loge('%s max = %s, purging', uri, max)
    self:purge(go)
    return
  else
    -- loge('%s max = %s', uri, max)
  end

  table.insert(self.pool[uri], go)

  self.poolOptions[uri] = self.poolOptions[uri] or {}

  -- if game.editor() then
  --   local canvas = go:getComponent(Canvas)
  --   if canvas and canvas:get_renderMode() ~= 2 then
  --     go:updateUI3dCamerasVisibility(false)
  --     canvas:set_enabled(false)
  --   else
  --     go:setVisible(false)
  --   end
  -- end
  go:setVisible(false)
  go:setInteractable(false)

  if self:isGlobal(uri) then
    go:setParent(self.PoolRootGlobal, false)
  else
    go:setParent(self.PoolRoot, false)
  end

  -- logwarn('[GameObjectPool] %s(%s) has been recycled', go:get_name(), go:GetInstanceID())
end

function m:wake(go, options)
  options = options or DEFAULT_WAKE_OPTIONS

  go:setParent(nil, false)

  if not options.noActive then
    -- if game.editor() then
    --   local canvas = go:getComponent(Canvas)
    --   if canvas and canvas:get_renderMode() ~= 2 then
    --     local animators = go:GetComponentsInChildren(Animator)
    --     for i = 1, #animators do local v = animators[i]
    --       v:Rebind()
    --     end
    --   end
    -- end
    -- else
    if not go:isVisible() then
      go:setVisible(true)
    end
    -- end
    go:setInteractable(true)
  end

  self.slepted[go:GetInstanceID()] = nil
  -- logwarn('[GameObjectPool] %s(%s) has been reused', go:get_name(), go:GetInstanceID())
end

function m:getFromPool(uri)
  -- uri = uri:lower()
  self.pool[uri] = self.pool[uri] or {}
  self.poolOptions[uri] = self.poolOptions[uri] or {}

  if #self.pool[uri] > 0 then
    return table.remove(self.pool[uri], 1)
  end

  return nil
end

-- not used for now
--[[
function m:isRoot(go)
  return go == self.PoolRoot or go == self.PoolRootGlobal
end
]]

-- Components cache
-- since many gameobjects are cached, it's likely their components
-- havent changed before scene switch, especially for UI
-- this should speed up UI bindings significantly
local type = type
function m:getComponents(go, uri)
  local t = type(go)
  if t == 'table' then
    go = go.gameObject
  end
  if is_null(go) then return {} end

  local instanceId = go:GetInstanceID()
  local comps = self.comps[instanceId]

  -- tag the instance with uri
  if uri then
    self.rootUri[instanceId] = uri
  end

  if comps then
    -- logwarn('retrieved components for go %s from cache', instanceId)
    return comps
  end

  local compsList = go:GetComponents(Component)
  local comps = {}
  for _, c in ipairs(compsList) do
    local mt = getmetatable(c)
    if mt and mt.__typename then comps[mt.__typename] = c end
  end

  self.comps[instanceId] = comps
  return self.comps[instanceId]
end

-- for faster getting the component in every frame
function m:getComponent(go, compname)
  local comps = self:getComponents(go)
  return comps[compname]
end

function m:isGlobalInstance(instanceId)
  local uri = self:getTagByInstanceId(instanceId)
  if not uri then return false end
  return self:isGlobal(uri)
end

function m:isGlobal(uri)
  local o = self.poolOptions[uri]
  if o then return op.truth(o.global) end
  return false
end

function m:setGlobal(uri)
  local o = self.poolOptions[uri]
  if o then
    o.global = true
  else
    o = { global = true }
    self.poolOptions[uri] = o
  end

  if not o.total then
    o.total = 999999999
  end
end

function m:create(uri)
  uri = uri:lower()
  local go = self:getFromPool(uri)

  if is_null(go) then
    if uri == '_empty' then
      go = GameObject()
    else
      -- logd('GameObjectPool create from prefab: %s', peek(uri))
      local prefab = self:getPrefab(uri)
      if not_null(prefab) then
        go = GameObject.Instantiate(prefab)
        -- some gameObject is de-active in prefab
        -- activate it here
        if not go:isVisible() then
          go:setVisible(true)
        end
      else
        loge('gp:create uri %s not found', uri)
      end
    end

    if go then
      self:tag(go, uri)
    end
  else
    self:wake(go)
  end

  return go
end

function m:wrapSubmitFunc(uri, onComplete)
  return function (go)
    local canvas = go:getComponent(Canvas)
    if canvas then
      canvas:set_enabled(false)
      HeavyTaskQueue.submit('loading', tostring(go), function ()
        canvas:set_enabled(true)
        onComplete(go)
      end)
    else
      local trans = go:get_transform()
      local x, y, z = trans:positionXYZ()
      trans:set_position(Vector3(-1000, -1000, -1000))
      HeavyTaskQueue.submit('loading', tostring(go), function ()
        trans:set_position(Vector3(x, y, z))
        onComplete(go)
      end)
    end
  end
end

function m:createAsync(uri, onComplete, options)
  -- loge('gp:createAsync uri=%s %s ', tostring(uri), debug.traceback())
  options = options or DEFAULT_CREATE_OPTIONS
  uri = uri:lower()
  local go = self:getFromPool(uri)
  local skipHeavyQueue = options.skipHeavyQueue

  -- 如果需要从bundle里异步加载，则不进入heavyQueue，因为本来就是异步有时间差
  -- 第一次从bundle里load出来的需要立刻由相关的class做初始化处理，例如ParticleView
  -- 主场景的particleView需要立刻把FVParticleRoot disable掉，
  -- 否则如果有FVParticleScaling作为孩子特效就会乱, 因为FVParticleRoot在disable之前会update
  if is_null(go) and (uri:match('prefab/misc') or uri:match('prefab/model')) then
    skipHeavyQueue = true
  end

  if onComplete then
    if not skipHeavyQueue then
      onComplete = self:wrapSubmitFunc(uri, onComplete)
    else
      -- logd('%s skipHeavyQueue = true', uri)
    end
  else
    onComplete = function () end
  end

  if is_null(go) then
    if uri == '_empty' then
      go = GameObject()
      if options.noActive then go:setVisible(false) end
      self:tag(go, uri)
      onComplete(go)
    else
      self:getPrefabAsync(uri, function(prefab)
        if not_null(prefab) then
          go = GameObject.Instantiate(prefab)
          self:tag(go, uri)
          if options.noActive then
            go:setVisible(false)
          else
            go:setVisible(true)
          end
          onComplete(go)
        else
          loge('gp:createAsync %s not found %s', uri, debug.traceback())
        end
      end)
    end
  else
    self:wake(go, options)
    onComplete(go)
  end
end

-- create gameobjects in pools beforehand
function m:poolAsync(uri, total, global, max, onComplete)
  uri = uri:lower()
  total = total or 1
  max = max or MAX
  self.pool[uri] = self.pool[uri] or {}
  self.poolOptions[uri] = self.poolOptions[uri] or {global = global, total = total, max = max}

  local num = total - #self.pool[uri]
  if num <= 0 then return onComplete({}) end

  self:getPrefabAsync(uri, function(prefab)
    if is_null(prefab) then
      loge('prefab for %s is nil', uri)
      return onComplete({})
    end

    local name = table.last(uri:split('/'))
    local list = {}
    for i = 1, num do
      local go = GameObject.Instantiate(prefab)
      go:set_name(name .. '_pooled')
      if not go:isVisible() then go:setVisible(true) end
      self:tag(go, uri)
      self:sleep(go, true)
      table.insert(list, go)
    end
    onComplete(list)
  end)
end

function m:getPrefabLoader(uri)
  local loader = self.asyncs[uri]
  if not loader then
    loader = CachedAssetLoader.new(uri, self.prefabs, unity.loadPrefab, unity.loadPrefabAsync)
    self.asyncs[uri] = loader
  end
  return loader
end

function m:getPrefabAsync(uri, onComplete)
  local loader = self:getPrefabLoader(uri)
  loader:loadAsync(onComplete)
end

function m:getPrefab(uri)
  local loader = self:getPrefabLoader(uri)
  return loader:load()
end

function m:shouldRecycle(go)
  -- save mono memory for low-mem devices
  if QualityUtil.isMemoryTight() and game.platform == 'android' then return false end

  return self:hasTag(go)
end

-- force recycle the gameObject under a given tag
function m:forceRecycle(go, tag)
  self:tag(go, tag)
  self:recycle(go)
end

function m:recycle(go, options)
  local uri = self:getTag(go)
  if uri and is_null(go) then
    self:delTag(go)
    return
  end

  if uri and not self:hasSlepted(go) then
    -- dynamically created and binded children should be recycled as well
    -- like slots in a scrollview
    if options and options.ignoreBinders then
      -- do not exit binders
    else
      self:exitBinders(go, true)
    end

    -- For the immediate children, they might be created
    -- dynamically as well. e.g. the Projectile3D has 3 parts.
    -- each part has to be recycled
    for child in go:iter() do
      if self:shouldRecycle(child) then
        self:sleep(child)
      end
    end

    self:sleep(go, options)
  end
end






-- ViewFactory.lua: pooled view instances
-- other factory, e.g. FloatingTextFactory, ParticleFactory, can reuse this class functions

class('ViewFactory', function(self)
end)

local m = ViewFactory
local unity = unity

m.debug = nil
m.SCENE_TAG = '$scene'

local initGroups = function ()
  if m.groupOptions then return end

  local particleRoot = '/particles'
  local textRoot = '/floating_texts'
  local uiRoot = ui:root()

  m.groupOptions = {
    BusyView          = { clz = BusyView, initSize = 1, maxSize = 1, global = true, parent = uiRoot, },
    text_normal       = { clz = FloatingText, initSize = 4, maxSize = 8, parent = uiRoot, initParentName = m.SCENE_TAG, recycleParentName = m.SCENE_TAG },
    text_framed       = { clz = FramedFloatingText, initSize = 4, maxSize = 8, parent = uiRoot, initParentName = m.SCENE_TAG, recycleParentName = m.SCENE_TAG},
    text_framed_two   = { clz = FrameFloatingTextTwo, initSize = 4, maxSize = 8, parent = uiRoot, initParentName = m.SCENE_TAG, recycleParentName = m.SCENE_TAG},
    text_icon         = { clz = FloatingIconText, initSize = 4, maxSize = 8, parent = uiRoot, initParentName = m.SCENE_TAG, recycleParentName = m.SCENE_TAG},
    MainRoomView      = { clz = MainRoomView, initSize = 1, maxSize = 1, global = true, parent = uiRoot },
    CardView          = { clz = CardView, initSize = 54, maxSize = 54, global = true },
    -- InteractiveView   = { clz = InteractiveView, initSize = 3, maxSize = 3, global = true, parent = uiRoot },
  }

  -- save pool memory for memory tight devices
  if QualityUtil.isMemoryTight() then
    -- these views are too slow if not pooled
    local keepGroups = {
      BusyView = true,
    }
    for group, opts in pairs(m.groupOptions) do
      if not keepGroups[group] then
        opts.initSize = 0
        opts.maxSize = 0
        opts.global = nil
      end
    end
  end
end

local onDispose = function (view, pool)
  if m.debug then
    logd('[ViewFactory] onDispose %s go=%s tag=%s size=%s',
      tostring(view), tostring(view.gameObject), pool.tag, pool:size())
  end

  local groupOptions = pool.groupOptions
  if groupOptions and groupOptions.global then
    m.unprotectGlobal(view)

    if view.onDispose then view:onDispose() end

    m.objPools[view] = nil
  end

  view.class.destroy(view, true)
end

function m.initPools(initSize, maxSize)
  logd('[ViewFactory].initPools initSize=%s maxSize=%s', tostring(initSize), tostring(maxSize))
  m.clear()
  initGroups()
  m.initViewRoots()
  m.initGoMeta()

  m.initSize = initSize or 1
  m.maxSize = maxSize or 1

  if not m.allPools then
    m.allPools = {}
  end
  if not m.objPools then
    m.objPools = setmetatable({}, {__mode='kv'})
  end
end

function m.initViewRoots()
  if m.debug then
    logd('[ViewFactory] initViewRoots')
  end

  if not m.GlobalViewRoot then
    m.GlobalViewRoot = TransformCollection.create('GlobalViewRoot')
  end

  -- because we can start preloading before scene switch
  -- put view to SceneViewRoot when need to protect preloaded views from destroyed when scene switching
  if not m.SceneViewRoot then
    m.SceneViewRoot = TransformCollection.create('SceneViewRoot')
  end
end

function m.initGoMeta()
  local go = GameObject()
  local mt = getmetatable(go)
  GameObject.Destroy(go)

  rawset(mt, 'destroy', function (self)
    local view = mt.findLua(self)
    local pool = m.objPools[view]
    if pool and pool.groupOptions.global then
      -- avoid being destroyed by go:destroy()
      if m.debug then
        logd('[ViewFactory] do not destroy %s because its global', tostring(self))
      end
      return
    end

    mt.origDestroy(self)
  end)
end

function m.hasGroupOptions(clsName)
  return m.groupOptions[clsName] ~= nil
end

function m.poolMaxSize(group)
  return m.groupOptions[group].maxSize
end

function m.preloadAll(onlyGlobal)
  for group, opts in pairs(m.groupOptions) do
    if opts.global or (not onlyGlobal) then
      m.preload(group, opts)
    end
  end
end

function m.preload(group, opts)
  opts = opts or m.groupOptions[group]

  if opts.async then
    --
  else
    local view, _pool = m._make(group)
    view:destroy()
  end
end

function m.clear(includeGlobal)
  unity.beginSample('ViewFactory.clear')

  m.destroyAll(includeGlobal)
  local tempList = {}

  if m.GlobalViewRoot and includeGlobal then
    if m.debug then
      logd('[ViewFactory] destroy GlobalViewRoot')
    end

    for v in m.GlobalViewRoot:iter() do
      tempList[#tempList + 1] = v
      -- GameObject.Destroy(v)
    end
  end

  if m.SceneViewRoot then
    if m.debug then
      logd('[ViewFactory] destroy SceneViewRoot')
    end
    for v in m.SceneViewRoot:iter() do
      tempList[#tempList + 1] = v
      -- GameObject.Destroy(v)
    end
  end

  for _, v in ipairs(tempList) do
    GameObject.Destroy(v)
  end

  table.clear(tempList)

  unity.endSample()
end

function m.destroyAll(includeGlobal)
  if not m.allPools then return end

  if m.debug then
    logd('[ViewFactory] destroyAll includeGlobal=%s', tostring(includeGlobal))
  end

  for tag, pool in pairs(m.allPools) do
    local opts = pool.groupOptions
    if (not opts.global) or includeGlobal then
      if m.debug then
        logd('[ViewFactory] destroy pool %s', tag)
      end
      while pool:size() > 0 do
        if opts.async then
          pool:borrow(function (view, _)
            onDispose(view, pool)
          end)
        else
          local view = pool:borrow()
          onDispose(view, pool)
        end
      end
      -- delete the pool so that no view can be returned to the pool after destroyAll
      m.allPools[tag] = nil
    end
  end

  for view, pool in pairs(m.objPools) do
    local opts = pool.groupOptions
    if opts.global then
      -- avoid gameObject being destroyed when scene switch
      view:destroy()
    else
      m.objPools[view] = nil
    end
  end
end

function m.make(group, ...)
  if not m.allPools then
    loge('[ViewFactory] make group=%s but no pools!', group)
    return nil
  end

  local view, pool = m._make(group)
  view:reopenInit(...)
  return view, pool
end

function m._make(group, tag, params)
  tag = tag or group
  local pool = m.allPools[tag]

  if not pool then
    local opts = m.groupOptions[group] or {}
    if m.debug then
      assert(opts.async ~= true, 'group should not have async flag!')
    end
    if m.debug then
      logd('[ViewFactory] create pool group=%s tag=%s', group, tag)
    end

    pool = Pool.new(function ()
      local view
      if params then
        view = opts.clz.new(unpack(params))
      elseif opts.params then
        view = opts.clz.new(unpack(opts.params))
      else
        view = opts.clz.new()
      end

      return m.initView(view, tag, opts)
    end,

    {tag = tag,
    initSize = opts.initSize or m.initSize,
    maxSize = opts.maxSize or m.maxSize,
    enforceMax = opts.enforceMax,
    setObjectMt = opts.setObjectMt,
    objectMt = opts.clz,
    onDispose = onDispose,
    noInit = true, })

    pool.groupOptions = opts
    m.allPools[tag] = pool

    pool:initPool()
  end

  local view = pool:borrow()
  if m.debug then
    logd('[ViewFactory] borrow view=%s group=%s tag=%s', tostring(view), group, tag)
  end
  m.reopenInitCommon(view, pool)
  return view, pool
end

function m.makeAsync(group, tag, bundleFile, onComplete, a1, a2, a3, a4, a5)
  local pool = m.allPools[tag]


  if not pool then
    local opts = m.groupOptions[group]
    if m.debug then
      assert(opts.async == true, 'group should have async flag!')
    end
    if m.debug then
      logd('[ViewFactory] create async pool group=%s tag=%s', group, tag)
    end

    pool = AsyncPool.new(function (onCreate)
      if m.debug then
        logd('[ViewFactory] loading async bundle=%s', tostring(bundleFile))
      end

      local skipHeavyQueue = false

      -- when loading, skip the heavy queue, to allow the created gameObjects to be handled
      -- immediately, to avoid being deleted during scene loading
      if ui.loading then
        skipHeavyQueue = true
      end

      gp:createAsync(bundleFile, function(go)
        uoc:setAttr(go, 'bundleFile', bundleFile)
        local view
        if opts.params then
          view = opts.clz.new(go, unpack(opts.params))
        else
          view = opts.clz.new(go)
        end
        m.initView(view, tag, opts)
        onCreate(view)
      end, {skipHeavyQueue = skipHeavyQueue})
    end,
    { tag = tag,
      initSize = opts.initSize or m.initSize,
      maxSize = opts.maxSize or m.maxSize,
      enforceMax = opts.enforceMax,
      setObjectMt = opts.setObjectMt,
      objectMt = opts.clz,
      onDispose = onDispose,
      noInit = true, })

    pool.groupOptions = opts
    m.allPools[tag] = pool

    pool:initPool()
  end

  -- return value is nil
  return pool:borrow(function (view, pool)
    if m.debug then
      logd('[ViewFactory] borrow async view=%s group=%s tag=%s', tostring(view), group, tag)
    end
    m.reopenInitCommon(view, pool)
    view:reopenInit(a1, a2, a3, a4, a5)
    if onComplete then onComplete(view, pool) end
  end)
end

function m.initView(view, tag, opts)
  if opts.global then
    view.gameObject:setParent(m.GlobalViewRoot)
  elseif opts.initParentName == m.SCENE_TAG then
    view.gameObject:setParent(m.SceneViewRoot)
  end

  if m.debug then
    logd('[ViewFactory] created view=%s go=%s tag=%s', tostring(view), tostring(view.gameObject), tag)
  end

  -- never recycle into GameObjectPool when exitBinders
  -- NOTE: if children gameObjects have been tagged, the tags are not deleted here
  gp:delTag(view.gameObject)

  view.destroy = function (view)
    if view.destroyed then return end

    local pool = m.allPools[tag]
    if pool then
      view:reopenExit()
      m.reopenExitCommon(view, pool)
      pool:recycle(view)
    else
      if m.debug then
        logd('[ViewFactory] destroy async: pool is nil view=%s go=%s',
          tostring(view), tostring(view.gameObject))
      end
    end
  end

  if opts.global then
    m.protectGlobal(view, view.destroy)
  end

  view:setVisible(false)
  return view
end

local defaultDestroyFunc = function (view) end

function m.protectGlobal(view, destroyFunc)
  destroyFunc = destroyFunc or defaultDestroyFunc

  -- NOTE we check if view is pooled in forceExit()
  view.destroy = destroyFunc
  view.onDestroy = destroyFunc
  view.cleanup = destroyFunc
  view.exit = destroyFunc
end

function m.unprotectGlobal(view)
  view.destroy = nil
  view.onDestroy = nil
  view.cleanup = nil
  view.exit = nil
end

function m.reopenInitCommon(view, pool)
  if m.debug then
    logd('[ViewFactory] reopenInitCommon view=%s tag=%s', tostring(view), pool.tag)
  end

  -- 创建失败，到这里的时候view是nil
  if not view then
    loge("view is nil!")
    return
  end

  local opts = pool.groupOptions
  if opts.parent then
    view:setParent(opts.parent)
  end

  --Apply scale
  -- if view then
  --   ui:setupCanvasScale(view.canvas, view.canvasScaler, view:reverseFixedRatio())
  -- end

  m.objPools[view] = pool
  view:setVisible(true)
  view.destroyed = nil
end

function m.reopenExitCommon(view, pool)
  view:setVisible(false)
  view.destroyed = true

  local opts = pool.groupOptions
  if m.debug then
    logd('[ViewFactory] reopenExitCommon view=%s tag=%s global=%s trace=%s',
      tostring(view), pool.tag, tostring(opts.global), debug.traceback())
  end

  if opts.global then
    view.gameObject:setParent(m.GlobalViewRoot)
  else
    m.objPools[view] = nil

    if opts.recycleParentName and opts.recycleParentName == m.SCENE_TAG then
      view.gameObject:setParent(m.SceneViewRoot)
    end
  end
end


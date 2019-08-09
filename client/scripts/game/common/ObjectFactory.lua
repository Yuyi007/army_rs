
-- ObjectFactory.lua: pooled lua class objects
-- other factory, e.g. PlayerStateMachine can reuse this class functions

class('ObjectFactory', function(self)
end)

local m = ObjectFactory
local unity = unity

m.debug = nil

local initGroups = function ()
  if m.groupOptions then return end

  m.groupOptions = {
    --to do trigger model
    EfxLoadTask = { clz = EfxLoadTask, initSize = 6, maxSize = 36, global = true, },
  }
end

local onDispose = function (obj, pool)
  if m.debug then
    logd('[ObjectFactory] onDispose %s tag=%s size=%s',
      tostring(obj), pool.tag, pool:size())
  end
end

function m.initPools(initSize, maxSize)
  logd('[ObjectFactory].initPools initSize=%s maxSize=%s', tostring(initSize), tostring(maxSize))
  m.clear()
  initGroups()

  m.initSize  = initSize or 1
  m.maxSize   = maxSize or 1

  if not m.allPools then
    m.allPools = {}
  end
  if not m.objPools then
    m.objPools = setmetatable({}, {__mode='kv'})
  end
end

function m.clear(includeGlobal)
  unity.beginSample('ObjectFactory.clear')

  m.destroyAll(includeGlobal)

  unity.endSample()
end

function m.preloadAll(onlyGlobal)
  for group, opts in pairs(m.groupOptions) do
    if opts.global or (not onlyGlobal) then
      m.preload(group, opts)
    end
  end
end

function  m.preload(group, opts)
  local obj, _pool = m._make(group)
  m.recycle(obj)
end

function m.destroyAll(includeGlobal)
  if not m.allPools then return end

  if m.debug then
    logd('[ObjectFactory] destroyAll includeGlobal=%s', tostring(includeGlobal))
  end

  for tag, pool in pairs(m.allPools) do
    local opts = pool.groupOptions
    if (not opts.global) or includeGlobal then
      logd('[ObjectFactory] destroy pool %s', tag)
      while pool:size() > 0 do
        local obj = pool:borrow()
        onDispose(obj, pool)
      end
    end
  end
end

function m.make(group, ...)
  local obj, pool = m._make(group)
  if obj.reopenInit then
    obj:reopenInit(...)
  end
  return obj, pool
end

function m._make(group, tag)
  tag = tag or group
  local pool = m.allPools[tag]

  if not pool then
    local opts = m.groupOptions[group]
    if m.debug then
      logd('[ObjectFactory] create pool group=%s tag=%s', group, tag)
    end

    pool = Pool.new(function ()
      local obj = opts.clz.new()
      if m.debug then
        logd('[ObjectFactory] created obj=%s group=%s tag=%s', tostring(obj), group, tag)
      end
      return obj
    end,
    {tag = tag,
    initSize = opts.initSize or m.initSize,
    maxSize = opts.maxSize or m.maxSize,
    enforceMax = (opts.enforceMax == true and true or false),
    objectMt = opts.clz,
    onDispose = onDispose })

    pool.groupOptions = opts
    m.allPools[tag] = pool
  end

  local obj = pool:borrow()
  if m.debug then
    logd('[ObjectFactory] borrow obj=%s group=%s tag=%s', tostring(obj), group, tag)
  end
  m.objPools[obj] = pool
  return obj, pool
end

function m.recycle(obj)
  local pool = m.objPools[obj]
  if pool then
    if m.debug then
      logd('[ObjectFactory] recycle obj=%s trace=%s', tostring(obj), debug.traceback())
    end
    m.objPools[obj] = nil
    if obj.reopenExit then
      obj:reopenExit()
    end
    pool:recycle(obj)
  else
    if m.debug then
      logd('[ObjectFactory] destroy: pool is nil obj=%s', tostring(obj))
    end
  end
end

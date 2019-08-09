
local tracemem = rawget(_G, 'TRACE_MEM')

-- assign a special metatable to pooled object to avoid programming error.
local pooledError = function (t)
  error(string.format('you cannnot use a pooled object (%s)!', tostring(t)))
end

local pooledMt = {
  __add = function (t, t1) pooledError(t) end,
  __mul = function (t, t1) pooledError(t) end,
  __sub = function (t, t1) pooledError(t) end,
  __div = function (t, t1) pooledError(t) end,
  __unm = function (t, t1) pooledError(t) end,
  __pow = function (t, t1) pooledError(t) end,
  __concat = function (t, t1) pooledError(t) end,
  __le = function (t, t1) pooledError(t) end,
  __lt = function (t, t1) pooledError(t) end,
  __eq = function (t, t1) pooledError(t) end,
  -- __tostring = function (t) pooledError(t) end,
  __index = function (t, k, v) pooledError(t) end,
  __newindex = function (t, k) pooledError(t) end,
}

-- A general pool, always ensure borrow succeeds
class('Pool', function (self, create, opts)
  opts = table.merge({
    initSize = 8,
    maxSize = 64,
  }, opts)
  
  self.id = #Pool.pools
  self.create = create
  self.tag = opts.tag or string.format('pool_%d', self.id)
  self.tag = tostring(self.tag)
  self.initSize = opts.initSize
  self.maxSize = opts.maxSize
  self.enforceMax = (opts.enforceMax == true and true or false)
  self.setObjectMt = (opts.setObjectMt ~= false and true or false)
  
  assert(self.initSize <= self.maxSize, 'init size too large!')
  
  self.lentSize = 0
  self.maxLentSize = 0
  self.onDispose = opts.onDispose
  self.objectMt = opts.objectMt; opts.objectMt = nil
  self.pond = {}
  
  if tracemem then traceMemory('pool %s new', self.tag) end
  
  if not opts.noInit then
    -- self:initPool()
  end
  
  Pool.register(self)
  
  if tracemem then traceMemory('pool %s after constructor', self.tag) end
end)

local m = Pool
local Pool = Pool
m.pools = {}

function m.register(pool)
  local pools = m.pools
  local idx = #pools + 1
  for i = 1, #pools do
    local p = pools[i]
    if p.tag == pool.tag then
      idx = i
      break
    end
  end
  pools[idx] = pool
end

function m.destroy(tag)
  local pools = m.pools
  for i = 1, #pools do
    local pool = pools[i]
    if pool.tag == tag then
      table.remove(pools, i)
      pool:exit()
      return
    end
  end
end

function m.getPool(tag)
  local pools = m.pools
  for i = 1, #pools do
    local pool = pools[i]
    if pool.tag == tag then
      return pool
    end
  end
  return nil
end

function m:initPool()
  local pond = self.pond
  if #pond > 0 then
    error(string.format("pool[%s]: already inited!", self.tag))
  end
  
  logd('pool[%s]: init=%d max=%d setObjectMt=%s', self.tag,
  self.initSize, self.maxSize, tostring(self.setObjectMt))
  
  if self.setObjectMt then
    -- Note that checking of object validity has a non-negligible overhead
    -- on performance, the call to getmetatable() and setmetatable() are expensive.
    assert(self.objectMt, string.format('pool[%s]: objectMt should not be nil!', self.tag))
  end
  
  for i = 1, self.initSize do
    local object = self.create()
    --Make onDestroy avoid being called while quit game
    if object.binder then
      object.binder.Pooled = true
    end
    
    if self.setObjectMt then setmetatable(object, pooledMt) end
    pond[i] = object
  end
end

function m:exit()
  self.pond = nil
  self.objectMt = nil
end

-- make sure borrow always succeeds
function m:borrow()
  local pond = self.pond
  local count = #pond
  local object
  if count > 0 then
    object = pond[count]
    if self.setObjectMt then setmetatable(object, self.objectMt) end
    if object.binder then
      object.binder.Pooled = false
    end
    pond[count] = nil
  else
    -- when pool size exceeds max size, the pool is
    -- partly degraded as no pool
    if not self.enforceMax or self.lentSize < self.maxSize then
      object = self.create()
    end
  end
  
  if object then
    self.lentSize = self.lentSize + 1
    if self.lentSize > self.maxLentSize then
      self.maxLentSize = self.lentSize
    end
  else
    -- loge('not borrowing')
  end
  
  return object
end

function m:recycle(object)
  local pond = self.pond
  local count = #pond
  local maxSize = self.maxSize
  if count < maxSize then
    if object.binder then
      object.binder.Pooled = true
    end
    
    if self.setObjectMt then setmetatable(object, pooledMt) end
    pond[count + 1] = object
    
  else
    if game.debug > 0 then
      -- logd('pool[%s]: size %d limit to %d', self.tag, count, maxSize)
    end
    for i = maxSize + 1, count do
      pond[i] = nil
    end
    if self.setObjectMt then setmetatable(object, self.objectMt) end
    local onDispose = self.onDispose
    if onDispose then onDispose(object, self) end
  end
  
  self.lentSize = self.lentSize - 1
end

function m:size()
  return #self.pond
end

function m:clear()
  table.clear(self.pond)
end

-- An async pool, allow to create object with async callbacks
class('AsyncPool', function (self, create, opts)
end, Pool)

local m = AsyncPool

function m:initPool()
  local pond = self.pond
  if #pond > 0 then
    error(string.format("pool[%s]: already inited!", self.tag))
  end
  
  logd('pool[%s]: init=%d max=%d setObjectMt=%s', self.tag,
  self.initSize, self.maxSize, tostring(self.setObjectMt))
  
  self.ready = false
  self.pending = {}
  
  local onReady = function ()
    self.ready = true
    local pending = self.pending
    if game.debug > 0 then
      -- logd('pool[%s] ready now, size=%d pending=%d', self.tag, self.initSize, #pending)
    end
    for j = 1, #pending do
      self:borrow(pending[j])
      pending[j] = nil
    end
  end
  
  local doInitMt = function (doNext)
    if self.setObjectMt then
      assert(self.objectMt, string.format('pool[%s]: objectMt should not be nil!', self.tag))
    end
    doNext()
  end
  
  local doInit = function ()
    if self.initSize > 0 then
      for i = 1, self.initSize do
        self.create(function (object)
          if object.binder then
            object.binder.Pooled = true
          end
          if self.setObjectMt then setmetatable(object, pooledMt) end
          pond[i] = object
          if #pond == self.initSize then onReady() end
        end)
      end
    else
      onReady()
    end
  end
  
  doInitMt(doInit)
end

-- make sure borrow always succeeds
function m:borrow(onComplete)
  local pond = self.pond
  local count = #pond
  
  local onBorrowComplete = function (object)
    self.lentSize = self.lentSize + 1
    if self.lentSize > self.maxLentSize then
      self.maxLentSize = self.lentSize
    end
    
    -- logd('[%s] lentSize=%s maxLentSize=%s size=%s trace=%s',
    --   self.tag, self.lentSize, self.maxLentSize, #self.pond, debug.traceback())
    onComplete(object, self)
  end
  
  if not self.ready then
    if game.debug > 0 then
      -- logd('pool[%s] not ready, size=%d initSize=%d', self.tag, count, self.initSize)
    end
    local pending = self.pending
    pending[#pending + 1] = onBorrowComplete
    return false
  end
  
  local object
  if count > 0 then
    object = pond[count]
    if self.setObjectMt then setmetatable(object, self.objectMt) end
    
    if object.binder then
      object.binder.Pooled = false
    end
    
    pond[count] = nil
    onBorrowComplete(object)
  else
    if not self.enforceMax or self.lentSize < self.maxSize then
      self.create(onBorrowComplete)
    else
      return false
    end
  end
  
  return true
end

-- A frame-based pool, all objects should be recycled at the end of the frame
class('FramePool', function (self, create, opts)
  self.outPond = {}
  FramePool.register(self)
end, Pool)

local m = FramePool
m.pools = {}

function m.register(pool)
  local pools = m.pools
  local idx = #pools + 1
  for i = 1, #pools do
    local p = pools[i]
    if p.tag == pool.tag then
      idx = i
      break
    end
  end
  pools[idx] = pool
end

function m.destroy(tag)
  Pool.destroy(tag)
  
  local pools = m.pools
  for i = 1, #pools do
    local pool = pools[i]
    if pool.tag == tag then
      table.remove(pools, i)
      pool:exit()
      return
    end
  end
end

-- make sure borrow always succeeds
function m:borrow()
  local pond = self.pond
  local count = #pond
  local outPond = self.outPond
  local object
  if count > 0 then
    object = pond[count]
    if self.setObjectMt then setmetatable(object, self.objectMt) end
    
    pond[count] = nil
  else
    -- when pool size exceeds max size, the pool is
    -- partly degraded as no pool
    object = self.create()
  end
  
  outPond[#outPond + 1] = object
  
  self.lentSize = self.lentSize + 1
  if self.lentSize > self.maxLentSize then
    self.maxLentSize = self.lentSize
  end
  
  -- logd('pool[%s] borrow object=%s', self.tag, peek(object))
  return object
end

-- this should be called at end of every frame, to recycle all out-lent objects
function m:recycleAll()
  local pond = self.pond
  local count = #pond
  local outPond = self.outPond
  local outPondCount = #outPond
  local maxSize = self.maxSize
  local remain = maxSize - count
  
  -- logd('pool[%s] recycleAll outPondCount=%d', self.tag, outPondCount)
  
  if outPondCount > remain and game.debug > 0 then
    -- display a warning
    -- logd('pool[%s]: out=%d size=%d maxSize=%d', self.tag, outPondCount, count, maxSize)
  end
  
  for i = 1, remain do
    local object = outPond[i]
    if not object then break end
    
    if self.setObjectMt then setmetatable(object, pooledMt) end
    pond[count + i] = object
    outPond[i] = nil
  end
  
  for i = remain + 1, outPondCount do
    outPond[i] = nil
  end
  
  self.lentSize = 0
end

function m:recycle(object)
  error(string.format('pool[%s]: FramePool does not support recycle()', self.tag))
end

-- A fixed interval frame-based pool
class('FixedFramePool', function(self, create, opts)
end, FramePool)

-- A reference-counting-based pool, objects reference count are managed by retain() and release()
class('RefCountPool', function (self, create, opts)
end, Pool)

local m = RefCountPool

function m:borrow()
  local object = Pool.borrow(self)
  object._refCount = 1
  -- logd('pool[%s] borrow object=%s', self.tag, peek(object))
  return object
end

function m:retain(object)
  object._refCount = object._refCount + 1
  -- logd('pool[%s] retain=%d object=%s', self.tag, object._refCount, peek(object))
end

function m:release(object)
  object._refCount = object._refCount - 1
  -- logd('pool[%s] release=%d object=%s', self.tag, object._refCount, peek(object))
  if object._refCount == 0 then
    -- logd('pool[%s] recycle object=%s', self.tag, peek(object))
    self:recycle(object)
    return true
  end
  return false
end

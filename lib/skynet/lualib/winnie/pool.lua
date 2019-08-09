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

  if self.setObjectMt then
    -- Note that checking of object validity has a non-negligible overhead
    -- on performance, the call to getmetatable() and setmetatable() are expensive.
    assert(self.objectMt, string.format('pool[%s]: objectMt should not be nil!', self.tag))
  end

  for i = 1, self.initSize do
    local object = self.create()
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
   skynet.error("Borrow object failed!!!")
  end

  return object
end

function m:recycle(object)
  if object.onRecycle then
    object:onRecycle()
  end

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
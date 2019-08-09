-- We could use this to cache gc-instensive attributes of unity objects
-- like gameObject.name, gameObject.tag or user defined attributes to be associated with a unity object
-- Use the cached version: gameObject:getName(), gameObject:getTag() which has been put into
-- GameObjectDecorator

class('UnityObjectCache', function(self)
  self:init()
end)

local m = UnityObjectCache
local WEAK_VAL = {__mode='v'}
local EMPTY = {}

local unity = unity
local string = string
local setmetatable = setmetatable

function m:init()
  self.allCacheTables = {
    attrs = setmetatable({}, {__mode='k'}),
    custom = setmetatable({}, {__mode='k'}),
    comps = setmetatable({}, {__mode='k'}),
  }
end

function m:clear()
  unity.beginSample('UnityObjectCache.clear')

  for tag, cacheTable in pairs(self.allCacheTables) do
    if tag ~= 'custom' then
      for go, cache in pairs(cacheTable) do
        -- logd('UnityObjectCache: clear go=%s', tostring(go))
        -- if not gp:isGlobalInstance(go:GetInstanceID()) then
          table.clear(cache)
          cacheTable[go] = nil
        -- end
      end
    end
  end

  unity.endSample()
end

function m:cache(o, t, value)
  local cache = self:getCache(o)
  cache[t] = value
  return value
end

function m:getCustomAttrCache(o)
  local cacheTable = self.allCacheTables.custom
  local customCache = cacheTable[o]
  if not customCache then
    customCache = setmetatable({}, WEAK_VAL)
    cacheTable[o] = customCache
  end

  return customCache
end

function m:getCache(o)
  local cacheTable = self.allCacheTables.attrs
  local cache = cacheTable[o]
  if not cache then
    cache = setmetatable({}, WEAK_VAL)
    cacheTable[o] = cache
  end

  return cache
end

function m:getAttr(o, attr, existingAttr)
  -- if is_null(o) then return nil end
  local cache = self:getCache(o)
  if nil ~= cache[attr] then return cache[attr] end

  -- if it's an existing attribute on the unity object cache it here directly
  if existingAttr then
    cache[attr] = o[attr]
  end

  return cache[attr]
end

function m:setAttr(o, attr, value)
  -- if is_null(o) then return end
  local cache = self:getCache(o)
  cache[attr] = value
end

-- This should only be used for the components not likely to change
-- like ParticleSystem ParticleSystemRenderer
function m:getComponentsInChildren(o, comp)
  -- if is_null(o) then return EMPTY end
  local cacheTable = self.allCacheTables.comps
  local cache = cacheTable[o]
  if not cache then
    cache = setmetatable({}, WEAK_VAL)
    cacheTable[o] = cache
  end

  local comps = cache[comp]
  if comps then return comps end
  comps = o:GetComponentsInChildren(comp, true)
  cache[comp] = comps
  return comps
end

function m:getComponent(o, comp)
  -- if is_null(o) then return nil end
  local cache = self:getCache(o)
  local c = cache[comp]
  if not_null(c) then return c end
  cache[comp] = o:GetComponent(comp)
  return cache[comp]
end

function m:addComponent(o, comp)
  -- if is_null(o) then return nil end
  local cache = self:getCache(o)
  local c = cache[comp]
  if not_null(c) then return c end
  c = o:GetComponent(comp) or o:AddComponent(comp)
  cache[comp] = c
  return c
end

function m:delComponent(o, comp)
  local cache = self:getCache(o)
  local c = cache[comp] or o:GetComponent(comp)
  -- if is_null(c) then return end
  Destroy(c)
  cache[comp] = nil
end

function m:clearCache(o)
  -- logd('UnityObjectCache: clearCache o=%s', tostring(o))
  for tag, cacheTable in pairs(self.allCacheTables) do
    local cache = cacheTable[o]
    if cache then table.clear(cache) end
  end
end



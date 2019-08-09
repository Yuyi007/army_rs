
if not rawget(_G, 'TransformCollectionData') then
  logd("TransformCollection: init TransformCollectionData")
  rawset(_G, 'TransformCollectionData', {
  })
end

-- This class tries to mimic a unity parent Transform, for grouping together a series of transforms logically,
-- but is much faster than using a parent Transform because there is no need to call SetParent

class('TransformCollection', function (self)
end)

local m = TransformCollection
local uoc
local unity = unity
local GameObject = GameObject
local IsNull = Slua.IsNull

m.debug = nil
m.useParentTransforms = false -- fallback to parent transforms
m.allCollections = rawget(_G, 'TransformCollectionData')

function m.setGlobals()
  uoc = rawget(_G, 'uoc')
end

function m.onClassReloaded(_clz)
  m.setGlobals()
end

-- this is 'findOrCreate' actually
function m.create(name, global)
  if global == nil then global = true end

  if m.useParentTransforms or game.platform == 'editor' then
    -- fallback to unity Transform
    local go = unity.findCreateGameObject('/' .. name)

    if global then
      GameObject.DontDestroyOnLoad(go)
    end

    return go
  else
    -- use table to record group of transforms logically, faster than unity Transform
    local cur = m.findWithName(name)
    if cur then
      cur:exit()
      cur:init(name)
      return cur
    end

    local res = m.new()
    res:init(name)
    return res
  end
end

-- reset all instances, when new lua code is loaded
function m.resetAll()
  for item, _v in pairs(m.allCollections) do
    item:exit()
    setmetatable(item, m)
    item:init(item.name)
  end
end

function m.hasCollection(obj)
  return m.allCollections[obj]
end

function m.findWithName(name)
  for item, _v in pairs(m.allCollections) do
    if item.name == name then
      return item
    end
  end
end

function m.removeFromAll(go)
  local trans = go:get_transform()
  local collection = uoc:getCustomAttrCache(trans).collection
  if m.debug then
    logd('[TransformCollection] removeFromAll trans=%s collection=%s %s',
      tostring(trans), (collection and collection.name or 'nil'), m.traceback())
  end
  if collection then
    collection:removeChild(trans)
  end
end

function m.protectAll()
  unity.beginSample('TransformCollection.protectAll')

  for item, _v in pairs(m.allCollections) do
    item:protect()
  end

  unity.endSample()
end

function m.unprotectAll()
  unity.beginSample('TransformCollection.unprotectAll')

  for item, _v in pairs(m.allCollections) do
    item:unprotect()
  end

  unity.endSample()
end

function m.traceback()
  -- return debug.traceback()
  return ''
end

--------------------------


function m:init(name)
  logd('[TransformCollection] init name=%s %s', name, m.traceback())

  self.name = name
  self.map = {}
  self.count = 0
  if self.visible == nil then self.visible = true end

  self.CollectionRoot = GameObject(self.name)
  GameObject.DontDestroyOnLoad(self.CollectionRoot)

  if m.debug then
    self.debugHandler = scheduler.schedule(function ()
      self:updateDebugInfo()
    end, 1, false, true)
  end

  m.allCollections[self] = true
end

function m:exit()
  logd('[TransformCollection] exit name=%s %s', tostring(self.name), m.traceback())

  if self.CollectionRoot then
    for go in self.CollectionRoot:iter() do
      logd('[TransformCollection] exit keep go=%s', tostring(go))
      go:get_transform():SetParent(nil, false)
      GameObject.DontDestroyOnLoad(go)
    end
    GameObject.Destroy(self.CollectionRoot)
    self.CollectionRoot = nil
  end

  if self.debugHandler then
    scheduler.unschedule(self.debugHandler)
    self.debugHandler = nil
  end

  self:clear()
end

function m:updateDebugInfo()
  self.CollectionRoot:set_name(string.format('%s (%d)', self.name, self.count))
end

function m:addChild(trans)
  if self.map[trans] then
    if m.debug then
      logd('[TransformCollection] name=%s addChild but already in map trans=%s count=%s %s',
        self.name, tostring(trans), self.count, m.traceback())
    end
    return
  end

  self.map[trans] = true
  self.count = self.count + 1

  if m.debug then
    logd('[TransformCollection] name=%s addChild trans=%s count=%s %s',
      self.name, tostring(trans), self.count, m.traceback())
    assert(trans:get_transform() == trans, 'you need to pass a transform as arg')
  end

  local customCache = uoc:getCustomAttrCache(trans)
  if customCache.collection then
    customCache.collection:removeChild(trans)
  end
  customCache.collection = self

  if not self.visible then
    if m.debug then
      logd('[TransformCollection] name=%s hide trans=%s', self.name, tostring(trans))
    end
    trans:get_gameObject():SetActive(false)
  end

  if self.isProtecting then
    trans:SetParent(self.CollectionRoot:get_transform(), false)
  else
    -- move views out of root game objects
    -- so it won't be destroyed when root game objects are destroyed
    if trans:get_parent() then
      trans:SetParent(nil, false)
    end
  end
end

function m:removeChild(trans)
  if not self.map[trans] then
    if m.debug then
      logd('[TransformCollection] name=%s removeChild but not in map trans=%s count=%s %s',
        self.name, tostring(trans), self.count, m.traceback())
    end
    return
  end

  self.map[trans] = nil
  self.count = self.count - 1

  if m.debug then
    logd('[TransformCollection] name=%s removeChild trans=%s count=%s %s',
      self.name, tostring(trans), self.count, m.traceback())
    if not IsNull(trans) then
      assert(trans:get_transform() == trans, 'you need to pass a transform as arg')
    end
  end

  local customCache = uoc:getCustomAttrCache(trans)
  if customCache.collection == self then
    customCache.collection = nil
  elseif customCache.collection then
    error(string.format('[TransformCollection] name=%s removeChild trans=%s but old collection is %s',
      self.name, tostring(trans), customCache.collection.name))
  end
end

function m:iter()
  local trans, val
  return function()
    trans, val = next(self.map, trans)
    if m.debug then
      logd('[TransformCollection] name=%s iter trans=%s val=%s', self.name, tostring(trans), tostring(val))
      assert(trans == nil or type(trans) == 'userdata')
    end
    if trans then
      return trans:get_gameObject()
    else
      return trans
    end
  end
end

function m:protect()
  if m.debug then
    logd('[TransformCollection] name=%s protect', self.name)
  end

  local rootTrans = self.CollectionRoot:get_transform()
  rootTrans:SetAsLastSibling()

  self.isProtecting = true

  for trans, _v in pairs(self.map) do
    if m.debug then
      logd('[TransformCollection] name=%s protect trans=%s', self.name, tostring(trans))
    end
    trans:SetParent(rootTrans, false)
  end
end

function m:unprotect()
  if m.debug then
    logd('[TransformCollection] name=%s unprotect', self.name)
  end

  self.isProtecting = nil

  for trans, _v in pairs(self.map) do
    if m.debug then
      logd('[TransformCollection] name=%s unprotect trans=%s', self.name, tostring(trans))
    end
    if IsNull(trans) then
      self:removeChild(trans)
    else
      trans:SetParent(nil, false)
    end
  end
end

function m:clear()
  if m.debug then
    logd('[TransformCollection] clear name=%s', self.name)
  end

  for trans, _v in pairs(self.map) do
    self:removeChild(trans)
  end
end

function m:setVisible(val)
  if m.debug then
    logd('[TransformCollection] name=%s set visible=%s', self.name, tostring(val))
  end

  self.visible = val
end

function m:GetComponentsInChildren(clz, includeInactive)
  includeInactive = (not not includeInactive)

  local res = {}
  for trans, _ in pairs(self.map) do
    if includeInactive or trans:get_gameObject():get_activeSelf() then
      if m.debug then
        logd('[TransformCollection] name=%s GetComponentsInChildren trans=%s', self.name, tostring(trans))
      end
      local comps = trans:GetComponentsInChildren(clz, includeInactive)
      for j = 1, #comps do
        res[#res + 1] = comps[j]
      end
    end
  end
  return res
end

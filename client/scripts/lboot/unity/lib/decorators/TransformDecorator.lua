class('TransformDecorator')

local m = TransformDecorator
local uoc

function m.decorate(o)
  local mt = getmetatable(o)
  local t = m.funcs(mt)
  for k, v in pairs(t) do
    rawset(mt, k, v)
  end
end

function m.setGlobals()
  uoc = rawget(_G, 'uoc')
end

function m.funcs(oldMt)
  local mt = {}
  local LuaUtils = LBoot.LuaUtils
  local TransformPositionXYZ = LuaUtils.TransformPositionXYZ

  function mt.getName(self)
    local name = uoc:getAttr(self, 'name', true)
    return name
  end

  function mt.setName(self, name)
    local oldName = self:getName()
    if oldName ~= name then
      self:set_name(name)
      uoc:cache(self, 'name', name)
    end
  end

  function mt.getTransform(self)
    local t = uoc:getAttr(self, 'transform', true)
    return t
  end

  function mt.getRoot(self)
    local t = uoc:getAttr(self, 'root')
    if not_null(t) then return t end
    return uoc:cache(self, 'root', self:get_root())
  end

  function mt.getComponent(self, comp)
    local t = uoc:getComponent(self, comp)
    return t
  end

  function mt.addComponent(self, comp)
    return self:get_gameObject():addComponent(comp)
  end

  function mt.find(self, path)

    local childPath = '__child__'..path
    local t = uoc:getAttr(self, childPath)
    if not_null(t) then return t end
    return uoc:cache(self, childPath, self:Find(path))
  end

  function mt.setActive(self, active)
    self:get_gameObject():setVisible(active)
  end

  function mt.setVisible(self, visible)
    self:get_gameObject():setVisible(visible)
  end

  function mt.isVisible(self)
    return self:get_gameObject():isVisible()
  end

  function mt.eq(self, other)
    if nil == other then return false end
    local otherTrans = other:get_transform()
    if nil == otherTrans then return false end
    return self:GetInstanceID() == otherTrans:GetInstanceID()
  end

  function mt.addChild(self, child, preservePos)
    if preservePos == nil then preservePos = false end
    child:get_transform():SetParent(self, preservePos)
  end

  function mt.setLocalScale(self, scaleFactor)
    self:set_localScale(Vector3(scaleFactor, scaleFactor, scaleFactor))
  end

  function mt.reset(self)
    self:set_localPosition(Vector3.static_zero)
    self:set_localRotation(Quaternion.static_identity)
    self:set_localScale(Vector3.static_one)
  end

  -- for compatibility for TransformCollection, always use setParent instead of SetParent
  function mt.setParent(self, parent, preservePos)
    if preservePos == nil then preservePos = false end

    TransformCollection.removeFromAll(self)

    if parent then
      if TransformCollection.hasCollection(parent) then
        parent:addChild(self, preservePos)
        return
      end

      self:SetParent(parent:get_transform(), preservePos)
    else
      self:SetParent(nil, preservePos)
    end
  end

  function mt.bindLua(self, luaTable)
    self:get_gameObject():bindLua(luaTable)
  end

  function mt.findLua(self)
    return self:get_gameObject():findLua()
  end

  -- make sure the x, y, z in the lossyScale are the same
  function mt.justifyScale(self, axis)
    axis = axis or 'x'
    local lossyScale = self:get_lossyScale()
    local x, y, z = lossyScale[1], lossyScale[2], lossyScale[3]
    -- no zero allowed
    if y == 0 then y = 0.000001 end
    if x == 0 then x = 0.000001 end
    if z == 0 then z = 0.000001 end
    local scalex, scaley, scalez = 1, 1, 1
    if axis == 'x' then
      scaley = x / y
      scalez = x / z
    elseif axis == 'y' then
      scalex = y / x
      scalez = y / z
    elseif axis == 'z' then
      scalex = z / x
      scaley = z / y
    end
    -- local realScale = lossyScale[axis]
    local newScale = Vector3.Scale(self:get_localScale(), Vector3(scalex, scaley, scalez))
    self:set_localScale(newScale)
  end

  -- a reverse iteration through the children
  function mt.iter(self)
    local i = self:get_childCount()
    return function()
      i = i - 1
      if i >= 0 then return self:GetChild(i) end
    end
  end

  function mt.first(self)
    if self:get_childCount() == 0 then return nil end
    return self:GetChild(0)
  end

  function mt.destroyChild(self, index)
    if self:get_childCount() == 0 then return end
    local t = self:GetChild(index)
    if nil ~= t then unity.destroy(t:get_gameObject()) end
  end

  function mt.findByName(self, name)
    -- 100x speed up than recursion in Lua
    local o = self:Find(name)
    if o then return o end

    for child in self:iter() do
      local t = child:findByName(name)
      if t then return t end
    end
  end

  -- use this wherever findByName won't suffice
  function mt.findByNameRecursively(self, name)
    local o = self:Find(name)
    if o then return o end

    for child in self:iter() do
      local t = child:findByNameRecursively(name)
      if t then return t end
    end

    return nil
  end

  function mt.destroyImdediateAllChildren(self)
    for v in self:iter() do
      GameObject.DestroyImediate(v:get_gameObject())
    end
  end

  function mt.findPath(self, t)
    local path = t:get_name()
    local parent = t:get_parent()
    while not self:eq(parent) and parent ~= nil do
      t = parent
      path = string.format('%s/%s', t:get_name(), path)
      parent = t:get_parent()
    end

    return path
  end

  function mt.destroy(self)
    self:get_gameObject():destroy()
  end

  function mt.createChild(self, name)
    local go = GameObject(name)
    go:get_transform():setParent(self, false)
  end

  -- struct members use frame pooling

  mt.position = oldMt.position
  mt.position[1] = function (self)
    local x, y, z = TransformPositionXYZ(self)
    local v = Vector3(x, y, z)
    return v
  end

  mt.positionXYZ = function (self)
    return TransformPositionXYZ(self)
  end

  mt.localPosition = oldMt.localPosition
  mt.localPosition[1] = function (self)
    local x, y, z = LuaUtils.TransformLocalPositionXYZ(self)
    local v = Vector3(x, y, z)
    return v
  end

  mt.forward = oldMt.forward
  mt.forward[1] = function (self)
    local x, y, z = LuaUtils.TransformForwardXYZ(self)
    local v = Vector3(x, y, z)
    return v
  end

  mt.right = oldMt.right
  mt.right[1] = function (self)
    local x, y, z = LuaUtils.TransformRightXYZ(self)
    local v = Vector3(x, y, z)
    return v
  end

  mt.up = oldMt.up
  mt.up[1] = function (self)
    local x, y, z = LuaUtils.TransformUpXYZ(self)
    local v = Vector3(x, y, z)
    return v
  end

  mt.eulerAngles = oldMt.eulerAngles
  mt.eulerAngles[1] = function (self)
    local x, y, z = LuaUtils.TransformEulerAnglesXYZ(self)
    local v = Vector3(x, y, z)
    return v
  end

  mt.localEulerAngles = oldMt.localEulerAngles
  mt.localEulerAngles[1] = function (self)
    local x, y, z = LuaUtils.TransformLocalEulerAnglesXYZ(self)
    local v = Vector3(x, y, z)
    return v
  end

  mt.lossyScale = oldMt.lossyScale
  mt.lossyScale[1] = function (self)
    local x, y, z = LuaUtils.TransformLossyScaleXYZ(self)
    local v = Vector3(x, y, z)
    return v
  end

  mt.localScale = oldMt.localScale
  mt.localScale[1] = function (self)
    local x, y, z = LuaUtils.TransformLocalScaleXYZ(self)
    local v = Vector3(x, y, z)
    return v
  end

  mt.rotation = oldMt.rotation
  mt.rotation[1] = function (self)
    local x, y, z, w = LuaUtils.TransformRotationXYZW(self)
    local v = Quaternion(x, y, z, w)
    return v
  end

  mt.localRotation = oldMt.localRotation
  mt.localRotation[1] = function (self)
    local x, y, z, w = LuaUtils.TransformLocalRotationXYZW(self)
    local v = Quaternion(x, y, z, w)
    return v
  end

  return mt
end

setmetatable(m, {__call = function(t, ...) m.decorate(...) end })
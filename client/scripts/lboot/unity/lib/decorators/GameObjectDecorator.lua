class('GameObjectDecorator')

local m = GameObjectDecorator
local uoc = rawget(_G, 'uoc')

function m.decorate(o)
  local mt = getmetatable(o)
  local t = m.funcs()
  for k, v in pairs(t) do
    rawset(mt, k, v)
  end
end

function m.setGlobals()
  uoc = rawget(_G, 'uoc')
end

function m.funcs()
  local mt = {}

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
    local transform = self:get_transform()
    local t = transform:getRoot()
    if t then
      return uoc:cache(self, 'root', t:get_gameObject())
    else
      return nil
    end
  end

  function mt.getComponent(self, comp)
    local t = uoc:getComponent(self, comp)
    return t
  end


  -- This should only be used for the components not likely to change
  -- like ParticleSystem ParticleSystemRenderer
  function mt.getComponentsInChildren(self, comp)
    local comps = uoc:getComponentsInChildren(self, comp)
    return comps
  end

  function mt.addComponent(self, comp)
    local t = uoc:addComponent(self, comp)
    return t
  end

  function mt.delComponent(self, comp)
    local t = uoc:delComponent(self, comp)
    return t
  end

  function mt.getTag(self)
    local tag = uoc:getAttr(self, 'tag', true)
    return tag
  end

  function mt.updateUI3dCamerasVisibility(self, realVisible)
    if game.editor() then
      -- in editor disabling cameras would result in frequent crashes
      return
    end

    if not_null(self) then
      local ui3dCullingMask = unity.getCullingMask('3DUI')
      local cameras = self:getComponentsInChildren(Camera)
      for i = 1, #cameras do
        local v = cameras[i]
        if v:get_cullingMask() == ui3dCullingMask then
          v:get_gameObject():setVisible(realVisible)
        end
      end
    end
  end

  function mt.destroy(self)
    -- logd('go destroy self=%s trace=%s', tostring(self), debug.traceback())
    if is_null(self) then return end

    local trans = self:get_transform()
    gp:exitBinders(self)
    self:setVisible(false)

    TransformCollection.removeFromAll(self)

    uoc:clearCache(self)
    uoc:clearCache(trans)
    BundlePathCacher.clearTransCache(self)

    GameObject.Destroy(self)
  end

  mt.origDestroy = mt.destroy

  function mt.setActive(self, active)
    local visible = not not active
    self:setVisible(visible)
  end

  function mt.setVisible(self, visible)
    visible = (not not visible)
    if not_null(self) then
    -- logd('%s setVisible %s, %s', self:getName(), peek(visible), debug.traceback())
      self:SetActive(visible)
    end
  end

  function mt.eq(self, other)
    return self:get_transform():eq(other:get_transform())
  end

  function mt.isVisible(self)
    return self:get_activeSelf()
  end

  function mt.isVisibleInScene(self)
    return self:get_activeInHierarchy()
  end

  function mt.setInteractable(self, interactable)
    -- logd('setInteractable self=%s interactable=%s %s', tostring(self),
    --   tostring(interactable), debug.traceback())
    local raycaster = mt.getComponent(self, UI.GraphicRaycaster)
    if raycaster then
      raycaster:set_enabled(interactable)
    end
  end

  function mt.addChild(self, child, preservePos)
    self:get_transform():addChild(child, preservePos)
  end

  function mt.setParent(self, parent, preservePos)
    self:get_transform():setParent(parent, preservePos)
  end

  function mt.setIdentity(self, go2)
    local t1 = self:getTransform()
    local t2 = go2:getTransform()
    t1:set_localPosition(t2:get_localPosition())
    t1:set_localRotation(t2:get_localRotation())
    t1:set_localScale(t2:get_localScale())
    self:set_name(go2:get_name())
  end

  function mt.resetTransform(self)
    self:get_transform():reset()
  end

  function mt.findLua(self)
    -- speed up findLua
    local t = uoc:getCustomAttrCache(self).luaTable
    if t then return t end

    local binder = self:getComponent(LuaBinderBehaviour)
    if binder then
      t = binder:get_Lua()
      if t then
        logd(string.format('findLua: %s fast lookup failed t=%s trace=%s', tostring(self), tostring(t), ''))
      end
      return t
    end
    return nil
  end

  function mt.bindLua(self, t)
    local binder = self:addComponent(LuaBinderBehaviour)

    uoc:getCustomAttrCache(self).luaTable = t
    binder:Bind(t)

    t.binder = binder
    return binder
  end

  -- mimic transform.find but the returned is a gameObject
  function mt.find(self, path)
    local childPath = '__child__'..path
    local t = uoc:getAttr(self, childPath)
    if not_null(t) then return t end

    local transform = self:get_transform()
    local t = transform:find(path)

    if not t then
      return nil
    end

    return uoc:cache(self, childPath, t:get_gameObject())
  end

  function mt.wasLayerFixed(self)
    local layerFixedBefore = uoc:getAttr(self, 'layerFixedBefore')
    return not not layerFixedBefore
  end

  function mt.setLayerFixed(self)
    uoc:setAttr(self, 'layerFixedBefore', true)
  end

  function mt.setLayer(self, layer, recursive)
    local layer0 = layer
    if type(layer) == 'string' then
      layer0 = unity.layer(layer)
    end

    if not layer0 then
      loge('%s gameObject.setLayer, layer %s not found', self:getName(), peek(layer))
      return
    end

    self:set_layer(layer0)

    if recursive then
      for child in self:get_transform():iter() do
        child:get_gameObject():setLayer(layer0, recursive)
      end
    end
  end

  function mt.setSkinnedMeshRendererLayers(self, layer)
    if type(layer) == 'string' then layer = unity.layer(layer) end
    local allSMRs = self:get_gameObject():GetComponentsInChildren(UnityEngine.SkinnedMeshRenderer)
    for i = 1, #allSMRs do
      local smr = allSMRs[i]
      if smr:get_gameObject():get_layer() ~= unity.layer('NeonLights') then
        smr:get_gameObject():setLayer(layer)
      end
    end
  end

  -- a reverse iteration through the children
  function mt.iter(self)
    local transform = self:get_transform()
    local i = transform:get_childCount()
    return function()
      i = i - 1
      if i >= 0 then return transform:GetChild(i):get_gameObject() end
    end
  end

  -- not a reverse iter
  function mt.iiter(self)
    local transform = self:get_transform()
    local length = transform:get_childCount()
    local i = -1
    return function()
      i = i + 1
      if i < length then return transform:GetChild(i):get_gameObject() end
    end
  end

  function mt.createChild(self, name)
    local go = GameObject(name)
    go:setParent(self, false)
  end

  return mt
end

setmetatable(m, {__call = function(t, ...) m.decorate(...) end })
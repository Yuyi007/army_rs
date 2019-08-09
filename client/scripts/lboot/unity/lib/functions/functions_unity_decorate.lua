local m = unity
local GameObject = UnityEngine.GameObject
local LuaBinderBehaviour = LBoot.LuaBinderBehaviour
local Vector3 = UnityEngine.Vector3
local Quaternion = UnityEngine.Quaternion
local Image = UnityEngine.UI.Image

function m.resetDecorate(classname)
  local t = classname:gsub('Decorator$', '')
  t = 'decorate'..t
  m.decorated['_'..t] = nil
end

function m.initDecorates()
  m.decorated = {}
  for k, decorator in pairs(_G) do
    if type(decorator) == 'table' and k:match('Decorator$') then
      local t = k:gsub('Decorator$', '')
      t = 'decorate'..t
      m[t] = function(o)
        if m.decorated['_'..t] then return end
        m.decorated['_'..t] = true
        decorator(o)
      end
    end
  end
end

function m.decorateCommon()
  m.decorateGo()
  m.decorateColor()
  m.decorateVector2()
  m.decorateVector3()
  m.decorateVector4()
  m.decorateQuaternion()
  m.decorateMatrix4x4()
  m.decorateTween()
end

function m.decorateGo()
  local go = GameObject('temp')
  local tr = go.transform
  local rect = go:AddComponent(UnityEngine.RectTransform)

  m.decorateGameObject(go)
  m.decorateTransform(tr)
  m.decorateRectTransform(rect)

  GameObject.Destroy(go)
end

function m.decorateTween()
  local chain = unity.createTweenChain()
  m.decorateGoTweenChain(chain)
  chain:destroy()
end

function m.decorateScrollSnap(scrollSnap)
  if m._scrollSnapDecorated then return end

  local mt = getmetatable(scrollSnap)

  local o = {}

  function o.setVisible(self, visible)
    self:get_gameObject():setVisible(visible)
  end

  function o.onDrag(self, e)
    self:OnDrag(e)
  end

  function o.onBeginDrag(self, e)
    self:OnBeginDrag(e)
  end

  function o.onEndDrag(self, e)
    self:OnEndDrag(e)
  end

  for k, v in pairs(o) do
    rawset(mt, k, v)
  end

  m._scrollSnapDecorated = true
end



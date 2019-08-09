class('Matrix4x4Decorator')

local m = Matrix4x4Decorator
local Matrix4x4 = UnityEngine.Matrix4x4
local Vector4 = UnityEngine.Vector4
local v0 = Vector4.zero
local NewMatrix4x4 = getmetatable(Matrix4x4).__call
local pool = FramePool.new(function () return m.create(Matrix4x4, v0, v0, v0, v0) end, {
  initSize = 0, maxSize = 128, tag = 'Matrix4x4', objectMt = getmetatable(NewMatrix4x4(Matrix4x4, v0, v0, v0, v0)),
})

function m.decorate()
  local typeMt = getmetatable(Matrix4x4)
  local mt = getmetatable(Matrix4x4.zero)

  local funcs = m.funcs()
  for k, v in pairs(funcs) do
    rawset(mt, k, v)
  end

  m.create = function (a, a1, a2, a3, a4)
    local res = NewMatrix4x4(a, a1, a2, a3, a4)
    for k, v in pairs(funcs) do
      rawset(res, k, v)
    end
    return res
  end

  for k, v in pairs(m.typeFuncs(typeMt, mt)) do
    rawset(typeMt, k, v)
  end
end

function m.typeFuncs(typeMt, objMt)
  local mt = {}

  mt.new = function ()
    return m.create(Matrix4x4)
  end

  mt.borrow = function () return pool:borrow() end

  if unity.useStructPooling then
    function mt.__call(t)
      local v = pool:borrow()
      return v
    end
  end

  function mt.newIdentity()
    local v = mt.new()
    local ident = Vector4(1, 1, 1, 1)
    v:SetColumn(0, ident)
    v:SetColumn(1, ident)
    v:SetColumn(2, ident)
    v:SetColumn(3, ident)
    return v
  end

  return mt
end

function m.funcs()
  local mt = {}

  return mt
end

setmetatable(m, {__call = function(t, ...) m.decorate(...) end })

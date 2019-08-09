class('Vector4Decorator')

local m = Vector4Decorator
local Vector4 = UnityEngine.Vector4
local NewVector4 = getmetatable(Vector4).__call
local pool = FramePool.new(function () return m.create(Vector4, 0, 0, 0, 0) end, {
  initSize = 0, maxSize = 128, tag = 'Vector4', objectMt = getmetatable(NewVector4(Vector4, 0, 0, 0, 0)),
})

function m.decorate()
  local typeMt = getmetatable(Vector4)
  local mt = getmetatable(Vector4.zero)

  local funcs = m.funcs(mt)
  for k, v in pairs(funcs) do
    rawset(mt, k, v)
  end

  m.create = function (a, b, c, d, e)
    local res = NewVector4(a, b, c, d, e)
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

  mt.new = function (x, y, z, w)
    if x and not y then
      y = x[2]; z = x[3]; w = x[4]; x = x[1]
    end
    return m.create(Vector4, x or 0, y or 0, z or 0, w or 0)
  end

  mt.borrow = function () return pool:borrow() end

  if unity.useStructPooling then
    function mt.__call(t, x, y, z, w)
      local v = pool:borrow()
      if not x then
        v[1] = 0; v[2] = 0; v[3] = 0; v[4] = 0
      elseif not y then
        v[1] = x[1]; v[2] = x[2]; v[3] = x[3]; v[4] = x[4]
      else
        v[1] = x; v[2] = y; v[3] = z; v[4] = w
      end
      return v
    end
  else
    function mt.__call(t, x, y, z, w)
      if not x then
        return NewVector4(t, 0, 0, 0, 0)
      elseif not y then
        return NewVector4(t, x[1], x[2], x[3], x[4])
      else
        return NewVector4(t, x, y, z, w)
      end
    end
  end


  return mt
end

function m.funcs(oldMt)
  local mt = {}

  function mt.set(self, x, y, z, w)
    if not x then
      self[1] = 0
      self[2] = 0
      self[3] = 0
      self[4] = 0
    elseif not y then
      self[1] = x[1]
      self[2] = x[2]
      self[3] = x[3]
      self[4] = x[4]
    else
      self[1] = x
      self[2] = y
      self[3] = z
      self[4] = w
    end
    return self
  end

  return mt
end

setmetatable(m, {__call = function(t, ...) m.decorate(...) end })

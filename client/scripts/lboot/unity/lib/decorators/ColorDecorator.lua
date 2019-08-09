class('ColorDecorator')

local m = ColorDecorator
local Color = UnityEngine.Color
local NewColor = getmetatable(Color).__call
local pool = FramePool.new(function () return m.create(Color, 0, 0, 0, 1) end, {
  initSize = 0, maxSize = 256, tag = 'Color', objectMt = getmetatable(NewColor(Color, 0, 0, 0, 1)),
})

function m.decorate()
  local typeMt = getmetatable(Color)
  local mt = getmetatable(Color.black)

  local funcs = m.funcs(mt)
  for k, v in pairs(funcs) do
    rawset(mt, k, v)
  end

  m.create = function (a, b, c, d, e)
    local res = NewColor(a, b, c, d, e)
    for k, v in pairs(funcs) do
      rawset(res, k, v)
    end
    return res
  end

  for k, v in pairs(m.typeFuncs(typeMt, mt)) do
    rawset(typeMt, k, v)
  end

  rawset(Color, 'static_black', Color.new(Color.black))
  rawset(Color, 'static_white', Color.new(Color.white))
end

function m.typeFuncs(typeMt, objMt)
  local mt = {}

  mt.new = function (r, g, b, a)
    if r and not g then
      g = r[2]; b = r[3]; a = r[4]; r = r[1]
    end
    return m.create(Color, r or 0, g or 0, b or 0, a or 1)
  end

  mt.borrow = function () return pool:borrow() end

  if unity.useStructPooling then
    function mt.__call(t, r, g, b, a)
      local v = pool:borrow()
      if not r then
        v[1] = 0; v[2] = 0; v[3] = 0; v[4] = 0
      elseif not g then
        v[1] = r[1]; v[2] = r[2]; v[3] = r[3]; v[4] = r[4] or 1
      else
        v[1] = r or 0; v[2] = g or 0; v[3] = b or 0; v[4] = a or 1
      end
      return v
    end
  else
    function mt.__call(t, r, g, b, a)
      if not r then
        return NewColor(t, 0, 0, 0, 1)
      elseif not g then
        return NewColor(t, r[1], r[2], r[3], r[4] or 1)
      else
        return NewColor(t, r, g, b, a or 1)
      end
    end
  end


  return mt
end

function m.funcs(oldMt)
  local mt = {}

  function mt.set(self, r, g, b, a)
    if not r then
      self[1] = 0
      self[2] = 0
      self[3] = 0
      self[4] = 1
    elseif not g then
      self[1] = r[1]
      self[2] = r[2]
      self[3] = r[3]
      self[4] = r[4]
    else
      self[1] = r
      self[2] = g
      self[3] = b
      self[4] = a
    end
    return self
  end

  return mt
end

setmetatable(m, {__call = function(t, ...) m.decorate(...) end })

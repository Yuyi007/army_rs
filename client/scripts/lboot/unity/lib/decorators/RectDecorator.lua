class('RectDecorator')

local m = RectDecorator
local Rect = UnityEngine.Rect
local NewRect = getmetatable(Rect).__call
-- local pool = FramePool.new(function () return NewRect(Rect, 0, 0, 0, 0) end, {
--   initSize = 4, maxSize = 128, tag = 'Rect', objectMt = getmetatable(NewRect(Rect, 0, 0, 0, 0)),
-- })

function m.decorate()
  -- slua now implement Rect as userdata

  local typeMt = getmetatable(Rect)
  for k, v in pairs(m.typeFuncs(typeMt)) do
    -- rawset(typeMt, k, v)
  end

  local mt = getmetatable(Rect())
  local funcs = m.funcs()
  for k, v in pairs(funcs) do
    -- rawset(mt, k, v)
  end
end

function m.typeFuncs(typeMt)
  local mt = {}

  -- mt.borrow = function () return pool:borrow() end

  if unity.useStructPooling then
    function mt.__call(t, x, y, width, height)
      local v = pool:borrow()
      local tp = type(x)
      if tp == 'table' or tp == 'userdata' then
        v.x = x.x; v.y = x.y; v.width = x.width; v.height = x.height
      elseif tp == 'nil' then
        v.x = 0; v.y = 0; v.width = 0; v.height = 0
      else
        v.x = x; v.y = y; v.width = width; v.height = height
      end
      return v
    end
  else
    function mt.__call(t, x, y, width, height)
      local tp = type(x)
      if tp == 'table' then
        return NewRect(t, x.x, x.y, x.width, x.height)
      elseif tp == 'nil' then
        return NewRect(t, 0, 0, 0, 0)
      else
        return NewRect(t, x, y, width, height)
      end
    end
  end


  mt.new = rawget(typeMt, '__call')

  return mt
end

function m.funcs()
  local mt = {}
  local LuaUtils = LBoot.LuaUtils

  function mt.set(self, x, y, width, height)
    local tp = type(x)
    if tp == 'table' or tp == 'userdata' then
      self.x = x.x
      self.y = x.y
      self.width = x.width
      self.height = x.height
    elseif tp == 'nil' then
      self.x = 0
      self.y = 0
      self.width = 0
      self.height = 0
    else
      self.x = x
      self.y = y
      self.width = width
      self.height = height
    end
    return self
  end

  -- struct members use frame pooling

  mt.center = oldMt.center
  mt.center[1] = function (self)
    local x, y = LuaUtils.RectCenterXY(self)
    local v = Vector2(x, y)
    return v
  end

  mt.max = oldMt.max
  mt.max[1] = function (self)
    local x, y = LuaUtils.RectMaxXY(self)
    local v = Vector2(x, y)
    return v
  end

  mt.min = oldMt.min
  mt.min[1] = function (self)
    local x, y = LuaUtils.RectMinXY(self)
    local v = Vector2(x, y)
    return v
  end

  mt.position = oldMt.position
  mt.position[1] = function (self)
    local x, y = LuaUtils.RectPositionXY(self)
    local v = Vector2(x, y)
    return v
  end

  mt.size = oldMt.size
  mt.size[1] = function (self)
    local x, y = LuaUtils.RectSizeXY(self)
    local v = Vector2(x, y)
    return v
  end

  return mt
end

setmetatable(m, {__call = function(t, ...) m.decorate(...) end })

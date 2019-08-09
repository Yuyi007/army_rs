class('RectTransformDecorator')

local m = RectTransformDecorator

function m.decorate(o)
  local mt = getmetatable(o)
  local t = m.funcs(mt)
  for k, v in pairs(t) do
    rawset(mt, k, v)
  end
end

function m.funcs(oldMt)
  local mt = {}
  local LuaUtils = LBoot.LuaUtils

  -- struct members use frame pooling

  mt.anchoredPosition = oldMt.anchoredPosition
  mt.anchoredPosition[1] = function (self)
    local x, y = LuaUtils.RectTransformAnchoredPositionXY(self)
    local v = Vector2(x, y)
    return v
  end

  mt.anchoredPosition3D = oldMt.anchoredPosition3D
  mt.anchoredPosition3D[1] = function (self)
    local x, y, z = LuaUtils.RectTransformAnchored3DPositionXYZ(self)
    local v = Vector3(x, y, z)
    return v
  end

  mt.anchorMax = oldMt.anchorMax
  mt.anchorMax[1] = function (self)
    local x, y = LuaUtils.RectTransformAnchorMaxXY(self)
    local v = Vector2(x, y)
    return v
  end

  mt.anchorMin = oldMt.anchorMin
  mt.anchorMin[1] = function (self)
    local x, y = LuaUtils.RectTransformAnchorMinXY(self)
    local v = Vector2(x, y)
    return v
  end

  mt.offsetMax = oldMt.offsetMax
  mt.offsetMax[1] = function (self)
    local x, y = LuaUtils.RectTransformOffsetMaxXY(self)
    local v = Vector2(x, y)
    return v
  end

  mt.offsetMin = oldMt.offsetMin
  mt.offsetMin[1] = function (self)
    local x, y = LuaUtils.RectTransformOffsetMinXY(self)
    local v = Vector2(x, y)
    return v
  end

  mt.pivot = oldMt.pivot
  mt.pivot[1] = function (self)
    local x, y = LuaUtils.RectTransformPivotXY(self)
    local v = Vector2(x, y)
    return v
  end

  mt.rect = oldMt.rect
  mt.rect[1] = function (self)
    local x, y, w, h = LuaUtils.RectTransformRectXYWH(self)
    local v = Rect(x, y, w, h)
    return v
  end

  mt.sizeDelta = oldMt.sizeDelta
  mt.sizeDelta[1] = function (self)
    local x, y = LuaUtils.RectTransformSizeDeltaXY(self)
    local v = Vector2(x, y)
    return v
  end

  return mt
end

setmetatable(m, {__call = function(t, ...) m.decorate(...) end })
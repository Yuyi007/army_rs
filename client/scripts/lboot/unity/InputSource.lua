
-- GetTouch, GetButtonDown etc. has GC alloc,
-- use this to collect inputs to avoid unnecessary API calls

class('InputSource', function ()
end)

local m = InputSource
local Input = UnityEngine.Input
local GetTouch = UnityEngine.Input.GetTouch
local GetButtonDown = UnityEngine.Input.GetButtonDown

m.btnDowns = {}
m.touches = {}
m.touchCount = nil

function m.clearInputs()
  local btnDowns = m.btnDowns
  local touches = m.touches

  for k, _ in pairs(btnDowns) do
    btnDowns[k] = nil
  end

  for i = 1, #touches do
    touches[i] = nil
  end
  m.touchCount = nil
end

function m.collectTouches()
  m.touchCount = Input:get_touchCount()

  local touches = m.touches
  for i = 0, m.touchCount - 1 do
    touches[i] = GetTouch(i)
  end
end

function m.getTouchCount()
  if not m.touchCount then
    m.collectTouches()
  end

  return m.touchCount
end

function m.getTouch(i)
  if not m.touchCount then
    m.collectTouches()
  end

  return m.touches[i]
end

function m.getTouches()
  return m.touches
end

function m.getButtonDown(key)
  local btnDowns = m.btnDowns
  if btnDowns[key] == nil then
    btnDowns[key] = GetButtonDown(key)
  end
  return btnDowns[key]
end

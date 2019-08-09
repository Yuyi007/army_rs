
class('LuaLogDrawer')

local m = LuaLogDrawer

local Text = UnityEngine.UI.Text
local Image = UnityEngine.UI.Image
local RectTransform = UnityEngine.RectTransform
local Rect = UnityEngine.Rect
local Screen = UnityEngine.Screen
local Time = UnityEngine.Time

m.logs = {}

declare('dvlogon', function ()
  game.dvlogon = true
end)

declare('dvlogoff', function ()
  game.dvlogon = nil
end)

declare('dvlog', function (...)
  local logs = m.logs
  logs[#logs + 1] = string.format(...)
end)

declare('lastCrash', function ()
  dvlog(getLastCrashReport())
end)

declare('dvclear', function ()
  local logs = m.logs
  for i = 1, #logs do
    logs[i] = nil
  end
end)

function m.startDraw(parent, text)
  if m.drawHandle then return end
  m.text = text
  m.textComp = text:GetComponent(Text)
  m.textComp.font = UnityEngine.Resources.GetBuiltinResource(UnityEngine.Font, "Arial.ttf")
  m.textComp.fontSize = 12
  m.textComp.color = Color(0, 0, 0, 1)

  dvlog('use dvlog() to print logs.')
  dvlog('use dvclear() to clear logs.')
  dvlog('use dvlogon() and dvlogoff to redirect logs to here.')
  dvlog('use lastCrash() to print last crash log.')
  m.drawHandle = coroutineStart(function (delta)
    m.initLogs(parent)
    coroutine.yield()

    while true do
      m.drawLogs()
      coroutine.yield()
    end
  end, 0.3, {global=false})
end

function m.stopDraw()
  if m.drawHandle then
    scheduler.unschedule(m.drawHandle)
    m.drawHandle = nil
    m.destroyLogs()

    m.textComp.text = ''
  end
end

function m.initLogs(parent)
  m.textComp.text = ''
  m.textComp.color = Color(1.0, 1.0, 1.0, 0.5)
end

function m.destroyLogs()
end

function m.drawLogs()
  m.textComp.text = table.concat(m.logs, '\n')
end

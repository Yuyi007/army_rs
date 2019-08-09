
class('StatsDrawer')

local m = StatsDrawer

local Text = UnityEngine.UI.Text
local Image = UnityEngine.UI.Image
local RectTransform = UnityEngine.RectTransform
local Rect = UnityEngine.Rect
local Screen = UnityEngine.Screen
local Time = UnityEngine.Time
local Pool = Pool

function m.startDraw(parent, text)
  if m.drawHandle then return end
  m.text = text
  m.textComp = text:GetComponent(Text)
  m.textComp.font = UnityEngine.Resources.GetBuiltinResource(UnityEngine.Font, "Arial.ttf")
  m.textComp.fontSize = 12
  m.textComp.color = Color(0, 0, 0, 1)
  m.showStatsComp = m.getShowStatsComp()
  m.poolInfo = {}

  m.drawHandle = coroutineStart(function (delta)
    -- getting tris and verts disrupts MainScene
    m.showStatsComp.UpdateDetailed = false

    m.initStats(parent)
    coroutine.yield()

    while true do
      m.drawStats()
      coroutine.yield()
    end
  end, 0.3, {global=false})
end

function m.stopDraw()
  if m.drawHandle then
    scheduler.unschedule(m.drawHandle)
    m.drawHandle = nil
    m.destroyStats()

    m.showStatsComp.UpdateDetailed = false
    m.textComp.text = ""
  end
end

function m.initStats(parent)
  m.textComp.text = ""
  m.textComp.color = Color(1.0, 1.0, 1.0, 0.5)
end

function m.destroyStats()
end

function m.drawStats()
  local comp = m.showStatsComp
  local pools = FramePool.pools
  local poolInfo = m.poolInfo

  for i = 1, #poolInfo do poolInfo[i] = nil end
  for i = 1, #pools do
    local pool = pools[i]
    table.insert(poolInfo, string.format("%s: lent-%d, maxlent-%d, max-%d \n",
      pool.tag, pool.lentSize, pool.maxLentSize, pool.maxSize))
  end
  table.insert(poolInfo, "\n")

  local unityFrameTime = game.lastFrameTime - game.lastFrameScriptTime
  m.textComp.text = string.format(
    "fps: %.1f\nframe: %.1fms,%.1fms,%.1fms\nscreen: (%d x %d)\ntris: %d verts: %d mem: %d\nmono: %.2fMB, %.1fKB/s\nlua: %.2fMB, %.1fKB/s\nframeGC: %d, %.3fKB\npools: %s\n",
    comp:get_Fps(),
    game.lastFrameScriptTime, unityFrameTime, game.lastFrameTime,
    Screen.width, Screen.height,
    comp:get_Tris(), comp:get_Verts(), comp:get_MemUsage(),
    game.monoMemUsage / 1048576.0, game.monoMemRate,
    game.luaMemUsage / 1024.0, game.luaMemRate,
    game.lastFrameGCSteps, game.lastFrameGCSize,
    table.concat(poolInfo))
end

function m.getShowStatsComp()
  local go = GameObject.Find('/ShowStats')
  if go then
    return go:GetComponent(LBoot.ShowStatsBehaviour)
  end
  return nil
end

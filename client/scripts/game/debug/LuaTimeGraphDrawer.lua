
class('LuaTimeGraphDrawer')

local m = LuaTimeGraphDrawer

function m.startDraw(parent, x, y, width, height)
  if m.drawHandle then return end

  m.drawHandle = coroutineStart(function (delta)
    ProFiHelper.setSchedulerHook(true)
    m.graph = BarGraph.new(parent, {x=x, y=y,
      width=width, height=height, color=Color(1, 0.1, 0.1, 0.5)})
    m.graph:init()
    coroutine.yield()

    while true do
      m.drawTimeGraph(ProFiHelper.profileResult)
      coroutine.yield()
    end
  end, 1.0, {global=false})
end

function m.stopDraw()
  if m.drawHandle then
    scheduler.unschedule(m.drawHandle)
    m.drawHandle = nil
    m.graph:exit()
    m.graph = nil
    ProFiHelper.setSchedulerHook(false)
  end
end

function m.drawTimeGraph(result)
  if not result then return end

  for i = 1, #result.sorted do local v = result.sorted[i]
    if i > m.graph.barNum then break end

    if v["func"] ~= "(null)" then
      local word = string.format("%s %s", v["word"], v["func"])
      -- local detail = string.match(word, "^@.-([^/\\]-[^%.]+)$")
      local detail = string.sub(word, -45)
      local calls = v["calls"]
      local total = 1000.0 * v["total"]
      local timePerCall = total / v["calls"]
      local callsPerFrame = (0.0 + calls) / ProFiHelper.profileCycle
      local timePerFrame = total / ProFiHelper.profileCycle
      local percent = (result.global_t > 0) and (100.0 * v["total"] / result.global_t) or 0
      local text = string.format("%s, %d, %.2f, %.2f",
        detail or word, calls, total, timePerCall)

      m.graph:updateBar(i, percent, text)
    end
  end
end


class('LuaAllocGraphDrawer')

local m = LuaAllocGraphDrawer
local xt = require 'xt'

function m.startDraw(parent, x, y, width, height)
  if m.drawHandle then return end

  if ProFiHelper.allocTraceSupported() then
    -- trace_alloc on main thread to trace only main thread
    local res, err = xt.trace_allocs(1)
    logd('trace mem started res=%s err=%s', tostring(res), tostring(err))
  end

  m.drawHandle = coroutineStart(function (delta)
    ProFiHelper.setSchedulerHook(true, 'alloc')
    m.graph = BarGraph.new(parent, {x=x, y=y,
      width=width, height=height})
    m.graph:init()
    coroutine.yield()

    while true do
      m.drawAllocGraph(ProFiHelper.profileResult)
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

  if ProFiHelper.allocTraceSupported() then
    xt.trace_allocs(0)
    logd('trace mem stopped.')
  end
end

function m.drawAllocGraph(result)
  if not result then return end

  for i = 1, #result.sorted do local v = result.sorted[i]
    if i > m.graph.barNum then break end

    if v["func"] ~= "(null)" then
      local word = string.format("%s %s", v["word"], v["func"])
      -- local detail = string.match(word, "^@.-([^/\\]-[^%.]+)$")
      local detail = string.sub(word, -45)
      local calls = v["calls"]
      local count = v["allocCount"]
      local size = v["allocSize"] / 1024.0
      local countPerCall = (calls > 0) and (count / calls) or 0
      -- local sizePerCount = (count > 0) and (size / count) or 0
      local sizePerCall = (calls > 0) and (size / calls) or 0
      -- local sizePerFrame = size / ProFiHelper.profileCycle
      local percent = (result.global_t > 0) and (100.0 * v['allocSize'] / result.global_t) or 0
      local text = string.format("%s, %.0f, %.0fKB",
        detail or word, count, size)

      m.graph:updateBar(i, percent, text)
    end
  end
end

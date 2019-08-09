
class('FrameDebugger')

local m = FrameDebugger

function m.startFrame()
  scheduler.setHook(nil)

  local debuggerView = game.debuggerView
  debuggerView:exitPanels()
  debuggerView:initPanels()
end

function m.stopFrame()
  scheduler.setHook(function (runClocks)
    return function (clocks, dt)
      for i = #clocks, 1, -1 do
        local v = clocks[i]
        if v and (not v.paused) and (not v.stopped) and v.num ~= 0 then
          v.dt = v.dt + dt

          -- only run global clocks
          if v.global and v.dt >= v.interval then
            v.func(dt)
            v.dt = 0
            if v.num > 0 then v.num = v.num - 1 end
          end
        end

        if v.num == 0 or v.stopped then table.remove(clocks, i) end
      end
    end
  end, 'normal')
end

function m.stepFrame()
  local debuggerView = game.debuggerView
  debuggerView:exitPanels()
  debuggerView:initPanels()

  scheduler.setHook(function (runClocks)
    return function (clocks, dt)
      pcall(function ()
        -- update lua time/alloc graph
        local stepFunc = function () runClocks(clocks, dt) end
        local enableLua = debuggerView.options.enableLua
        local enableMem = debuggerView.options.enableMem
        local enableNet = debuggerView.options.enableNet

        if enableLua == 1 then
          logd('FrameDebugger: drawTimeGraph')
          ProFiHelper.profileOneStep(stepFunc)
          LuaTimeGraphDrawer.drawTimeGraph(ProFiHelper.profileResult)
        elseif enableLua == 2 then
          logd('FrameDebugger: drawAllocGraph')
          ProFiHelper.profileOneStep(stepFunc, 'alloc')
          LuaAllocGraphDrawer.drawAllocGraph(ProFiHelper.profileResult)
        end

        -- update memory graph
        if enableMem then
          logd('FrameDebugger: drawMemGraph')
          local memResult
          memResult = MemGraphDrawer.traverseMemory(false, {memResult})
          MemGraphDrawer.drawMemGraph(memResult)
        end

        -- update net graph
        if enableNet then
          logd('FrameDebugger: drawNetGraph')
          NetGraphDrawer.updateNetData()
          NetGraphDrawer.drawNetGraph()
        end
      end)

      -- stop frame
      scheduler.setHook(function (runClocks)
        return function (clocks, dt) end
      end, 'normal')
    end
  end, 'profile')
end

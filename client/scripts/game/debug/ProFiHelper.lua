
class('ProFiHelper', function (self)
end)

local m = ProFiHelper
local xt = require 'xt'
local Time = UnityEngine.Time
local getTime = function () return Time:get_realtimeSinceStartup() end

m.sampleRate = 200 -- runClocks sample rate (in Hz)
m.profileCycle = 5 -- a profile session last for how many runClocks
m.profileResult = nil

function m.allocTraceSupported()
  -- FIXME xt.trace_allocs() currently has bugs, crashes the game
  -- Bug can be easily reproduced on android and Mac Book Air editor
  return false
end

function m.setSchedulerHook(enabled, analyseType)
  m.profileResult = nil

  if enabled then
    local sampleTicks = nil
    local analysing = false

    scheduler.setHook(function (runClocks)
      return function (clocks, dt)
        if analysing then
          runClocks(clocks, dt)
        else
          local profi = nil
          if math.random(m.sampleRate) == m.sampleRate then
            profi = profileStart('ProFi_vis')
            profi:setGetTimeMethod(getTime)
            sampleTicks = 0 -- sample started
          end

          runClocks(clocks, dt)

          if sampleTicks then sampleTicks = sampleTicks + 1 end
          if sampleTicks == m.profileCycle then
            sampleTicks = nil
            profi = profileStop()
            if profi then
              -- analyse in a coroutine, do not block game frames
              analysing = true
              coroutineStart(function ()
                local analyse = m.analyseTime
                if analyseType == 'alloc' then
                  analyse = m.analyseAlloc
                end
                m.profileResult = analyse(profi, true)
                profi:reset()
                analysing = false
              end)
            else
              loge('ProFiHelper: profi is nil after profileStop()')
            end
          end
        end
      end
    end)
  else
    scheduler.setHook(nil)
  end
end

function m.profileOneStep(stepFunc, analyseType)
  local profi = profileStart('ProFi_vis')
  local analyse = m.analyseTime
  if analyseType == 'alloc' then
    analyse = m.analyseAlloc
    if m.allocTraceSupported() then
      local res, err = xt.trace_allocs(1)
      logd('trace mem started res=%s err=%s', tostring(res), tostring(err))
    end
  end

  profi:setGetTimeMethod(getTime)
  stepFunc()

  profileStop()
  m.profileResult = analyse(profi)
  profi:reset()

  if analyseType == 'alloc' then
    if m.allocTraceSupported() then
      xt.trace_allocs(0)
      logd('trace mem stopped')
    end
  end
end

function m.shouldExcludeTime(source)
  return string.match(source, 'lboot/unity/lib/scheduler.lua') or
    string.match(source, 'LuaTimeGraphDrawer.lua') or
    string.match(source, 'ProFiHelper.lua') or
    string.match(source, 'FrameDebugger.lua')
end

function m.analyseTime(profi, yield)
  -- logd("profi=%s", inspect(profi.reports))
  local global_t = profi.stopTime - profi.startTime
  local sorted = {}

  local sortByDurationDesc = function( a, b )
    return a.timer > b.timer
  end

  if yield then coroutine.yield() end
  table.sort(profi.reports, sortByDurationDesc)
  if yield then coroutine.yield() end

  for i, item in ipairs(profi.reports) do
    local fi = item.funcInfo
    local name = fi.name or 'anonymous'
    local source = fi.short_src or 'C_FUNC'
    local linedefined = fi.linedefined or 0
    if not m.shouldExcludeTime(source) then
      table.insert(sorted, {
        word = string.format("%s:%d", source, linedefined),
        func = name,
        calls = item.count,
        total = item.timer,
        })
    end
    if i % 50 == 0 and yield then coroutine.yield() end
  end

  return {
    sorted = sorted,
    global_t = global_t,
  }
end

function m.shouldExcludeAlloc(source)
  return string.match(source, 'lboot/unity/lib/scheduler.lua') or
    string.match(source, 'LuaAllocGraphDrawer.lua') or
    string.match(source, 'ProFiHelper.lua') or
    string.match(source, 'FrameDebugger.lua')
end

function m.analyseAlloc(profi, yield)
  -- logd("profi=%s", inspect(profi.reports))
  local global_t = (profi.stopAllocSize - profi.startAllocSize) -
    (profi.stopFreeSize - profi.startFreeSize)
  local sorted = {}

  local sortBySizeDesc = function( a, b )
    return a.allocSize - a.freeSize > b.allocSize - b.freeSize
  end

  if yield then coroutine.yield() end
  table.sort(profi.reports, sortBySizeDesc)
  if yield then coroutine.yield() end

  for i, item in ipairs(profi.reports) do
    local fi = item.funcInfo
    local name = fi.name or 'anonymous'
    local source = fi.short_src or 'C_FUNC'
    local linedefined = fi.linedefined or 0
    if not m.shouldExcludeAlloc(source) then
      table.insert(sorted, {
        word = string.format("%s:%d", source, linedefined),
        func = name,
        calls = item.count,
        allocCount = item.allocCount - item.freeCount,
        allocSize = item.allocSize - item.freeSize,
        })
    end
    if i % 50 == 0 and yield then coroutine.yield() end
  end

  return {
    sorted = sorted,
    global_t = global_t,
  }
end

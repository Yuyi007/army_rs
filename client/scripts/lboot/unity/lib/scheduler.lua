local m = class('scheduler')

if not rawget(_G, 'schedulerData') then
  logd("scheduler: init scheduler data")
  rawset(_G, 'schedulerData', {
    idx=0,
    updateClocks={},
    fixedUpdateClocks={},
    lateUpdateClocks={},
    finalUpdateClocks={},
  })
end

local updateClocks = schedulerData.updateClocks
local fixedUpdateClocks = schedulerData.fixedUpdateClocks
local lateUpdateClocks = schedulerData.lateUpdateClocks
local finalUpdateClocks = schedulerData.finalUpdateClocks
local allClocks = {updateClocks, fixedUpdateClocks, lateUpdateClocks, finalUpdateClocks}
local clocksUpdateNames = {'Update', 'FixedUpdate', 'LateUpdate', 'FinalUpdate'}
local lastFrameScriptTime = 0
local clockPool = Pool.new(function () return {} end,
  {tag = 'SchedulerClocks', initSize = 8, maxSize = 1024, objectMt = {}})

local Time = UnityEngine.Time
local GlobalUpdateBehaviour = LBoot.GlobalUpdateBehaviour
local unity = unity

local toRemove = {}
local currentFuncs = {}

local function runClocks(clocks, dt)
  for i = 1, #currentFuncs do
    currentFuncs[i] = nil
  end

  for i = 1, #clocks do
    local v = clocks[i]
    if v and (not v.paused) and (not v.stopped) and v.num ~= 0 then
      v.dt = v.dt + dt
      local diff = (v.dt - v.interval)
      if diff >= -0.0001 then
        v.dt = v.dt - v.interval
        if v.num > 0 then v.num = v.num - 1 end
        -- NOTE 1:
        -- schedulers can be removed in func
        -- NOTE 2:
        -- schedulers can be inserted to clocks in func
        currentFuncs[#currentFuncs + 1] = v.func
      end
    end

    if v.num == 0 or v.stopped then
      toRemove[#toRemove + 1] = i
    end
  end

  for i = #toRemove, 1, -1 do
    local clock = table.remove(clocks, toRemove[i])
    if clock then
      clock.func = nil
      clockPool:recycle(clock)
    end
    toRemove[i] = nil
  end

  -- NOTE 3:
  -- If the function throws an error,
  -- it shouldn't repeat in subsequent loops
  -- We put function execution to last of the function, to save a pcall cost per func
  for i = 1, #currentFuncs do
    currentFuncs[i](dt)
  end

  -- m.measuredFuncs(currentFuncs, dt)
end

function m.measuredFuncs(currentFuncs, dt)
  local times = {}
  local totalTime = 0.001

  for i = 1, #currentFuncs do
    local ts = Time:get_realtimeSinceStartup()
    currentFuncs[i](dt)
    local time = (Time:get_realtimeSinceStartup() - ts) * 1000
    local info = debug.getinfo(currentFuncs[i], 'S')
    times[#times + 1] = {i, time, info}
    totalTime = totalTime + time
  end

  table.sort(times, function (a, b) return a[2] > b[2] end)
  for j = 1, #times do
    local i, time, info = unpack(times[j])
    local src = string.format('%s:%s-%s', info.short_src, info.linedefined, info.lastlinedefined)
    local percent = time * 100 / totalTime
    logd('i=%d time=%f %d%% %s', i, math.round(time, 3), percent, src)
  end
end

function m.init()
  logd("scheduler.init: <Update>=%d,%d <FixedUpdate>=%d,%d <LateUpdate>=%d,%d <FinalUpdate>=%d,%d",
    #updateClocks, #m.getGlobalClocks(updateClocks),
    #fixedUpdateClocks, #m.getGlobalClocks(fixedUpdateClocks),
    #lateUpdateClocks, #m.getGlobalClocks(lateUpdateClocks),
    #finalUpdateClocks, #m.getGlobalClocks(finalUpdateClocks))

  m.setSchedulerFuncs(runClocks)
end

-- Profiler version of setSchedulerFuncs --
function m.setSchedulerFuncsProfile(func)
  local app = GameObject.Find('/LBootApp')
  if app == nil then return end

  local updater = app:GetComponent(GlobalUpdateBehaviour)

  updater.UpdateAction = function ()
    local startTime = Time:get_realtimeSinceStartup()
    ProfileSampler.checkStartSample()
    ProfileSampler.runSample(function ()
      func(updateClocks, Time.get_deltaTime())
    end, '')
    lastFrameScriptTime = (Time:get_realtimeSinceStartup() - startTime)
  end
  updater.FixedUpdateAction = function ()
    local startTime = Time:get_realtimeSinceStartup()
    ProfileSampler.runSample(function ()
      func(fixedUpdateClocks, Time.get_fixedDeltaTime())
    end, 'fixed')
    lastFrameScriptTime = lastFrameScriptTime + (Time:get_realtimeSinceStartup() - startTime)
  end
  updater.LateUpdateAction = function ()
    local startTime = Time:get_realtimeSinceStartup()
    ProfileSampler.runSample(function ()
      func(lateUpdateClocks, Time.get_deltaTime())
    end, 'late')
    lastFrameScriptTime = lastFrameScriptTime + (Time:get_realtimeSinceStartup() - startTime)
  end
  updater.FinalUpdateAction = function ()
    local startTime = Time:get_realtimeSinceStartup()
    ProfileSampler.runSample(function ()
      func(finalUpdateClocks, Time.get_deltaTime())
    end, 'final')
    lastFrameScriptTime = lastFrameScriptTime + (Time:get_realtimeSinceStartup() - startTime)
  end
end
-- Profiler version of setSchedulerFuncs --
    
-- Normal version of setSchedulerFuncs --
function m.setSchedulerFuncsNormal(func)
  local app = GameObject.Find('/LBootApp')
  if app == nil then return end

  local updater = app:GetComponent(GlobalUpdateBehaviour)

  updater.UpdateAction = function ()
    unity.beginSample('UpdateAction')
    local startTime = Time:get_realtimeSinceStartup()
    func(updateClocks, Time.get_deltaTime())
    lastFrameScriptTime = (Time:get_realtimeSinceStartup() - startTime)
    unity.endSample()
  end
  updater.FixedUpdateAction = function ()
    unity.beginSample('FixedUpdateAction')
    local startTime = Time:get_realtimeSinceStartup()
    func(fixedUpdateClocks, Time.get_fixedDeltaTime())
    lastFrameScriptTime = lastFrameScriptTime + (Time:get_realtimeSinceStartup() - startTime)
    unity.endSample()
  end
  updater.LateUpdateAction = function ()
    unity.beginSample('LateUpdateAction')
    local startTime = Time:get_realtimeSinceStartup()
    func(lateUpdateClocks, Time.get_deltaTime())
    lastFrameScriptTime = lastFrameScriptTime + (Time:get_realtimeSinceStartup() - startTime)
    unity.endSample()
  end
  updater.FinalUpdateAction = function ()
    unity.beginSample('FinalUpdateAction')
    local startTime = Time:get_realtimeSinceStartup()
    func(finalUpdateClocks, Time.get_deltaTime())
    lastFrameScriptTime = lastFrameScriptTime + (Time:get_realtimeSinceStartup() - startTime)
    unity.endSample()
  end
end
-- Normal version of setSchedulerFuncs --

------------------------------------------------------
-- Switch on/off profiling on scheduler functions

if ProfileSampler.sampleScheduler then
  m.setSchedulerFuncs = m.setSchedulerFuncsProfile
else
  m.setSchedulerFuncs = m.setSchedulerFuncsNormal
end

-- Switch on/off profiling on scheduler functions
------------------------------------------------------

function m.setHook(genHook, flavor)
  local hook = nil
  if genHook then
    logd('scheduler.setHook: hook enabled flavor=%s trace=%s', tostring(flavor), debug.traceback())
    hook = genHook(runClocks)
  else
    logd('scheduler.setHook: hook disabled flavor=%s trace=%s', tostring(flavor), debug.traceback())
    hook = runClocks
  end

  if flavor == 'profile' then
    m.setSchedulerFuncsProfile(hook)
  elseif flavor == 'normal' then
    m.setSchedulerFuncsNormal(hook)
  else
    m.setSchedulerFuncs(hook)
  end
end

function m.lastFrameScriptTime()
  return lastFrameScriptTime
end

-- by default, schedule on Update()
function m.schedule(func, interval, isPaused, isGlobal, num, kind, index)
  kind = kind or 'Update'

  if type(func) ~= 'function' then
    loge('schedule func not a function: %s trace=%s', peek(func), debug.traceback())
    return
  end

  local clocks = nil
  if kind == 'Update' then
    clocks = updateClocks
  elseif kind == 'FixedUpdate' then
    clocks = fixedUpdateClocks
  elseif kind == 'LateUpdate' then
    clocks = lateUpdateClocks
  elseif kind == 'FinalUpdate' then
    clocks = finalUpdateClocks
  else
    error("schedule: bad arguments")
  end

  local clock = m.createClock(func, interval, isPaused, isGlobal, num)
  if index then
    table.insert(clocks, index, clock)
  else
    clocks[#clocks + 1] = clock
  end

  if isGlobal and game.debug > 0 then
    -- logd("scheduler.schedule: add global <%s> globals=%d trace=%s",
    --   tostring(kind), #m.getGlobalClocks(clocks), debug.traceback())
  end

  return clock.handle
end

-- schedule on Update()
function m.scheduleWithUpdate(func, interval, isPaused, isGlobal, num, index)
  return m.schedule(func, interval, isPaused, isGlobal, num, 'Update', index)
end

-- schedule on FixedUpdate()
function m.scheduleWithFixedUpdate(func, interval, isPaused, isGlobal, num, index)
  return m.schedule(func, interval, isPaused, isGlobal, num, 'FixedUpdate', index)
end

-- schedule on LateUpdate()
function m.scheduleWithLateUpdate(func, interval, isPaused, isGlobal, num, index)
  return m.schedule(func, interval, isPaused, isGlobal, num, 'LateUpdate', index)
end

-- schedule in the end of LateUpdate()
function m.scheduleWithFinalUpdate(func, interval, isPaused, isGlobal, num, index)
  return m.schedule(func, interval, isPaused, isGlobal, num, 'FinalUpdate', index)
end

function m.createClock(func, interval, isPaused, isGlobal, num)
  interval = interval or 0
  isPaused = isPaused or false
  isGlobal = isGlobal or false
  num = num or -1

  schedulerData.idx = schedulerData.idx + 1
  local clock = clockPool:borrow()
  clock.handle   = schedulerData.idx
  clock.func     = func
  clock.dt       = 0
  clock.interval = interval
  clock.paused   = isPaused
  clock.global   = isGlobal
  clock.num      = num
  clock.stopped  = false
  return clock
end

-- -1 to repeat forever
function m.scheduleWithNum(func, interval, num)
  return m.scheduleWithUpdate(func, interval, false, false, num)
end

function m.performWithDelay(delay, func)
  return m.scheduleWithUpdate(func, delay, false, false, 1)
end

function m.unscheduleAll()
  for j = 1, #allClocks do
    local clocks = allClocks[j]
    local clocksCount = #clocks
    local stopped = 0
    for i = clocksCount, 1, -1 do
      local v = clocks[i]
      if v.global ~= true then
        v.stopped = true
        stopped = stopped + 1
      else
        if type(v.func) == 'function' then
          -- logd("scheduler.unscheduleAll: <%s> i=%d is global func=%s",
            -- clocksUpdateNames[j], i, peek(debug.getinfo(v.func, 'S')))
        end
      end
    end
    -- logd("scheduler.unscheduleAll: <%s> before=%d stopped=%d",
    --   clocksUpdateNames[j], clocksCount, stopped)
  end
end

function m.unscheduleAllAndGlobal()
  logd('scheduler.unscheduleAllAndGlobal')
  table.clear(updateClocks)
  table.clear(fixedUpdateClocks)
  table.clear(lateUpdateClocks)
  table.clear(finalUpdateClocks)
end

function m.unschedule(handle)
  -- logd("scheduler.unschedule %d", handle)
  for j = 1, #allClocks do
    local clocks = allClocks[j]
    for i = 1, #clocks do
      local v = clocks[i]
      if v.handle == handle then
        -- logd("scheduler.unschedule found %d", handle)
        v.stopped = true
        if v.global and game.debug > 0 then
          -- logd("scheduler.schedule: remove global <%s> globals=%d trace=%s",
          --   clocksUpdateNames[j], #m.getGlobalClocks(clocks), debug.traceback())
        end
        break
      end
    end
  end
end

function m.getGlobalClocks(clocks)
  local res = {}
  for i = 1, #clocks do
    local v = clocks[i]
    if v.global == true and not v.stopped then table.insert(res, v) end
  end
  return res
end

function m.clearPools()
  clockPool:clear()
end

function m.onClassReloaded(_cls)
  scheduler.init()
end

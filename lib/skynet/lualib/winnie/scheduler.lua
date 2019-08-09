class("Scheduler", function(self) end)

local m = Scheduler

m.beginupdateClocks = {}
m.preupdateClocks = {}
m.updateClocks = {}
m.lateupdateClocks = {}
m.endupdateClocks = {}
m.running = false
m.uuid = 0
m.lastRunTime = nil
m.runStartTime = nil
m.clockPool = Pool.new(function () return {} end, {tag = 'SchedulerClocks', initSize = 8, maxSize = 1024, objectMt = {}})
m.interval = SCHEDULER_PRECISION or 50
--print("Scheduler PRECISION:", m.interval)
function m.genID()
  m.uuid = m.uuid + 1
  return m.uuid
end

function m.run(co)
  while true do 
    if not m.running then
      break
    end

    local now = skynet.now()
    m.runStartTime = now
    m.lastRunTime = m.lastRunTime or now
    -- beginupdate clocks
    m.runClocks(m.beginupdateClocks)
    -- preupdate clocks
    m.runClocks(m.preupdateClocks)
    -- update clocks
    m.runClocks(m.updateClocks)
    -- lateupdate clocks
    m.runClocks(m.lateupdateClocks)
    -- endupdate clocks
    m.runClocks(m.endupdateClocks)

    -- make sure framerate do not greater than 30
    now = skynet.now()
    local tmSpan = now - m.runStartTime
    if tmSpan < m.interval then
      skynet.sleep(m.interval - tmSpan)
    end
  end
end

function m.start()
  if m.interval < 0 then return end
  if m.running then return end
  m.running = true
  local function run()
    local st, err = pcall(m.run)
    if not st then
      skynet.error("scheduler run error:"..err)
    end
  end
  skynet.fork(m.run, coroutine.running())
end

function m.stop()
  m.clockPool:clear()
  m.running = false
  m.beginupdateClocks = {}
  m.preupdateClocks = {}
  m.updateClocks = {}
  m.lateupdateClocks = {}
  m.endupdateClocks = {}
  m.uuid = 0
  m.lastRunTime = nil
  m.runStartTime = nil
end

local toRemove = {}
local currentFuncs = {}

function m.runClocks(clocks)
  for i = 1, #currentFuncs do
    currentFuncs[i] = nil
  end

  local now = skynet.now()
  for i=1, #clocks do 
    local clock = clocks[i]
    clock.lastTime = clock.lastTime or now
    local deltaTime = now - clock.lastTime
    if not clock.stopped then
      local diff = deltaTime - clock.interval
      if diff >= 0.001 then
        currentFuncs[#currentFuncs + 1] = clock
      end
    end

    if clock.stopped then
      --print("clock stoped:", clock.id)
      toRemove[#toRemove + 1] = i
    end
  end

  for i = #toRemove, 1, -1 do
    local clock = table.remove(clocks, toRemove[i])
    if clock then
      clock.func = nil
      m.clockPool:recycle(clock)
    end
    toRemove[i] = nil
  end


  for i = 1, #currentFuncs do
    local clock = currentFuncs[i]
    local host = clock.host
    local func = clock.func
    clock.lastTime = now
    if not host then
      -- print("clock run:", clock.id)
      func(deltaTime)
    else
      -- print(">>>>host:"..tostring(host.classname))
      func(host, deltaTime)
    end
  end
   
end

function m.makeClock(kind, interval, host, func)
  clock = m.clockPool:borrow()
  clock.id = m.genID()
  clock.kind = kind
  clock.interval = interval
  clock.lastTime = nil
  clock.host = host
  clock.func = func
  clock.stopped = false
  return clock
end

function m.unscheduleUpdater(kind, id)
  local clocks = nil
  if kind == "beginupdate" then
    clocks = m.beginupdateClocks
  elseif kind == "endupdate" then
    clocks = m.endupdateClocks
  elseif kind == "preupdate" then
    clocks = m.preupdateClocks
  elseif kind == "update" then
    clocks = m.updateClocks 
  elseif kind == "lateupdate" then
    clocks = m.lateupdateClocks
  else
    assert("wrong scheduler kind:"..tostring(kind))
  end

  for i, v in pairs(clocks) do
    if v.id == id then
      --print("unschedule clock:", id)
      clocks[i].stopped = true
      return
    end
  end
end

function m.scheduleWithBeginupdate(interval, func, host)
  local clock = m.makeClock("beginupdate", interval, host, func)
  table.insert(m.beginupdateClocks, clock)
  return clock.id
end

function m.scheduleWithEndupdate(interval, func, host)
  local clock = m.makeClock("endupdate", interval, host, func)
  table.insert(m.endupdateClocks, clock)
  return clock.id
end


function m.scheduleWithPreupdate(interval, func, host)
  local clock = m.makeClock("preupdate", interval, host, func)
  table.insert(m.preupdateClocks, clock)
  return clock.id
end

function m.scheduleWithUpdate(interval, func, host)
  local clock = m.makeClock("update", interval, host, func)
  table.insert(m.updateClocks, clock)
  return clock.id
end

function m.schedule(interval, func, host)
   return m.scheduleWithUpdate(interval, func, host)
end

function m.unschedule(hanlde)
  m.unscheduleUpdate(hanlde)
end

function m.scheduleWithLateupdate(interval, func, host)
  local clock = m.makeClock("lateupdate", interval, host, func)
  table.insert(m.lateupdateClocks, clock)
  return clock.id
end

function m.unscheduleBeginupdate(handle)
  m.unscheduleUpdater('beginupdate', handle)
end

function m.unscheduleEndupdate(handle)
  m.unscheduleUpdater('endupdate', handle)
end


function m.unschedulePreupdate(handle)
  m.unscheduleUpdater('preupdate', handle)
end

function m.unscheduleUpdate(handle)
  m.unscheduleUpdater('update', handle)
end

function m.unscheduleLateupdate(handle)
  m.unscheduleUpdater('lateupdate', handle)
end

function m.performWithDelay(delay, func)
  m.scheduleWithUpdate(delay, func, false)
end

Scheduler.start()
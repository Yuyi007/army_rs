-- scheduler.lua
--
-- This is a placeholder file, the implementation is platform-specific
--


local m = class('scheduler')

function m.schedule(func, interval, isPaused, isGlobal)
  error("scheduler: no implemention specified")
end

function m.scheduleWithNum(func, interval, num)
  error("scheduler: no implemention specified")
end

function m.performWithDelay(delay, func)
  error("scheduler: no implemention specified")
end

function m.unscheduleAll()
  error("scheduler: no implemention specified")
end

function m.unscheduleAllAndGlobal()
  error("scheduler: no implemention specified")
end

function m.unschedule(handle)
  error("scheduler: no implemention specified")
end

function m.lastFrameScriptTime()
  error("scheduler: no implemention specified")
end


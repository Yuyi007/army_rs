class('IntervalChecker', function(self)
end)

local m = IntervalChecker
local unity = unity

m.handle1s = nil
m.handle01s = nil
m.checkers = {}

function m.start()
  m.started = true
  if not m.handle then
    m.handle1s = scheduler.schedule(function()
      m.checkInterval_1s()
    end, 1)

    m.handle01s = scheduler.schedule(function()
      m.checkInterval_01s()
    end, 0.1)
  end
end

function m.stop()
  m.started = false
  if m.handle01s then
    scheduler.unschedule(m.handle01s)
    m.handle01s = nil
  end

  if m.handle1s then
    scheduler.unschedule(m.handle1s)
    m.handle1s = nil
  end
end

function m.register(name, ck)
  m.checkers[name] = ck
end

function m.unregister(name)
  m.checkers[name] = nil
end

function m.checkInterval_1s()
  unity.beginSample('checkInterval_1s')

  for i,v in pairs(m.checkers) do
    v()
  end

  unity.endSample()
end

function m.checkInterval_01s()
  unity.beginSample('checkInterval_01s')

  unity.endSample()
end

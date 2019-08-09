-- SchedulerTest.lua
-- Do not test this when scheduler.init called in-between
-- You can run this by running game in editor and saving to reload this file

logd('Scheduler testing...')

local n = 100
local i = 0
scheduler.schedule(function()
  i = i + 1
end, 0.02, false, false, n)

local j = 0
scheduler.performWithDelay(0, function ()
  j = j + 1
end)

scheduler.performWithDelay(3.0, function ()
  logd('Scheduler test finished')
  logd('i=%d j=%d', i, j)
  assert(i == 100)
  assert(j == 1)
  logd('Scheduler test success!')
end)

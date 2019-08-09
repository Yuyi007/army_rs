-- ProfileSampler.lua

class('ProfileSampler', function (self)
end)

local m = ProfileSampler

m.sampleScheduler = false
m.sampleCallbacks = false

m.doSample = false
m.curSample = 0
m.maxSamples = 9

function m.checkStartSample()
  m.doSample = true--(math.random(100) > 80)
  logd('checkStartSample: doSample=%s %d', tostring(m.doSample), m.curSample)
end

function m.runSample(func, tag)
  if m.doSample then
    profile(func, nil, nil, string.format('profile_%d_%s.txt', m.curSample, tag))
    m.curSample = (m.curSample + 1) % m.maxSamples
  else
    func()
  end
end

rawset(_G, '__profile_lua_callback', function (t, callback, arg1)
  -- logd('__profile_lua_callback: t=%s callback=%s arg1=%s',
  --   tostring(t), tostring(callback), tostring(arg1))
  local func = t[callback]
  if not func then
    --logd('__profile_lua_callback: func not found %s', tostring(callback))
    return
  end
  if m.sampleCallbacks then
    m.checkStartSample()
    m.runSample(function ()
      func(t, arg1)
    end, callback)
  else
    func(t, arg1)
  end
end)

function m.startRunSamples()
  scheduler.setHook(nil, 'profile')
end

function m.stopRunSamples()
  scheduler.setHook(nil)
end

function m.onClassReloaded(_cls)
  if m.sampleScheduler then
    m.startRunSamples()
  else
    m.stopRunSamples()
  end
end

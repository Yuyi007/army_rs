
local xt = require('xt')
local math, string = math, string

local RNDN = 1000000

function decide(chance)
  return chance * RNDN > math.random(RNDN)
end

function setLuaGC(pause, stepmul)
  pause = pause or 150
  stepmul = stepmul or 1000

  local timeCount = 0
  local function checkMemory(dt)
    timeCount = timeCount + dt
    local used = tonumber(collectgarbage("count"))
    logd(string.format("[LUA] MEMORY USED: %0.2f KB, UPTIME: %04.2fs", used, timeCount))
  end

  local handle = nil
  if game.debug > 4 then
    handle = scheduler.schedule(checkMemory, 2.0, false)
  elseif game.debug > 3 then
    handle = scheduler.schedule(checkMemory, 30.0, false)
  elseif game.debug > 2 then
    handle = scheduler.schedule(checkMemory, 150.0, false)
  elseif game.debug > 1 then
    handle = scheduler.schedule(checkMemory, 1800.0, false)
  end

  if game.checkMemoryHandle then scheduler.unschedule(game.checkMemoryHandle) end
  game.checkMemoryHandle = handle

  collectgarbage("setpause", pause)
  collectgarbage("setstepmul", stepmul)
end

local lastTraceMonoMemUsage = 0
local lastTraceLuaMemUsage = 0

function traceMemory(...)
  -- collectgarbage("collect")
  -- LBoot.LuaUtils.GCCollect(-1)
  -- LBoot.LuaUtils.GCWaitForPendingFinalizers()

  local mono = LBoot.LuaUtils.GetTotalMemory() / 1024.0
  local lua = tonumber(collectgarbage("count"))

  local monoInc = mono - lastTraceMonoMemUsage
  local luaInc = lua - lastTraceLuaMemUsage

  local title = string.format(...)
  logd('traceMemory: %s lua=%d (%d) mono=%d (%d)', title, lua, luaInc, mono, monoInc)

  lastTraceMonoMemUsage = mono
  lastTraceLuaMemUsage = lua
end

-- from lua src lobject.h:
-- 32 bit
local POINTER_SIZE = 4
local SIZE_T_SIZE = 4
-- 64 bit
if xt.is_64bit and xt.is_64bit() then
  logd('is_64bit: true')
  POINTER_SIZE = 8
  SIZE_T_SIZE = 8
end
local TVALUE_SIZE = 8 + 4
local COMMON_HEADER_SIZE = POINTER_SIZE + 1 + 1
local TSTRING_SIZE = COMMON_HEADER_SIZE + 1 + 4 + SIZE_T_SIZE
local UDATA_SIZE = COMMON_HEADER_SIZE + POINTER_SIZE * 2 + SIZE_T_SIZE
local UPVAL_SIZE = COMMON_HEADER_SIZE + POINTER_SIZE + TVALUE_SIZE
local PROTO_SIZE = COMMON_HEADER_SIZE + POINTER_SIZE * 8 + 4 * 8 + 1 * 4
local TABLE_SIZE = COMMON_HEADER_SIZE + 1 * 2 + POINTER_SIZE * 5 + 4
local TKEY_SIZE = TVALUE_SIZE
local NODE_SIZE = TKEY_SIZE + TVALUE_SIZE
local LUA_STATE_SIZE = COMMON_HEADER_SIZE + 1 + POINTER_SIZE * 13 + 4 * 5 + 2 * 2 + 1 * 2 + TVALUE_SIZE * 2

local align8 = function (size) return size + (8 - size % 8) end
TVALUE_SIZE = align8(TVALUE_SIZE)
TSTRING_SIZE = align8(TSTRING_SIZE)
UDATA_SIZE = align8(UDATA_SIZE)
UPVAL_SIZE = align8(UPVAL_SIZE)
PROTO_SIZE = align8(PROTO_SIZE)
TABLE_SIZE = align8(TABLE_SIZE)
TKEY_SIZE = align8(TKEY_SIZE)
NODE_SIZE = align8(NODE_SIZE)
LUA_STATE_SIZE = align8(LUA_STATE_SIZE)

-- estimate number of bytes of a lua value
function estimateNumOfBytes(obj, t)
  t = t or type(obj)
  if t == 'nil' then
    return TVALUE_SIZE
  elseif t == 'boolean' then
    return TVALUE_SIZE
  elseif t == 'number' then
    return TVALUE_SIZE
  elseif t == 'string' then
    return TVALUE_SIZE + TSTRING_SIZE + string.len(obj)
  elseif t == 'userdata' then
    return TVALUE_SIZE + UDATA_SIZE
  elseif t == 'function' then
    local size = TVALUE_SIZE + PROTO_SIZE
    local i = 1
    while true do
      local n, v = debug.getupvalue(obj, i)
      if not n then break end
      size = size + UPVAL_SIZE
      i = i + 1
    end
    -- ignore closures
    return size
  elseif t == 'thread' then
    return TVALUE_SIZE + LUA_STATE_SIZE
  elseif t == 'table' then
    local size = TVALUE_SIZE + TABLE_SIZE
    local arraySize = #obj
    local hashSize = 0
    for k, v in pairs(obj) do
      if arraySize == 0 then
        hashSize = hashSize + 1
      elseif not (type(k) == 'number' and k > 0 and k <= arraySize) then
        hashSize = hashSize + 1
      end
    end
    size = size + math.nextPowerOfTwo(arraySize) * TVALUE_SIZE + math.nextPowerOfTwo(hashSize) * NODE_SIZE
    return size
  else
    error(string.format('unknown data type %s', t))
  end
end

-- set initial search paths
function setInitialSearchPaths()
  error("setInitialSearchPaths: no implementation specified")
end

-- addSearchPath, only add when the path wasn't already in
-- params: pos is optional
function addSearchPath(path, pos)
  error("addSearchPath: no implementation specified")
end

function enableGlobalVarsOnwards()
  if game.script ~= 'compiled' then
    setmetatable(_G, {})
  end
end

function disableGlobalVarsOnwards()
  -- disable implicit declaration of globals onwards
  -- but not in compiled mode, for hot reloading of codes on devices
  if game.script ~= 'compiled' then
    setmetatable(_G, {
      __newindex = function (_, n)
        error("You are declaring a global variable " ..n..debug.traceback())
      end,
      __index = function (_, n)
        error("You are reading a undeclared global variable "..n..debug.traceback())
      end,
    })
  end
end

-- clearing requires
-- will only work in compiled script mode
function clearRequires(include, exclude)
  include = include or function (name)
    local prefixes = {'lboot', 'game', 'rlua'}
    for _, prefix in ipairs(prefixes) do
      if string.find(name, prefix) == 1 then
        return true
      end
    end
    return false
  end

  for name, _v in pairs(package.loaded) do
    if (include == nil or include(name)) and
      (exclude == nil or (not exclude(name))) then
      -- ccwarning('reloading require: ' .. name)
      package.loaded[name] = nil
      local status, err = pcall(function () loadstring('require "' .. name .. '"') end)
      if not status then loge('require failed: ' .. err) end
    end
  end
end

-- load lua file
function loadLuaScript(script)
  local mode = lfs.attributes(script, 'mode')
  if mode and mode == 'file' then
    logd('loading ' .. tostring(script))

    local key, iv = getLuaEncryptionKey()
    local func, err = xt.loadfile_aes(script, key, iv)
    if func then
      func()
      logd('xt.loadfile success err=' .. tostring(err))
      return true
    else
      logd('xt.loadfile failed err=' .. tostring(err))
      func, err = loadfile(script)
      if func then
        func()
        logd('loadfile success err=' .. tostring(err))
        return true
      else
        logd('loadfile failed err=' .. tostring(err))
      end
    end
  else
    logd('script doesnt exist: ' .. tostring(script))
  end
end

-- load lua buffer
function loadLuaBuffer(buf, chunkname)
  local key, iv = getLuaEncryptionKey()
  local func, err = xt.loadstring_aes(buf, key, iv, chunkname)
  if func then
    func()
    logd('xt.loadstring success err=' .. tostring(err))
    return true
  else
    logd('xt.loadstring failed err=' .. tostring(err))
    func, err = loadstring(buf, chunkname)
    if func then
      func()
      logd('loadstring success err=' .. tostring(err))
      return true
    else
      logd('loadstring failed err=' .. tostring(err))
    end
  end
end

-- switch runtime environment to update folder
function switchEnv(rootFolder)
  logd('switchEnv: rootFolder=' .. tostring(rootFolder))

  local root
  if rootFolder then
    root = rootFolder
  else
    root = UpdateManager.rootpath()
  end

  logd('---------------------------------------------------------')
  logd('switching runtime environment to path: ' .. root)

  ------------------------------------------------------------------

  if game.script == 'compiled' then
    -- On devices, the scripts are packed to a single compiled file,
    -- just need to load the updated file again

    logd('reloading lua script')

    local script = root .. '/cl.lc'
    local loaded = loadLuaScript(script)
    if loaded then
      clearRequires()
    end
  else
    -- On simulator, the scripts are always loaded from developers'
    -- source folder, so there is no need to switch package path

    -- switch lua search paths
    --package.path = root .. "/?.lua;" .. package.path
    --package.cpath = root .. "/?.so;" .. package.cpath
    logd('no need to switching lua env in development')
  end

  ------------------------------------------------------------------

  -- purge cached data
  -- CCSpriteFrameCache:sharedSpriteFrameCache():removeUnusedSpriteFrames()
  -- display.director:purgeCachedData()

  -- CCCachedFileReader:instance():purgeCachedData()

  -- add search path
  rootFolder = rootFolder or UpdateManager.rootFolder()
  addSearchPath(rootFolder .. '/bundles/', 1)
  addSearchPath(rootFolder .. '/', 1)

  logd('SqliteConfigFile.useUpdates previous value is %s', tostring(SqliteConfigFile.useUpdates))
  SqliteConfigFile.useUpdates = true
  logd('---------------------------------------------------------')
  
  -- FINISHED
  -- from this point on, the game will use new scripts and new assets
end


function asyncHttp(options)
  local url = options.url
  local method = options.method or 'GET'
  local headers = options.headers or {}
  local onComplete = options.onComplete or function () end
  local onError = options.onError or function () end

  require 'lboot/net/socket/dispatch'
  dispatch.TIMEOUT = 15
  local handler = dispatch.newhandler('coroutine')
  local http = require 'lboot/net/socket/http'
  local tcp = handler.tcp()
  local done = false
  local handle = nil

  local run = function ()
    if not done then
      handler:step()
    else
      logd('asyncHttpGet done')
      scheduler.unschedule(handle)
    end
  end

  handler:start(function ()
    logd('asyncHttpGet started: ' .. url)
    local t = {}
    local r, c, h = http.request {
      url=url, method=method, tcp=tcp, headers=headers,
      sink = socket.ltn12.sink.table(t)
    }
    if r and c == 200 then
      if t then
        res = table.concat(t)
        onComplete(res)
      else
        onComplete(nil)
      end
    else
      onError(c)
    end

    logd('asyncHttpGet finished r=' .. tostring(r) .. ' c=' .. tostring(c))
    done = true
  end)

  handle = scheduler.schedule(run, 0.005, false, false)
end

-- ensure a function is executed in foreground
--
-- When android switches activities, it is possible for a callback
-- to be executed when the game activity is in background state.
--
-- There are a few limitations when a callback is executed in background state:
-- 1. No MsgEndpoint connections, can not send messages to the server
-- 2. Texture created during background state may not display correctly
--
-- This function ensures a closure is executed in the foreground.
-- update by xiaobin, 2014-11-12
function executeInForeground(func, ...)
  local arg = {...}
  local callback = function() func(unpack(arg)) end

  -- local signalName = 'reconnected' -- system reconnect signal
  local signalName = 'ReconnectHandler_done' -- app reconnect done signal

  if game.appInForeground then
    if mp:isConnected() then
      if game.keepConnection then -- in case of keep connection, delay callback to next frame to avoid texture crash
        logd('appInForeground, connected, keepConnection is true, calling func at the next frame')
        scheduler.performWithDelay(0, callback, false)
      else
        logd('appInForeground, connected, keepConnection is false, calling func immediately')
        func()
      end
    else
      logd('appInForeground, not connected, add func to reconnected signal')
      mp:signal(signalName):addOnce(callback)
    end
  else
    if mp:isConnected() then  -- in case of keep connection
      logd('appInBackground, connected, add func to sigEnterForeground signal')
      game.sigEnterForeground:addOnce(callback)
    else
      logd('appInBackground, not connected, add func to reconnected signal')
      mp:signal(signalName):addOnce(callback)
    end
  end
end

-- invoke callback if it's a function
function invokeCallback(callback, param)
  if type(callback) == 'function' then
    if param then
      executeInForeground(function()
        logd('invokeCallback with param')
        callback(param)
      end)
    else
      executeInForeground(function()
        logd('invokeCallback without param')
        callback()
      end)
    end
  else
    logd('invokeCallback is no funtion')
  end
end

-- start keep connection
-- there is a scheduler to check and end keep connection when timeout
function keepConnectionBegin(timeout)
  logd('keepConnectionBegin lock=%s %s', tostring(game.lockKeepConnection), debug.traceback())

  if game.lockKeepConnection then
    return
  end

  game.keepConnection = true
  scheduleKeepConnectionCheck(timeout)
end

-- end keep connection
function keepConnectionEnd()
  logd('keepConnectionEnd lock=%s %s', tostring(game.lockKeepConnection), debug.traceback())

  if game.lockKeepConnection then
    return
  end

  game.keepConnection = nil
  unscheduleKeepConnectionCheck()
end

function unscheduleKeepConnectionCheck()
  if game.keepConnectionHandler then
    scheduler.unschedule(game.keepConnectionHandler)
    game.keepConnectionHandler = nil
  end
end

-- schedule a fail-safe checker for keep connection value
-- to reset keep connection value after a maximum timeout
function scheduleKeepConnectionCheck(timeout)
  timeout = timeout or 600

  unscheduleKeepConnectionCheck()
  game.keepConnectionHandler = scheduler.schedule(function ()
    logd('keepConnectionCheck!')
    game.lockKeepConnection = nil
    keepConnectionEnd()
  end, timeout, false, true)
end

-- keep connection when executing a function
-- when the function ends use of lock, it should call the callback passed in
-- there can be only one keepConnectionWhen session at one time
function keepConnectionWhen(func, timeout)
  if game.lockKeepConnection then
    logd('keepConnectionWhen: lock=%s', tostring(game.lockKeepConnection))
    return
  end

  keepConnectionBegin(timeout)
  game.lockKeepConnection = true

  local callback = function ()
    game.lockKeepConnection = nil
    keepConnectionEnd()
  end

  local ok, err = pcall(func, callback)
  if not ok then
    loge('keepConnectionWhen: func err=%s', tostring(err))
    callback()
  end
end

function isLittleEndian()
  return bit.tohex(1) == '00000001'
end

-- logd("isLittleEndian=%s", tostring(isLittleEndian()))

-- format seconds to 'hh:mm:ss'
function formatDuration(seconds)
  local h = math.floor(seconds / 3600)
  local m = math.floor(seconds / 60 - h * 60)
  local s = seconds % 60
  return string.format("%02d:%02d:%02d", h, m, s)
end

function formatDuration2(seconds)
  local amin = 60
  local ahour = 60 * amin
  local aday = 24 * ahour
  local d = math.floor(seconds / aday)

  seconds = seconds % aday
  local h = math.floor(seconds / ahour)

  seconds = seconds % ahour
  local m = math.floor(seconds / amin)

  local s = seconds % amin

  if d > 0 then
    return string.format("%d天%d小时%d分%d秒", d, h, m, s)
  else
    if h > 0 then
      return string.format("%d小时%d分%d秒", h, m, s)
    else
      if m > 0 then
        return string.format("%d分%d秒", m, s)
      else
        return string.format("%d秒", s)
      end
    end
  end
  return ''
end

function formatDuration3(seconds)
  local amin = 60
  local ahour = 60 * amin
  local aday = 24 * ahour
  local d = math.floor(seconds / aday)

  seconds = seconds % aday
  local h = math.floor(seconds / ahour)

  seconds = seconds % ahour
  local m = math.floor(seconds / amin)

  local s = seconds % amin

  if d > 0 then
    return string.format("%d天", d)
  else
    if h > 0 then
      return string.format("%d小时", h)
    else
      if m > 0 then
        return string.format("%d分", m)
      else
        return string.format("%d秒", s)
      end
    end
  end
  return ''
end

function parse_duration2(str)
  local arr = string.split(str, ':')
  return arr[1]*3600+arr[2]*60+arr[3]
end

-- parse duration from string like '1h 2m 3s'
-- TODO handle no space
local tokens = { s = 1, m = 60, h = 3600, d = 3600 * 24 }
function parse_duration(s)
  s = string.gsub(s, 'min', 'm')
  s = string.gsub(s, 'sec', 's')
  s = string.gsub(s, 'hour', 'h')
  s = string.gsub(s, 'day', 'd')
  local seconds = 0
  local arr = string.split(s, ' ')
  for i = 1, #arr do local v = arr[i]
    seconds = seconds + string.sub(v, 1, -2) * tokens[string.at(v, -1)]
  end
  return seconds
end

-- decode multiple strings encoded in java
function decodeStrings(s)
  return unpack(string.split(s, '||'))
end

function prepareFile(file)
  -- return path_for_file, file_exists
  local path = file
  local mode = lfs.attributes(path , 'mode')

  if mode == 'file' then
    -- the file exists
    return path, true
  else
    -- make path for the file
    local dir = string.sub(path, 1, string.rfind(path, '/'))
    if mkpath(dir) then
      return path, false
    else
      return nil, false
    end
  end
end

function mkpath(path)
  local i, j = 1
  repeat
    i, j = string.find(path, '[/\\][^/^\\]+', j)
    local dir = string.sub(path, 1, j)
    local mode = lfs.attributes(dir, 'mode')
    if not mode then
      logd('mkdir: '..dir)
      local res, err = lfs.mkdir(dir)
      if not res and err ~= 'File exists' then
        logd('mkpath ' .. dir .. ' failed: ' .. err)
        return nil
      end
    end
  until not i
  return true
end

function rmpath(path)
  local res, msg = true, nil

  for file in lfs.dir(path) do
    local name = tostring(file)
    local fullname = path .. '/' .. name
    if string.find(name, '.', 1, true) ~= 1 then
      local mode = lfs.attributes(fullname, 'mode')
      if mode == 'directory' then
        res = res and rmpath(fullname)
        res = res and lfs.rmdir(fullname)
      elseif mode == 'file' then
        res = res and os.remove(fullname)
      end
    end
  end

  return res, msg
end

function coroutineStart(loop, duration, options)
  duration = duration or 0
  options = table.merge({global=false}, options)

  local co = coroutine.create(loop)
  local _loop
  local _handle
  local _resume = function(delta)
    local success, msg = coroutine.resume(co, delta)
    if not success then
      error(debug.traceback(co, msg))
    end
  end
  _resume(1)
  _loop = function(delta)
    if coroutine.status(co) ~= 'dead' then
      _resume(delta)
    else
      if options.onComplete then
        options.onComplete()
      end
      scheduler.unschedule(_handle)
    end
  end

  _handle = scheduler.scheduleWithUpdate(_loop, duration, false, options.global)
  return _handle
end

function pcall2(f)
  local ok, res = pcall(f)
  if ok then
    return res
  else
    loge('pcall failed: err=%s trace=%s', tostring(res), debug.traceback())
    return nil
  end
end

function formatDurationAdv(seconds)
  local tm = 60
  local th = tm*60
  local td = th*24
  local tw = th*24*7
  local tmn = td*30
  local s = ''
  if seconds>0 and seconds<td then
    s = formatDuration(seconds)
  elseif seconds>=td and seconds<tw then
    s = ''..math.floor(seconds/td)..loc('str_ui_day')
  elseif seconds>=tw and seconds<tmn then
    s = ''..math.floor(seconds/tw)..loc('str_ui_week')
  elseif seconds>=tmn then
    s = ''..math.floor(seconds/tmn)..loc('str_ui_month')
  end
  return s
end

function utf8gsub(...)
  local utf8 = require 'utf8'
  return utf8.gsub(...)
end

function utf8sub(str, startChar, numChars)
  local utf8 = require 'utf8'
  return utf8.sub(str, startChar, numChars)
end

function utf8len(str)
  local utf8 = require 'utf8'
  return utf8.len(str)
end

function utf8MakeShort(str, len)
  local utf8 = require 'utf8'

  if utf8.len(str) > len then
    return utf8.sub(str, 1, len) .. '...'
  else
    return str
  end
end

function utf8Escape(str)
  local utf8 = require 'utf8'
  return utf8.escape(str)
end

function dumpMemoryDebugInfo()
  logd("dumpMemoryDebugInfo is not implemented yet")
end

function dumpSystemInfo()
  logd("============= System Info ==============")
  local t = {}
  for k, v in pairs(game.systemInfo) do
    table.insert(t, {k, v})
  end
  table.sort(t, function (a, b) return a[1] < b[1] end)
  for i = 1, #t do local v = t[i]
    logd("%s = %s", tostring(v[1]), tostring(v[2]))
  end
  logd("============= System Info ==============")
end

-- profile using luaprofiler, ProFi.lua, pepperfish_profiler.lua

local prof, profType, profStartParam = nil, 'none', nil

function profileStart(t, param)
  if prof then
    loge('profileStart: already profiling! t=%s trace=%s', profType, debug.traceback())
  end

  profType = t
  if not profType then
    if game.platform == 'android' then
      -- on android pepperfish seems to print strange results
      profType = 'ProFi'
    else
      profType = 'pepperfish'
    end
  end
  profStartParam = param

  logd("profileStart: t=%s", profType)
  if profType == 'luaprofiler' then
    prof = require 'profiler'
    os.remove(profStartParam)
    prof.start(profStartParam)
  elseif profType == 'luaprofiler_vis' then
    prof = require 'profiler'
    os.remove(profStartParam)
    prof.start(profStartParam)
  elseif profType == 'ProFi' then
    prof = require 'lboot/ext/ProFi'
    prof:start()
  elseif profType == 'ProFi_vis' then
    prof = require 'lboot/ext/ProFi'
    prof:start()
  elseif profType == 'pepperfish' then
    prof = newProfiler('call')
    if prof then prof:start() end
  else
    error("profileStart: bad arguments!")
  end

  return prof
end

function profileRun(profiledFunc)
  local ok, res = pcall(profiledFunc)
  if not ok then
    loge("profileRun: error %s", peek(res))
    return nil
  else
    return res
  end
end

function profileStop(param)
  if not prof then return end
  local filename = param
  if not filename then
    if game.platform == 'editor' then
      filename = 'profile.txt'
    elseif game.platform == 'android' then
      filename = '/sdcard/race/profile_android.txt'
    end
  end
  local profRet = prof

  if profType == 'luaprofiler' then
    prof.stop()
    local s = require 'lboot/ext/luaprofiler_summary'
    s.summary(profStartParam, filename, true)
  elseif profType == 'luaprofiler_vis' then
    prof.stop()
    -- Allow caller to analyse luaprofiler.out by themselves
  elseif profType == 'ProFi' then
    prof:stop()
    prof:writeReport(filename)
    prof:reset()
  elseif profType == 'ProFi_vis' then
    prof:stop()
    -- Allow caller to analyse ProFi result by themselves
  elseif profType == 'pepperfish' then
    prof:stop()
    local outfile = io.open( filename, "w+" )
    prof:report( outfile, true )
    outfile:close()
  else
    error("profileStop: bad profType!")
  end
  logd("profileStop: t=%s", profType)
  prof, profType = nil, nil

  return profRet
end

function profile(f, t, startParam, stopParam)
  local prof = profileStart(t, startParam)
  if prof then
    local res = profileRun(f)
    profileStop(stopParam)
    return res
  else
    return f()
  end
end

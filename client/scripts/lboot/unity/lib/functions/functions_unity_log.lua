local LogUtil = LBoot.LogUtil
local string = string
local table = table
local debug = debug
local math = math
local os = os
local tostring = tostring
local rawget = rawget
local pcall = pcall
local unpack = unpack
local UnityEngine = UnityEngine

-- Set do not print out stack traces
-- Use SetStackTraceLogType(level, logType) in Unity 5.4
-- UnityEngine.Application.stackTraceLogType = 0
UnityEngine.Application.SetStackTraceLogType(0, 0)
UnityEngine.Application.SetStackTraceLogType(1, 0)
UnityEngine.Application.SetStackTraceLogType(2, 0)
UnityEngine.Application.SetStackTraceLogType(3, 0)
UnityEngine.Application.SetStackTraceLogType(4, 0)

function __G__TRACKBACK__(msg)
  loge(msg)
  loge(debug.traceback())
end

local __allLogs = nil
local __allErrorLogs = nil
local __allLogMaxLen = 3000

function RECORD_LOGS(msg, isError)
  __allLogs = __allLogs or {}
  __allLogs[#__allLogs + 1] = msg
  while #__allLogs > __allLogMaxLen do
    table.remove(__allLogs, 1)
  end

  if isError then
    __allErrorLogs = __allErrorLogs or {}
    __allErrorLogs[#__allErrorLogs + 1] = msg
    while #__allErrorLogs > __allLogMaxLen do
      table.remove(__allErrorLogs, 1)
    end
  end
end

function SET_RECORD_LOGS_MAX_LEN(val)
  __allLogMaxLen = val
end

function GET_RECORD_LOGS()
  return __allLogs
end

function GET_RECORD_ERROR_LOGS()
  return __allErrorLogs
end

-- printf
function printf(...)
  u3log(string.format(select(1, ...)))
end

function prt(...)
  u3log(...)
end

function print(...)
  u3log(...)
end

local function ensureStrings(array)
  for i = 1, #array do local v = array[i]
    array[i] = tostring(v)
  end
  return array
end

local socket = require 'lboot/net/socket/socket'

local function formatLogs(tag, msg)
  local time = socket.gettime()
  local itime = math.floor(time)
  local msecs = (time - itime) * 1000
  local tstr = tostring(os.date('%X', itime))
  msg = string.format('%s.%03d [%s] %s', tstr, msecs, tag, msg)
  return msg

  -- local ServerTime = rawget(_G, 'ServerTime')
  -- if ServerTime and ServerTime.time then
  --   local time = ServerTime.time()
  --   local tstr = tostring(os.date('%X', time))
  --   msg = string.format('%s [%s] %s', tstr, msecs, tag, msg)
  -- else
  --   msg = string.format('[%s] %s', tag, msg)
  -- end
  -- return msg
end

function u3log(...)
  local arg = ensureStrings({...})
  local status, res = pcall(string.format, unpack(arg))
  if status then
    local msg = formatLogs('GAME', res)

    LogUtil.Debug(msg)

    RECORD_LOGS(msg)
  else
    local msg = formatLogs('GAME', 'print failed')
    local trace = debug.traceback()

    LogUtil.Debug(msg)
    loge(trace)

    RECORD_LOGS(msg)
    RECORD_LOGS(trace)
  end
end


function logerror(...)
  local arg = ensureStrings({...})
  local status, res = pcall(string.format, unpack(arg))
  if status then
    local msg = formatLogs('GAME Error', tostring(res))

    LogUtil.Error(msg)

    RECORD_LOGS(msg, true)
  else
    local msg = formatLogs('GAME Error', 'print failed')
    local trace = debug.traceback()

    LogUtil.Error(msg)
    loge(trace)

    RECORD_LOGS(msg, true)
    RECORD_LOGS(trace, true)
  end
end

function logwarn(...)
  local arg = ensureStrings({...})
  local status, res = pcall(string.format, unpack(arg))
  if status then
    local msg = formatLogs('GAME', tostring(res))

    LogUtil.Warn(msg)

    RECORD_LOGS(msg)
  else
    local msg = formatLogs('GAME', 'print failed')
    local trace = debug.traceback()

    LogUtil.Warn(msg)
    loge(trace)

    RECORD_LOGS(msg)
    RECORD_LOGS(trace)
  end
end

function loginfo(...)
  u3log(...)
end

function logdebug(...)
  -- u3log(debug.traceback())
  u3log(...)
end

function logtrace(...)
  u3log(...)
end

local function __log_disabled(...)
end

function setLogLevel(level)
  -- if level == 'none' then
  --   declare('logerror', __log_disabled)
  --   declare('logwarn', __log_disabled)
  --   declare('loginfo', __log_disabled)
  --   declare('logdebug', __log_disabled)
  --   declare('logtrace', __log_disabled)
  -- elseif level == 'error' then
  --   declare('logwarn', __log_disabled)
  --   declare('loginfo', __log_disabled)
  --   declare('logdebug', __log_disabled)
  --   declare('logtrace', __log_disabled)
  -- elseif level == 'warn' then
  --   declare('loginfo', __log_disabled)
  --   declare('logdebug', __log_disabled)
  --   declare('logtrace', __log_disabled)
  -- elseif level == 'info' then
  --   declare('logdebug', __log_disabled)
  --   declare('logtrace', __log_disabled)
  -- elseif level == 'debug' then
  --   declare('logtrace', __log_disabled)
  -- else
  --   error("invalid log level")
  -- end

  declare('loge', logerror)
  declare('logw', logwarn)
  declare('logi', loginfo)
  declare('log',  loginfo)
  declare('logd', logdebug)
  declare('logt', logtrace)
end

-- compatible with legacy code
declare('ccwarn', logdebug)
declare('ccwarning', logdebug)
declare('d', logdebug)

setLogLevel('debug')

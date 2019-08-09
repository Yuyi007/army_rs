
local rawget = rawget

function __G__TRACKBACK__(msg)
  loge(msg)
  loge(debug.traceback())
end

-- printf
function printf(...)
  print(string.format(select(1, ...)))
end

local function ensureStrings(array)
  for i = 1, #array do local v = array[i]
    array[i] = tostring(v)
  end
  return array
end

function _log(...)
  local arg = ensureStrings({...})
  local status, res = pcall(string.format, unpack(arg))
  local str
  if status then
    str = '[LUA] '..res
  else
    str = '[LUA] print failed ' .. debug.traceback()
  end

  print(str)
  local game = rawget(_G, 'game')
  if game and game.dvlogon then dvlog(str) end
end

function logerror(...)
  local arg = ensureStrings({...})
  local status, res = pcall(string.format, unpack(arg))
  local str
  if status then
    str = '[LUA Error] ' .. tostring(res)
  else
    str = '[LUA Error] print failed ' .. debug.traceback()
  end

  print(str)
  local game = rawget(_G, 'game')
  if game and game.dvlogon then dvlog(str) end
end

function logwarn(...)
  local arg = ensureStrings({...})
  local status, res = pcall(string.format, unpack(arg))
  local str
  if status then
    str = '[LUA] ' .. tostring(res)
  else
    str = '[LUA] print failed ' .. debug.traceback()
  end

  print(str)
  local game = rawget(_G, 'game')
  if game and game.dvlogon then dvlog(str) end
end

function loginfo(...)
  _log(...)
end

function logdebug(...)
  _log(...)
end

function logtrace(...)
  _log(...)
end

local function __log_disabled(...)
end

function setLogLevel(level)
  if level == 'none' then
    declare('logerror', __log_disabled)
    declare('logwarn', __log_disabled)
    declare('loginfo', __log_disabled)
    declare('logdebug', __log_disabled)
    declare('logtrace', __log_disabled)
  elseif level == 'error' then
    declare('logwarn', __log_disabled)
    declare('loginfo', __log_disabled)
    declare('logdebug', __log_disabled)
    declare('logtrace', __log_disabled)
  elseif level == 'warn' then
    declare('loginfo', __log_disabled)
    declare('logdebug', __log_disabled)
    declare('logtrace', __log_disabled)
  elseif level == 'info' then
    declare('logdebug', __log_disabled)
    declare('logtrace', __log_disabled)
  elseif level == 'debug' then
    declare('logtrace', __log_disabled)
  else
    error("invalid log level")
  end

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

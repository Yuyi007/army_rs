
class('LuaScriptDebugger', function ()
end)

local m = LuaScriptDebugger

function m.initHostIp()
  local user = os.getenv("USER") or "none" -- now not available in IOS 8 simulator
  local home = os.getenv("HOME") -- not available on Android
  local platform = game.platform

  if not user then
    local a, b = string.match(home, '^/([^/]+)/([^/]+)')
    user = b
  end

  -- Add your debugger host ip here:
  local hostIpTable = {
    duwenjie = '127.0.0.1',
    ios = nil,
    android = nil,
  }
  local hostIp = hostIpTable[user] or hostIpTable[platform] or '127.0.0.1'

  logd('LuaScriptDebugger.lua: user=%s', tostring(user))
  logd('LuaScriptDebugger.lua: home=%s', tostring(home))
  logd('LuaScriptDebugger.lua: hostIp=%s', tostring(hostIp))

  return hostIp
end

function m.start()
  m.mobdebug = require 'lboot/ext/mobdebug'
  local hostIp = m.initHostIp()

  local ok, res = pcall(function () m.mobdebug.start(hostIp) end)
  logd('LuaScriptDebugger.lua: debugger started=%s res=%s', tostring((res == true)), tostring(res))

  return res or false
end

function m.stop()
  if m.mobdebug then
    local ok, err = pcall(function () m.mobdebug.done() end)
    logd('LuaScriptDebugger.lua: debugger done err=%s', tostring(err))

    m.mobdebug = nil
  else
    -- logd('LuaScriptDebugger.lua: debugger not exists!')
  end
end

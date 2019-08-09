package.path = package.path..";../../?.lua;"
skynet  = require "skynet"
require "skynet.manager"
socket  = require "skynet.socket"

local CMD = {}
local uconnect = nil

function CMD.init()
  local host = skynet.getenv("statsd_host") or "127.0.0.1"
  local port = skynet.getenv("statsd_port") or 8125

  uconnect = socket.udp(function(data, size, from) end)
  socket.udp_connect(uconnect, host, port)
end

function CMD.sendData(data)
  if not uconnect then
    return
  end

  socket.write(uconnect, data)
  --print ("statsd Service send data ", data)  ...
end

skynet.start(function()  
  print("Service start statsd")

  skynet.dispatch("lua", function(_,_, command, ...)
        local f = CMD[command]
        local res = f(...)
        if res then
          skynet.ret(skynet.pack(res))
        end
      end)

  skynet.register(".stat")
end)

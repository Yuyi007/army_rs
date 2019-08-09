package.path = package.path..";../../?.lua;"
lkcp    = require "lkcp"
skynet_core = require "skynet.core"

require "inspect"
require "winnie/winnie"
statsDB = require "statsd"
require "app/combat/gate/udpclient"
require "app/combat/gate/udpencoding"
require "app/combat/dispatcher"

isShareAgent = false

local client = UdpClient.new()
local hself = skynet.self()

skynet.register_protocol {
  name = "client",
  id = skynet.PTYPE_CLIENT,
  unpack = skynet_core.unpackext,

  dispatch = function (session, source, from, str, isHandShake, sessionid, gatesockid)
    local addr, port = socket.udp_address(from)
    --print(hself, "@@@@@@@@@@@@@@recv data:", str, addr, port, isHandShake, sessionid, gatesockid)

    if client then
        if isHandShake == 1 then
          client:setAddrInfo(addr, port)
          client:init(0, sessionid, gatesockid)
        end

        client:onSockRecvDD(str)
    end
  end
}

skynet.start(function()
    RedisHelper.start()
    --client = UdpClient.new()

    --[[local hTimer = Scheduler.schedule(500, function()
        collectgarbage("collect")
    end)--]]

    skynet.dispatch("lua", function(_, addr, command, ...)
          --print("lua dispatch addr - ", command, client[command])

          local f = client[command]
          local ok, res = pcall(f, client, ...)
          if ok then
            --skynet.ret(skynet.pack(res))
          end

          if command == "onRecycle" then 
            skynet.exit()
          end
        end)
  end)

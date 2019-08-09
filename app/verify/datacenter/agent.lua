package.path = package.path..";../../?.lua;"
skynet  = require "skynet"
socket  = require "skynet.socket"
require "inspect"
require "skynet.manager"
require "winnie/winnie"
--statsDB = require "statsd"

require "app/verify/datacenter/tcpclient"  
require "app/verify/datacenter/tcpencoding" 

local queue = require "skynet.queue"
local cs = queue()  

local datacenter, idSock, addr = ...
local tcpClient = nil

local function doRequest(data)
  local msg = TcpEncoding.decode(data)
  --print("receive request :", inspect(msg))

  tcpClient:onRecvData(msg)
end

local function doSocket(id)
  socket.start(id)

  -- tcpClient:sockSend("hello client") -- test

  while true do
    local size = 2
    local str = socket.read(id, size)
    if (str == nil) or (str==false) then break end

    local ilen, i = string.unpack(">H", str)
    print("data len:", ilen)

    if ilen then
      local data = socket.read(id, ilen)
      if (data == nil) or (data==false) then break end
      print("client ", id, " recvdata:", data, "len:", ilen)

      -- cs(doRequest, data)
      doRequest(data)
    else
      break
    end
    skynet.sleep(0)
  end

  print("client ", addr, "disconnected!")
  socket.close(id)

  skynet.send(datacenter, "lua", "removeAgent", skynet.self())
  skynet.exit()
end

--------------------------------------------------------------------------

skynet.start(function()
    print("Service start agent for ", addr, skynet.self())

    idSock = tonumber(idSock)
    tcpClient = TcpClient.new()
    tcpClient:init(datacenter, idSock, addr)

    skynet.fork(function()
      doSocket(idSock)
    end)

    skynet.dispatch("lua", function(_,_, command, ...)
        print("agent", skynet.self(), "recv command", command, ...)

        local f = tcpClient[command]
        local ok, res = pcall(f, tcpClient, ...)
        
        if ok then
          skynet.ret(skynet.pack(res))
        end
      end)
  end)

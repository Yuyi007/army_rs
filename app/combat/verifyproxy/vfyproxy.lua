package.path = package.path..";../../?.lua;"
skynet  = require "skynet"
require "skynet.manager"
socket  = require "skynet.socket"

require "winnie/winnie"
require "inspect"
require "app/verify/datacenter/tcpencoding" 

local queue = require "skynet.queue"
local cs = queue()  

-------------------------------------------------------------------------

local CMD = {}
local tconnect = nil

local function doResponse(data)
  local msg = TcpEncoding.decode(data)

  print("recv verify server msg:", inspect(msg))
end

local function doSock(host, port)
  while true do
    if tconnect then
      socket.close(tconnect)
      tconnect = nil
    end

    print("connecting verify server", host, port)
    while not tconnect do
      tconnect = socket.open(host, port)
      if not tconnect then
        --print("connect ", host, port, " failed!")
        skynet.sleep(500)
      end
    end

    print("verify server connected")
    
    --socket.start(tconnect)

    while true do
      local size = 2
      local str = socket.read(tconnect, size)
      if (str == nil) or (str==false) then break end

      local ilen, i = string.unpack(">H", str)
      print("data len:", ilen)

      if ilen then
        local data = socket.read(tconnect, ilen)
        if (data == nil) or (data==false) then break end
        print("verify proxy ", tconnect, " recvdata:", data, "len:", ilen)

        cs(doResponse, data)
      else
        break
      end
    end
  end
end 

local function doTest()
  local frame = 1

  while true do
    if not tconnect then 
      skynet.sleep(100)
    else
      local token = "100000001"
      if skynet.self() % 2 == 0  then
        CMD.clearRoomInfo(token)
      end

      skynet.sleep(100)     

      while true do
        local data = "testdata"..tostring(frame)
        if frame % 4 == 0 then 
          data = tostring(skynet.self() % 2)
        end

        CMD.frameCheck(skynet.self(), token, frame, data)

        frame = frame + 1
        skynet.sleep(5)
      end
      -- break
    end
  end
end

--------------------------------------------------------------------------

function CMD.init()
  local host = skynet.getenv("verify_host") or "127.0.0.1"
  local port = skynet.getenv("verify_port") or 7668

  skynet.fork(doSock, host, port)
  -- skynet.fork(doTest)
end

function CMD.sendData(msg)
  if not tconnect then
    print("gate proxy offline ")
    return
  end

  local data = TcpEncoding.encode(msg)
  local buf = string.pack(">s2", data)
  local res = socket.write(tconnect, buf)
  if res == false then
    socket.close(tconnect)
    print("gate proxy offline ")
  else
    print ("gate proxy Service send data ", inspect(msg))
  end
end

function CMD.clearRoomInfo(token)
  local msg = {}
  msg.cmd = 1000
  msg.token = token

  CMD.sendData(msg)
end

function CMD.frameCheck(cid, token, frame, data)
  local msg = {}

  msg.cmd = "1001"
  msg.type = "1001"
  msg.token = token
  msg.frame = tostring(frame)
  msg.cid = tostring(cid)
  msg.data = data

  CMD.sendData(msg)
end

function CMD.removeRoomVfyService(token)
  local msg = {}
  msg.cmd = 2000
  msg.token = token

  CMD.sendData(msg)
end

skynet.start(function()  
  print("Service start verify proxy")

  skynet.dispatch("lua", function(_,_, command, ...)
        local f = CMD[command]
        local res = f(...)
        if res then
          skynet.ret(skynet.pack(res))
        end
      end)

  skynet.register(".vfyproxy")
end)

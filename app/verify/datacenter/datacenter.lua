package.path = package.path..";../../?.lua;"
skynet  = require "skynet"
socket  = require "skynet.socket"
require "inspect"
require "winnie/winnie"
require "app/verify/datacenter/tcpserver"  

--------------------------------------------------------------------------

local CMD = {}
local sock = nil

local RoomVfyServices = {}
AgentServices = {}

function CMD.start(addr, port)
  --RedisHelper.start()
  startServer(addr, port)

  return true
end

function CMD.send_client_msg(addr, sid, cmd, msg)
  
end

function CMD.removeClient(addr, port)
  
end

function CMD.newRoomVfyService(token)
  CMD.removeRoomVfyService(token)
  
  local dt = skynet.newservice("verification", token)
  skynet.send(dt, "lua", "init", token)

  RoomVfyServices[token] = dt

  for k,v in pairs(AgentServices) do
    skynet.send(k, "lua", "updateRoomVfyService", token, dt)
  end
end

function CMD.getRoomVfyService(token)
  return RoomVfyServices[token]
end

function CMD.removeRoomVfyService(token)
  local room = RoomVfyServices[token]
  if room then 
    for k,v in pairs(AgentServices) do
      skynet.send(k, "lua", "removeRoomVfyService", token)
    end

    skynet.send(room, "lua", "exitRoom")
    RoomVfyServices[token] = nil
  end
end

function CMD.removeAgent(agent)
  AgentServices[agent] = nil
end

skynet.start(function()
    print("Service start datacenter")

    skynet.dispatch("lua", function(_,_, command, ...)
        local f = CMD[command]
        local res = f(...)
        if res then
          skynet.ret(skynet.pack(res))
        end
      end)
  end)

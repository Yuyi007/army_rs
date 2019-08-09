package.path = package.path..";../../?.lua;"
skynet  = require "skynet"
socket  = require "skynet.socket"

function startServer(addr, port)
  local id = socket.listen(addr, port)
  print("Listen socket :", addr, port)

  socket.start(id , function(id, addr)
    print("connect from " .. addr .. " " .. id)

    local agt = skynet.newservice("agent", skynet.self(), id, addr)
    AgentServices[agt] = skynet.now()
  end)
end

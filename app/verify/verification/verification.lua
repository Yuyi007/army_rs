package.path = package.path..";../../?.lua;"
skynet  = require "skynet"
require "inspect"
require "winnie/winnie"
require "app/verify/verification/verify"  

--verification <==> room
--local Roomtoken = ...

--------------------------------------------------------------------------
local vfy = nil

skynet.start(function()
    vfy = Verify.new()
    vfy:init()

    print("Service start verification")

    skynet.dispatch("lua", function(_,addr, command, ...)
        if command == "exitRoom" then 
          vfy = nil
          skynet.exit()
          return
        end

        local f = vfy[command]
        local ok, res = pcall(f, vfy, addr, ...)
        
        if ok then
          skynet.ret(skynet.pack(res))
        end
      end)
  end)

skynet 	= require "skynet"

local CMD = {}

function CMD.start()

	return true
end


skynet.start(function()
	print("Service start keep alive")
	skynet.dispatch("lua", function(_,_, command, ...)
        local f = CMD[command]
        local res = f(...)
        if res then
          skynet.ret(skynet.pack(res))
        end
      end)
end)
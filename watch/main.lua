local skynet = require "skynet"


skynet.start(function()

    print("======Server start=======")

    skynet.newservice("service1")

    --skynet.exit()
end)
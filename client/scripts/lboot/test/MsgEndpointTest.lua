-- MsgEndpointTest.lua
-- Unit test for MsgEndpoint (test with local servers)
-- Include me to perform the test

local mp = MsgEndpoint.new()
mp:init(game.defaultHost, game.defaultPort)

local updateMsg = {
  platform = 'ios',
  sdk = 'firevale',
  market = '',
  location = '',
  texSize = '',
  pkgVersion = '',
  appVersion = '',
  version = '',
  encoding = 0,
  ip = mp:getLocalIp()
}

mp:sendMsg(1, updateMsg, function (msg)
  print('update success! ' .. peek(msg))

  -- for below the server needs to support batch

  -- mp:queueMsg(1, updateMsg, function (msg)
  --   print('update success! ' .. peek(msg))
  -- end)

  -- mp:queueMsg(1, updateMsg, function (msg)
  --   print('update success! ' .. peek(msg))
  -- end)

  mp:sendMsg(1, updateMsg, function (msg)
    print('update success! ' .. peek(msg))
  end)
end)
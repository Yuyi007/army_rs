-- VideoPlayer.lua
local luaoc = require('lboot/lib/luaoc')

class('VideoPlayer', function(self)
end)

function VideoPlayer:play(file, onComplete, onTouch)
  onTouch = onTouch or function() end
  if game.platform == 'ios' then
    -- local ok, ret = luaoc.callStaticMethod(OCLASS_IOS_UTILS, 'showMessageBox', {
    local ok, ret = luaoc.callStaticMethod('MoviePlayer', 'play',
      { url = engine.fullPathForFilename(file),
        cleanup = 0,
        x = 0,
        y = 0,
        width = 960,
        height = 640,
        callback = function (msg)
          logd('play ' .. tostring(file) .. ' has finished')
          onComplete(msg)
        end,
      })

    return ret
  elseif game.platform == 'android' then
    local ok, ret = luaj.callStaticMethod('com/yousi/MoviePlayer', 'play',
      { engine.fullPathForFilename(file), -- url
        0, -- x
        0, -- y
        960, -- width
        640, -- height
        function (msg) -- complete callback
          logd('play ' .. tostring(file) .. ' has finished')
          onComplete(msg)
        end,
        function (msg) -- onTouch callback
          logd('movie touched ' .. tostring(file))
          onTouch(msg)
        end,
      })
    return ret
  elseif game.platform == 'wp8' then
    Wp8MoviePlayer:sharedPlayer():play(
      engine.fullPathForFilename(file),
      0,
      0,
      960,
      640,
      function ()
        onComplete(nil)
      end
      )
    return true
  else
    logd('play: not implemented yet')
    scheduler.performWithDelay(0, function ()
      onComplete(nil)
    end, false)
  end

  return nil
end

function VideoPlayer:stop()
  if game.platform == 'ios' then
    local ok, ret = luaoc.callStaticMethod('MoviePlayer', 'stop', { })
    return ret
  elseif game.platform == 'android' then
    local ok, ret = luaj.callStaticMethod('com/yousi/MoviePlayer', 'stop', { })
    return ret
  elseif game.platform == 'wp8' then
    Wp8MoviePlayer:sharedPlayer():stop()
  else
    logd('stop: not implemented yet')
  end

  return nil
end
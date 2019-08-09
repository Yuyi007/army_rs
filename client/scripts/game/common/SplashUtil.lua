class('SplashUtil')

local m = SplashUtil
local luaj = require('lboot/lib/luaj')
local JCLASS_SPLASH = 'com/yousi/race/SplashController'

function m.showSplash()
  if game.ios() then
    
  elseif game.android() then
    luaj.callStaticMethod(JCLASS_SPLASH, 'showSplashScreen', {})
  end
end

function m.hideSplash()
  if game.ios() then
    
  elseif game.android() then
    luaj.callStaticMethod(JCLASS_SPLASH, 'hideSplashScreen', {})
  end
end


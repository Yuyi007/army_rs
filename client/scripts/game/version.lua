-- version.lua

return function ()
  -- make sure only set pkg version once per game
  local function setPkgVersion(version)
    if type(game.pkgVersion) == 'string' and string.len(game.pkgVersion) > 0 then
      logd('game.pkgVersion is ' .. tostring(game.pkgVersion) ..
        ', refuse to change to ' .. tostring(version))
    else
      logd('setting game.pkgVersion to ' .. tostring(version))
      game.pkgVersion = version
    end
  end

  -- package version, modify when package changed
  -- previous version v0.0.2
  -- when server is set to v0.0.2 as force update pkg_version, the v0.0.3 (or above) ipa/apk clients will not fetch update from cdn
  -- this solves pre-upload ipa/apk before cdn update problems
  -- important: remember to clear the pkg version on gm tool when the new ipa/apk is released
  setPkgVersion('v0.0.3')

  -- the game version number to display to player (clientVersion decides updates)
  -- game.version = 'v0.3.5'
end
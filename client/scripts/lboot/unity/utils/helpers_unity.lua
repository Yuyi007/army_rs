
function setInitialSearchPaths()
  -- add a default search path for each platform
  logd('setInitialSearchPaths')
  local bundleSearchPath = ''

  if PLATFORM == 'editor' then
    if game.shouldLoadAssetInEditor() then
      bundleSearchPath = UnityEngine.Application.dataPath .. "/../AssetBundles/ios/"
    else
      bundleSearchPath = UnityEngine.Application.dataPath .. "/../AssetBundles/osx/"
    end
  elseif PLATFORM == 'osx' then
    bundleSearchPath = UnityEngine.Application.dataPath .. "/../../AssetBundles/osx/"
  elseif PLATFORM == 'android' then
    if game.mode == 'development' and
      rawget(_G, 'RESOURCE_FOLDER') then
      bundleSearchPath = RESOURCE_FOLDER .. '/bundles/'
      addSearchPath(RESOURCE_FOLDER .. '/', 1)
    else
      bundleSearchPath = 'bundles/'
    end
  elseif PLATFORM == 'ios' then
    bundleSearchPath = 'bundles/'
  elseif PLATFORM == 'server' then
  else
    error('invalid platform ' .. tostring(PLATFORM) .. '!')
  end

  logd('adding search path ' .. bundleSearchPath)

  addSearchPath(bundleSearchPath)

  addSearchPath()
end

-- addSearchPath, only add when the path wasn't already in
-- params: pos is optional
-- important: the path added should be a relative path, not absolute.
function addSearchPath(path, pos)
  local FileUtils = LBoot.FileUtils

  local paths = FileUtils.GetSearchPaths().Table
  local found = FileUtils.HasSearchPath(path)
  if not found then
    logd('add search path: ' .. tostring(path) .. ' pos=' .. tostring(pos))
    if pos then
      table.insert(paths, pos, path)
    else
      table.insert(paths, path)
    end
  else
    logd('already have search path: ' .. tostring(path))
  end

  paths = Slua.MakeArray(String, paths)
  FileUtils.SetSearchPaths(paths)

  -- debug: print search paths
  paths = FileUtils.GetSearchPaths().Table
  for i = 1, #paths do local p = paths[i]
    logd('search path: ' .. tostring(p))
  end
end

function getLuaEncryptionKey()
  local key, iv = LBoot.LuaUtils.ByteArrayToLuaString(LBoot.LBootApp.LUA_KEY),
    LBoot.LuaUtils.ByteArrayToLuaString(LBoot.LBootApp.LUA_IV)
  return key, iv
end

function getBundleEncryptionKey()
  local key, iv = LBoot.LuaUtils.ByteArrayToLuaString(LBoot.LBootApp.BUNDLE_KEY),
    LBoot.LuaUtils.ByteArrayToLuaString(LBoot.LBootApp.BUNDLE_IV)
  return key, iv
end

function getCommEncryptionKey()
  local commKey, commNonce = LBoot.LuaUtils.ByteArrayToLuaString(LBoot.LBootApp.COMM_KEY),
    LBoot.LuaUtils.ByteArrayToLuaString(LBoot.LBootApp.COMM_NONCE)
  return commKey, commNonce
end

function optimizeResolution(designWidth, designHeight, fullscreen)
  local current = { width=Screen.width, height=Screen.height }
  logd('current resolution %dx%d', current.width, current.height)

  for _, ratio in ipairs({ 2, 1.5 }) do
    local opWidth = math.floor(current.width / ratio)
    local opHeight = math.floor(current.height / ratio)

    logd('trying resolution %dx%d', opWidth, opHeight)
    if opWidth >= designWidth and opHeight >= designHeight then
      logd('optimize resolution by ratio %f', ratio)
      Screen.SetResolution(opWidth, opHeight, false)
      break
    end
  end
end

function not_null(o)
    return not is_null(o)
end

function is_null(o)
    if o == nil or o == cjson.null then return true end
    if type(o) == 'userdata' then
      return Slua.IsNull(o)
    end
    return false
end

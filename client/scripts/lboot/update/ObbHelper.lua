-- ObbHelper.lua
-- Helper to download and init the obb package

class('ObbHelper', function (self)
end)

local luaj = require('lboot/lib/luaj')
local clazz = 'com/yousi/lib/ObbHelper'

-- get expansion files on external storage
function ObbHelper.getExpansionFiles(onComplete)
  -- check existence of expansion files
  local ok, ret = luaj.callStaticMethod(clazz, 'getExpansionFilesLua', {
    function (jsonResult)
      logd('getExpansionFiles result=' .. tostring(jsonResult))
      local msg = cjson.decode(jsonResult)
      onComplete(msg)
    end
  })

  if not ok then
    logd('getExpansionFiles Error ' .. tostring(ret))
    onComplete({ success=false })
  end

  return ok
end

-- uncompress one file
function ObbHelper.uncompressOneFile(srcfile, dstfile, onComplete)
  local ok, ret = luaj.callStaticMethod(clazz, 'uncompressOneFileLua', {
    srcfile,
    dstfile,
    function (jsonResult)
      logd('uncompressOneFile result=' .. tostring(jsonResult))
      local msg = cjson.decode(jsonResult)
      onComplete(msg)
    end
  })

  if not ok then
    logd('uncompressOneFile Error ' .. tostring(ret))
    onComplete({ success=false })
  end

  return ok
end

-- uncompress specified files
function ObbHelper.uncompressFiles(destpath, files, onProgress, onComplete)
  local ok, ret = luaj.callStaticMethod(clazz, 'uncompressFilesLua', {
    destpath,
    files,
    function (jsonResult)
      local msg = cjson.decode(jsonResult)
      onProgress(msg)
    end,
    function (jsonResult)
      logd('uncompressFiles result=' .. tostring(jsonResult))
      local msg = cjson.decode(jsonResult)
      onComplete(msg)
    end
  })

  if not ok then
    logd('uncompressFiles Error ' .. tostring(ret))
    onComplete({ success=false })
  end

  return ok
end

-- uncompress the whole obb content to external storage
function ObbHelper.uncompressExpansionFile(destpath, onProgress, onComplete)
  local obbpath = UpdateManager.rootpath()
  mkpath(obbpath)

  local ok, ret = luaj.callStaticMethod(clazz, 'uncompressExpansionFileLua', {
    obbpath,
    function (jsonResult)
      local msg = cjson.decode(jsonResult)
      onProgress(msg)
    end,
    function (jsonResult)
      logd('uncompressExpansionFile result=' .. tostring(jsonResult))
      local msg = cjson.decode(jsonResult)
      onComplete(msg)
    end,
  })

  if not ok then
    logd('uncompressExpansionFile Error ' .. tostring(ret))
    onComplete({ success=false })
  end

  return ok
end

-- download obb file from google play
function ObbHelper.downloadObbFile(onProgress, onComplete)
  local ok, success = luaj.callStaticMethod(clazz, 'downloadObbFileLua', {
    function (jsonResult)
      local msg = cjson.decode(jsonResult)
      onProgress(msg)
    end,
    function (jsonResult)
      logd('downloadObbFile result=' .. tostring(jsonResult))
      local msg = cjson.decode(jsonResult)
      onComplete(msg)
    end,
  })

  if not ok then
    logd('downloadObbFile Error ' .. tostring(ret))
    onComplete({ success=false })
  end

  return ok
end

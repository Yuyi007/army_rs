-- functions_unity_engine.lua
--
-- This implementation defines functions target at Unity3D

-- engine table is defined in functions_engine.lua

local io = io
local xt = require 'xt'
local FileUtils = LBoot.FileUtils
local unity = unity

function engine.time()
  return Time:get_time()
end

function engine.realtime()
  return Time:get_realtimeSinceStartup()
end

function engine.saveUserPrefs(table)
  for k, v in pairs(table) do
    unity.setString(k, v)
  end
end

function engine.loadUserPref(key)
  return unity.getString(key)
end

function engine.getCStringFromFile(path)
  local data, len = engine.getStringFromFile(path)
  -- logd('getCStringFromFile: path=%s len=%d', path, len)
  if data then
    return data
  end
  return nil
end

function engine.getStringFromFile(path)
  -- WARNING: This implementation bloats C# heap
  -- local data = FileUtils.GetDataFromFile(path)
  -- local str = LBoot.LuaUtils.ByteArrayToLuaString(data)
  -- return str, LBoot.LuaUtils.ByteArrayLength(data)

  local fullpath = FileUtils.GetFullPathOfFile(path)
  -- logd('getStringFromFile: path=%s fullpath=%s', tostring(path), tostring(fullpath))

  if not fullpath then return nil end

  local jarfile, match = string.gsub(fullpath, '^jar:file:/.*/assets/', '')
  local data
  if match > 0 then
    data = xt.readDataFromAppJarFile(jarfile, 0, 0)
  else
    data = io.readfile(fullpath)
  end
  return data, string.len(data)
end

function engine.getStringFromFileIter(path)
  local fullpath = FileUtils.GetFullPathOfFile(path)
  -- logd('getStringFromFileIter: path=%s fullpath=%s', tostring(path), tostring(fullpath))

  if not fullpath then return nil end

  local jarfile, match = string.gsub(fullpath, '^jar:file:/.*/assets/', '')
  local offset, size = 0, 2 * 1024 * 1024
  if match > 0 then
    return function ()
      local data = xt.readDataFromAppJarFile(jarfile, offset, size)
      if data then
        local len = string.len(data)
        -- logd('getStringFromFileIter: jar path=%s len=%s', path, len)
        offset = offset + len
        return data, len
      end
    end
  else
    local file = io.open(fullpath, "r")
    return function ()
      local data = file:read(size)
      if data then
        local len = string.len(data)
        -- logd('getStringFromFileIter: path=%s len=%s', path, len)
        return data, len
      else
        io.close(file)
      end
    end
  end
end

function engine.getCStringFromZipFile(path)
  local data = engine.getStringFromFile(path)
  local str = zlib.inflate()(data)
  return str
end

function engine.getWritablePath()
  return FileUtils.GetWritablePath()
end

function engine.isFileExistsInRawPath(path)
  return FileUtils.IsFileExistsInRawPath(path)
end

function engine.getDataFromRawPath(path)
  -- This bloats C# heap
  -- return FileUtils.GetDataFromRawPath(path)
  return io.readfile(path)
end

function engine.isFileExistsInPackage(path)
  return FileUtils.IsFileExistsInStreamingAssets(path)
end

function engine.fullPathForFilename(file)
  return FileUtils.GetFullPathOfFile(file)
end

function engine.copyFile(srcfile, dstfile)
  -- This bloats C# heap
  return FileUtils.CopyFile(srcfile, dstfile, true)
end

function engine.deleteFile(file)
  return FileUtils.DeleteFile(file)
end

function engine.beginSample(label)
  return unity.beginSample(label)
end

function engine.endSample()
  return unity.endSample()
end

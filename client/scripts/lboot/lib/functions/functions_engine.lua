-- functions_engine.lua
--
-- This file defines platform specific functions
-- according to game engine and deployment platform used
--
-- Thus Providing a platform-agnostic layer for base libs
--
-- This is a placeholder file

declare('engine', {})

-- return time in seconds
function engine.time()
  error("functions_engine: no implemention specified")
end

-- return real time in seconds
function engine.realtime()
  error("functions_engine: no implemention specified")
end

function engine.saveUserPrefs(table)
  error("functions_engine: no implemention specified")
end

function engine.loadUserPref(key)
  error("functions_engine: no implemention specified")
end

function engine.getCStringFromFile(path)
  error("functions_engine: no implemention specified")
end

function engine.getStringFromFile(path)
  error("functions_engine: no implemention specified")
end

function engine.getStringFromFileIter(path)
  error("functions_engine: no implemention specified")
end

function engine.getCStringFromZipFile(path)
  error("functions_engine: no implemention specified")
end

function engine.getWritablePath()
  error("functions_engine: no implemention specified")
end

function engine.isFileExistsInRawPath(path)
  error("functions_engine: no implemention specified")
end

function engine.getDataFromRawPath(path)
  error("functions_engine: no implemention specified")
end

function engine.isFileExistsInPackage(path)
  error("functions_engine: no implemention specified")
end

function engine.fullPathForFilename(file)
  error("functions_engine: no implemention specified")
end

function engine.copyFile(srcfile, dstfile)
  error("functions_engine: no implemention specified")
end

function engine.deleteFile(file)
  error("functions_engine: no implemention specified")
end

function engine.beginSample(label)
  -- override me
end

function engine.endSample()
  -- override me
end

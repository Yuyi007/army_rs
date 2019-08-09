local skynet = require "skynet"

local debug = (skynet.getenv("debug") == "true")
if not debug then return end

skynet.cache.mode("OFF")
local mode = skynet.cache.mode()
--print("[reloaded]using code cache mode:"..tostring(mode))

local lfs = require "lfs"

local changedFiles = {}
local scanned = 0
local scansPerCall = 10
local timeTable = {}
local scriptFolder = skynet.getenv("script_root")
local hco = nil


local function reloadFile(path)
  --cache.clear()
  local i = string.find(path, "/[^/]*$")
  if not i then return end
  local fileName = string.sub(path, i+1, -1)
  print("[reloaded]"..fileName)
  if not fileName then return end
  if string.sub(fileName, -4, -1) ~= '.lua' then return end

  local rel = fileName:sub(1, -5)
  package.loaded[rel] = nil
  dofile(path)
end

local function reloadChangedFiles()
  if hco and coroutine.status(hco) ~= "death" then
    local success, msg = coroutine.resume(hco)
    if not success and msg then
      print("[reloaded]Code reload error, failed msg:" .. tostring(msg))
    end
  end

  local path = table.remove(changedFiles)
  local count, max = 1, 99
  while path do
    print("[reloaded]Lua file reload :" .. path)

    reloadFile(path)
    path = table.remove(changedFiles)
    count = count + 1
    if count > max then
      print("[reloaded]Code reload too much files! count:" .. (#changedFiles))
    end
  end
end

local function scanChangedFile(root, timeTable)
  for path in lfs.dir(root) do
    if string.sub(path, 1, 1) ~= "." then
      local name = string.format("%s/%s", root, path)
      local mode = lfs.attributes(name, "mode")
      if mode == "directory" then
        local changedFile = scanChangedFile(name, timeTable)
        if changedFile then
          table.insert(changedFiles, changedFile)
        end
      elseif mode == "file" then
        if string.sub(name, -4) == ".lua" then
          local modifyTime = lfs.attributes(name, 'modification')
          local modifyTime0 = timeTable[name]
          timeTable[name] = modifyTime
          if modifyTime0 and modifyTime0 < modifyTime then
            table.insert(changedFiles, name)
          end
        end
      end

      scanned = scanned + 1
      if scanned % scansPerCall == 0 then
        coroutine.yield()
      end
    end
  end
end

-- Scheduler.scheduleWithUpdate(2, function()
--     reloadChangedFiles()
--   end) 

-- hco = coroutine.create(function()
--     while true do 
--       scanChangedFile(scriptFolder, timeTable)
--     end
--   end)
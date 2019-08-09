-- ObbLocalUpdater.lua
-- Local update file from GGPlay OBB file when UpdateManager checking update

require 'lboot/update/ObbHelper'

class('ObbLocalUpdater', function (self, options)
  self.metafiles = {}
  self.files = {}
  self.info = {
    sizeDone = 0,
    sizeTotal = 0,
  }
  self.failed = {}

  -- 选项
  self.options = table.merge({
  }, options)

  self.inited = false
end)

function ObbLocalUpdater:init(onComplete)
  if not self.inited then
    -- check existence of expansion files
    ObbHelper.getExpansionFiles(function (msg)
      if msg.main or msg.patch then
        self:initObbMeta(msg.main, msg.patch, onComplete)
      else
        logd('no obb files found, skipping')
        onComplete()
      end
    end)

    self.inited = true
  end
end

function ObbLocalUpdater:initObbMeta(mainfile, patchfile, onComplete)
  require 'lboot/update/UpdateManager'

  local obbpath = UpdateManager.rootpath()
  local obbmetafile = obbpath .. '/meta_obb.json'
  mkpath(obbpath)

  ObbHelper.uncompressOneFile('meta.json', obbmetafile, function (msg)
    if msg.success == true then
      local status, err = pcall(function ()
        local content = engine.getCStringFromFile(obbmetafile)
        self.metafiles = cjson.decode(content).files
      end)
      if not status then logd('decode meta_obb.json failed: ' .. tostring(err)) end
    else
      -- if failed, fallback and not read meta
    end
    onComplete()
  end)
end

function ObbLocalUpdater:checkFile(file, dstfile, fileInfo)
  if self.metafiles and self.metafiles[file] and
    self.metafiles[file].hash == fileInfo.hash and
    self.metafiles[file].size == fileInfo.size then
    self.files[file] = { fileInfo=fileInfo, dstfile=dstfile }
    -- self.info.sizeTotal = self.info.sizeTotal + fileInfo.size
    return true
  end

  return false
end

function ObbLocalUpdater:runUpdates(verifier, onProgress, onComplete)
  local files = table.keys(self.files)
  local filesStr = table.concat(files, "\n")

  self.failed = {}

  onProgress(self.info, loc('str_extracting_update_content'))

  -- rely on the java code for file integrity check
  ObbHelper.uncompressFiles(UpdateManager.rootpath(), filesStr,
    function (msg)
      self.info.sizeDone = msg.cur
      self.info.sizeTotal = msg.total
      onProgress(self.info, '_extracting')
    end,
    function (msg)
      if msg.success then
        if type(msg.failed) == 'string' then
          for file in string.gmatch(msg.failed, "[^\n]+") do
            if file and string.len(file) > 0 then
              self.failed[file] = self.files[file]
            end
          end
        end
      else
        -- none succeeded
        logd('uncompressFiles all failed')
        self.failed = self.files
      end
      onComplete(self.files, self.failed)
    end)
end
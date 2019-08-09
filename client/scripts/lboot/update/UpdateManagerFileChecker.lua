-- UpdateManagerFileChecker.lua

--------------------------------------------
-- UpdateManager Sub Module: File Checker
-- check if a file needs to be updated
--------------------------------------------

class('UpdateManagerFileChecker', function (self, rootpath, info, verifier, delegate, options)
  self.rootpath = rootpath
  self.info = info
  self.verifier = verifier
  self.delegate = delegate
  self.options = table.merge({}, options)
end)

function UpdateManagerFileChecker:checkFile(file, fileInfo, suppressLogs)
  if file ~= 'meta.json' and file ~= 'VERSION' then
    local result = self:prepareUpdateFile(file, fileInfo, suppressLogs)
    if result == 'checksum1' or result == 'checksum2' or
      result == 'newfile' or result == 'nohash' then
      -- the file should be updated
      return true
    end
  end

  return false
end

function UpdateManagerFileChecker:prepareUpdateFile(file, fileInfo, suppressLogs)
  local path, exist = prepareFile(self.rootpath .. '/' .. file)
  local logdebug = logd
  if suppressLogs then logdebug = function () end end

  if path then
    if self:shouldExcludeFile(file, fileInfo) then
      logd('excluded: ' .. file)
      self.info.excluded = self.info.excluded + 1
      return 'excluded'
    elseif fileInfo.hash then
      local existInPackage = engine.isFileExistsInPackage(file)

      if exist then
        -- compute checksum of previously downloaded file
        if self.verifier:verifyFile(path, file, fileInfo) then
          logdebug('verified: ' .. file)
          self.info.verified = self.info.verified + 1
          return 'verified1'
        else
          if existInPackage and self.verifier:verifyFile(file, file, fileInfo) and
              pcall(function ()
                local ok, err = os.remove(path)
                if ok then
                  if self.verifier and type(self.verifier.onFileChanged) == 'function' then
                    self.verifier:onFileChanged(path, file)
                  end
                else
                  logd('removing ' .. path .. ' failed: ' .. tostring(err))
                end
              end) then
            logd('use in-package (downloaded removed): ' .. file)
            return 'package2'
          elseif self:checkLocalFile(file, path, fileInfo) then
            logd('local: ' .. file)
            self.info.localUpdated = self.info.localUpdated + 1
            return 'local'
          else
            -- checksum not correct, download anyway
            logd('to download (checksum incorrect): ' .. file)
            return 'checksum2'
          end
        end
      else
        -- compute checksum of in-package file

        if existInPackage then
          if self.verifier:verifyFile(file, file, fileInfo) then
            self.info.package = self.info.package + 1
            return 'package'
          elseif self:checkLocalFile(file, path, fileInfo) then
            logd('local: ' .. file)
            self.info.localUpdated = self.info.localUpdated + 1
            return 'local'
          else
            logd('to download (package checksum incorrect): ' .. file)
            return 'checksum2'
          end
        elseif self:checkLocalFile(file, path, fileInfo) then
          logd('local: ' .. file)
          self.info.localUpdated = self.info.localUpdated + 1
          return 'local'
        else
          -- the in-package file does not exist
          logd('to download (new file): ' .. file)
          return 'newfile'
        end
      end
    else
      logd('to download (no hash): ' .. file)
      return 'nohash'
    end
  end

  self.delegate:onUpdateError(loc('str_lua_9'))
end

function UpdateManagerFileChecker:shouldExcludeFile(file, fileInfo)
  return (fileInfo.tags and self.options.excludesTagPattern and
    string.find(fileInfo.tags, self.options.excludesTagPattern))
end

function UpdateManagerFileChecker:checkLocalFile(file, path, fileInfo)
  if self.options.localUpdater and
    self.options.localUpdater:checkFile(file, path, fileInfo) then
    return true
  else
    return false
  end
end

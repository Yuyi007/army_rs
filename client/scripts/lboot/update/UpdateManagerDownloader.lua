-- UpdateManagerDownloader.lua

local handler = dispatch.newhandler('coroutine')
local http = require 'lboot/net/socket/http'
local ltn12 = require("lboot/net/socket/ltn12")

---------------------------------------------------------------
-- UpdateManager Sub Module: Downloader with local updater
-- updates from local resource packs before downloading online
-- forwards downloading to other downloaders
---------------------------------------------------------------

class('DownloaderWithLocalUpdater', function (self, files, info, downloader, localUpdater, verifier, onLocalProgress)
  self.files = files
  self.info = info
  self.downloader = downloader
  self.localUpdater = localUpdater
  self.verifier = verifier
  self.onLocalProgress = onLocalProgress or (function() end)

  delegateTo(self, self.downloader)
end)

function DownloaderWithLocalUpdater:start()
  self:runLocalUpdates(self.onLocalProgress, function ()
    self.downloader:start()
  end)
end

function DownloaderWithLocalUpdater:runLocalUpdates(onProgress, onComplete)
  logd('runLocalUpdates: ')
  if self.localUpdater then
    self.localUpdater:runUpdates(self.verifier, onProgress, function (files, failed)
      if self.verifier and type(self.verifier.onFileChanged) == 'function' then
        for file, value in pairs(files) do
          self.verifier:onFileChanged(value.dstfile, file)
        end
      end
      local addedBack = 0
      for file, value in pairs(failed) do
        logd('adding back failed file: ' .. tostring(file))
        if not self.files[file] then
          self.files[file] = value
          self.info.sizeTotal = self.info.sizeTotal + value.fileInfo.size
          self.info.total = self.info.total + 1
          addedBack = addedBack + 1
        end
      end
      logd('after local updates: addedBack=' .. addedBack .. ' total=' .. self.info.total)
      onComplete()
    end)
  else
    logd('no local updater found')
    onComplete()
  end
end

----------------------------------------------------------
-- UpdateManager Sub Module: Downloader using lua socket
----------------------------------------------------------

class('LuaSocketDownloader', function (self, rootpath, baseUrl, files, info, verifier, delegate, options)
  self.rootpath = rootpath
  self.baseUrl = baseUrl
  self.files = files
  self.info = info
  self.verifier = verifier
  self.delegate = delegate
  self.fail_http = 0
  self.paused = false
  self.stopped = false
  self.options = table.merge({
    globalScheduler = false,
  }, options)
end)

function LuaSocketDownloader:start()
  local runHandle
  local fails = 0
  local now = 0
  local checkTime = 0
  local measureTime = 0
  local measureSize = 0
  local sizeDone = 0
  local sizeProgress = 0
  local filesToDownload = {}
  local filesDownloading = {}

  for file, value in pairs(self.files) do
    table.insert(filesToDownload, { file=file, value=value })
  end

  local updateFiles = function ()
    local i = 1
    while i <= #filesToDownload do
      local v = filesToDownload[i]
      local file, value = v.file, v.value
      local fileInfo = value.fileInfo

      if self.info.downloading >= self.options.concurrentDownloads then
        break
      end

      if fails < 100 or now - checkTime > 3 then
        checkTime = now
        -- start downloading this file
        self.info.downloading = self.info.downloading + 1
        table.insert(filesDownloading, table.remove(filesToDownload, i))
        value.tcp = handler.tcp()
        handler:start(function ()
          local r, c, h, path = self:downloadFile(file, value.dstfile, fileInfo, value.tcp)
          if r and c == 200 then
            if (self.verifier and
              self.verifier:verifyDownloadedFile(path, file, fileInfo)) or
              fileInfo == nil or fileInfo.hash == nil then
              logd('download success: ' .. file)
              self.info.downloaded = self.info.downloaded + 1
              if fileInfo then
                sizeDone = sizeDone + fileInfo.size
              end
              value.finished = true
            else
              logd('failed when downloading (checksum incorrect): ' .. file)
              fails = fails + 1
              table.insert(filesToDownload, table.removeVal(filesDownloading, v))
              self.delegate:onUpdateError(loc('str_loading_error_content'))
            end
          else
            logd('failed when downloading: ' .. file)
            fails = fails + 1
            self.fail_http = self.fail_http + 1
            table.insert(filesToDownload, table.removeVal(filesDownloading, v))
            self.delegate:onUpdateError(loc('str_loading_error_content'))
          end
          self.info.downloading = self.info.downloading - 1
          value.tcp = nil
        end)
      else
        i = i + 1
      end
    end

    sizeProgress = 0
    for i = 1, #filesDownloading do local v = filesDownloading[i]
      if v.value.tcp then
        sizeProgress = sizeProgress + v.value.tcp.getstats()
      end
    end
  end

  local updateProgress = function ()
    self.info.sizeDone = sizeDone + sizeProgress
    self.info.duration = math.max(now - self.info.startTime, 1)

    local spanTime = now - measureTime
    if spanTime > 1 then
      -- calculate download speed
      local spanSize = self.info.sizeDone - measureSize
      self.info.speed = math.max(0, math.round(spanSize / 1024.0 / spanTime, 2))
      measureSize = self.info.sizeDone
      measureTime = now
    end
    self.delegate:onUpdateProgress('_downloading')
  end

  local run = function ()
    if self.stopped then
      scheduler.unschedule(runHandle)
      logd('LuaSocketDownloader stopped')
    elseif self.paused then
      self.delegate:onUpdateProgress(loc('update paused'))
    elseif self.info.downloaded < self.info.total then
      now = os.time()
      updateFiles()
      updateProgress()
      handler:step()
    else
      scheduler.unschedule(runHandle)
      self.delegate:onUpdateComplete(loc('str_lua_8'))
      logd('LuaSocketDownloader run finish')
    end
  end

  runHandle = scheduler.schedule(run, 0, false, self.options.globalScheduler)
end

function LuaSocketDownloader:downloadFile(file, dstfile, fileInfo, tcp)
  local url = self.baseUrl .. '/' .. file
  local path = dstfile or (self.rootpath .. '/' .. file)
  local r, c, h
  local resolve_first = self.fail_http > 0 and true or false
  local sink = ltn12.sink.file
  if fileInfo and fileInfo.compress == 'gz' then
    sink = ltn12.sink.gzfile
    url = url .. '.gz'
  end

  logd('downloading: %s dst=%s', url, path)
  -- logd('fileInfo=%s', peek(fileInfo))

  r, c, h = http.request {
    url=url, method='GET', headers={['Cache-Control']='no-cache'}, tcp=tcp,
    sink = sink(io.open(path, 'wb+')),
    resolve_first=resolve_first,
  }

  return r, c, h, path
end

function LuaSocketDownloader:pause()
  self.paused = true
end

function LuaSocketDownloader:resume()
  self.paused = false
end

function LuaSocketDownloader:stop()
  self.stopped = true
end

function LuaSocketDownloader:isStopped()
  return self.stopped
end

----------------------------------------------------------
-- UpdateManager Sub Module: Native Downloader
----------------------------------------------------------

class('NativeDownloader', function (self, rootpath, baseUrl, files, info, verifier, delegate, options)
  self.rootpath = rootpath
  self.baseUrl = baseUrl
  self.files = files
  self.info = info
  self.verifier = verifier
  self.delegate = delegate
  self.options = options
  self.paused = false
  self.stopped = false
  self.measureTime = os.time()
  self.measureSize = 0
end)

function NativeDownloader:start()
  self.filesToDownload = {}
  self.filesDownloading = {}

  for file, value in pairs(self.files) do
    table.insert(self.filesToDownload, {
      file=file, fileInfo=value.fileInfo, dstfile=value.dstfile
    })
  end

  self:tryNextFiles()
end

function NativeDownloader:tryNextFiles()
  if #self.filesToDownload > 0 then
    local i = 1
    while i <= #self.filesToDownload do
      if self.stopped then
        logd('NativeDownloader stopped')
        self.delegate:onUpdateProgress(loc('update stopped'))
        self.filesToDownload = {}
        return
      elseif self.paused then
        self.delegate:onUpdateProgress(loc('update paused'))
        return
      elseif self.info.downloading >= self.options.concurrentDownloads then
        return
      else
        self.info.downloading = self.info.downloading + 1
        local value = table.remove(self.filesToDownload, i)
        table.insert(self.filesDownloading, value)
        self:tryFile(value.file, value.dstfile, value.fileInfo, function (fileSize)
          self.info.sizeDone = self.info.sizeDone + fileSize
          self.info.downloaded = self.info.downloaded + 1
          self.info.downloading = self.info.downloading - 1
          table.removeVal(self.filesDownloading, value)
          self:tryNextFiles()
        end)
      end
    end
  else
    self.delegate:onUpdateComplete(loc('str_lua_8'))
  end
end

function NativeDownloader:tryFile(file, dstfile, fileInfo, onComplete)
  local dstfile = dstfile or (self.rootpath .. '/' .. file)
  local fileSize = 0
  if fileInfo then fileSize = fileInfo.size end

  local function onProgress(bytesDownloaded)
    local now = os.time()
    local spanTime = now - self.measureTime

    if spanTime > 1 then
      local sizeProgress = 0
      for i = 1, #self.filesDownloading do local v = self.filesDownloading[i]
        if v.file == file then v.bytesDownloaded = bytesDownloaded end
        sizeProgress = sizeProgress + tonumber(v.bytesDownloaded)
      end
      self.info.duration = math.max(now - self.info.startTime, 1)

      -- calculate download speed
      local sizeDone = self.info.sizeDone + sizeProgress
      local spanSize = sizeDone - self.measureSize
      self.info.speed = math.max(0, math.round(spanSize / 1024.0 / spanTime, 2))
      self.measureSize = sizeDone
      self.measureTime = now
    end

    self.delegate:onUpdateProgress('_downloading')
  end

  local function onComplete2(success)
    if success then
      if (self.verifier and
        self.verifier:verifyDownloadedFile(dstfile, file, fileInfo)) or
        fileInfo == nil or fileInfo.hash == nil then
        logd('download success: ' .. file)
        onComplete(fileSize)
      else
        logd('failed when downloading (checksum incorrect): ' .. file)
        self.delegate:onUpdateError(loc('str_loading_error_content'))
        self:downloadFile(file, dstfile, fileInfo, onProgress, onComplete2)
      end
    else
      logd('failed when downloading: ' .. file)
      self.delegate:onUpdateError(loc('str_loading_error_content'))
      self:downloadFile(file, dstfile, fileInfo, onProgress, onComplete2)
    end
  end

  self:downloadFile(file, dstfile, onProgress, onComplete2)
end

function NativeDownloader:downloadFile(file, dstfile, fileInfo, onProgress, onComplete)
  local url = self.baseUrl .. '/' .. file

  logd('downloading: ' .. url)

  if fileInfo and fileInfo.compress == 'gz' then
    error(string.format('NativeDownloader: compressed file %s not supported!', url))
  else
    OsCommon.asyncDownload(url, dstfile, onProgress, onComplete)
  end
end

function NativeDownloader:pause()
  self.paused = true
end

function NativeDownloader:resume()
  self.paused = false
  self:tryNextFiles()
end

function NativeDownloader:stop()
  self.stopped = true
end

function NativeDownloader:isStopped()
  return self.stopped
end

----------------------------------------------------------
-- UpdateManager Sub Module: Native Batch Downloader
----------------------------------------------------------

class('NativeBatchDownloader', function (self, rootpath, baseUrl, files, info, verifier, delegate, options)
  self.rootpath = rootpath
  self.baseUrl = baseUrl
  self.files = files
  self.info = info
  self.verifier = verifier
  self.delegate = delegate
  self.options = options
  self.stopped = false
end)

function NativeBatchDownloader:start()
  local filesArray = {}
  local fileurls = {}
  local filepaths = {}
  local compresses = {}
  local hashes = {}
  local hasher = self.verifier and self.verifier.hashVerifier.hasher or ''
  local seed = self.verifier and self.verifier.hashVerifier.seed or ''
  local measureTime = os.time()
  local measureSize = 0

  for file, value in pairs(self.files) do
    local filepath = value.dstfile or (self.rootpath .. '/' .. file)
    local filehash = ''
    local compress = 'none'
    if value.fileInfo then
      filehash = value.fileInfo.hash
      compress = value.fileInfo.compress or 'none'
    end
    table.insert(filesArray, file)
    table.insert(fileurls, self.baseUrl .. '/' .. file)
    table.insert(filepaths, filepath)
    table.insert(compresses, compress)
    table.insert(hashes, filehash)
  end

  local function onProgress(bytesDownloaded)
    local now = os.time()
    local spanTime = now - measureTime
    self.info.sizeDone = bytesDownloaded

    if spanTime > 0 then
      -- calculate download speed
      local spanSize = self.info.sizeDone - measureSize
      self.info.duration = math.max(now - self.info.startTime, 1)
      self.info.speed = math.max(0, math.round(spanSize / 1024.0 / spanTime, 2))
      measureSize = self.info.sizeDone
      measureTime = now
    end

    self.delegate:onUpdateProgress('_downloading')
  end

  local function onError(index)
    self.delegate:onUpdateError(loc('str_loading_error_content'))
  end

  local function onFileComplete(success, index)
    if success then
      local file = filesArray[index]
      if file then
        self.info.downloaded = self.info.downloaded + 1
        if self.verifier and type(self.verifier.onFileChanged) == 'function' then
          local value = self.files[file]
          if value and value.fileInfo then
            self.verifier:onFileChanged(value.dstfile, file, value.fileInfo.hash)
          end
        end
      else
        logd('onFileComplete error: index=' .. tostring(index))
      end
    end
  end

  local function onComplete(success)
    if success then
      if self.info.downloaded == self.info.total then
        self.delegate:onUpdateComplete(loc('str_lua_8'))
      else
        self.delegate:onUpdateError('update failed: not all downloaded')
        logd('downloaded=' .. tostring(self.info.downloaded) ..
          ' total=' .. tostring(self.info.total))
      end
    else
      self.delegate:onUpdateError('update failed')
    end
  end
  logd(">>>async down load files:%s", inspect(fileurls))
  OsCommon.asyncDownloadFiles(fileurls, filepaths, compresses,
    hashes, hasher, seed, self.options.concurrentDownloads,
    onProgress, onError, onFileComplete, onComplete)
end

function NativeBatchDownloader:pause()
  OsCommon.pauseAsyncDownloadFiles(true)
end

function NativeBatchDownloader:resume()
  OsCommon.pauseAsyncDownloadFiles(false)
end

function NativeBatchDownloader:stop()
  self.stopped = true
  OsCommon.cancelAsyncDownloadFiles()
end

function NativeBatchDownloader:isStopped()
  return self.stopped
end

-- UpdateManager.lua

require 'lboot/update/UpdateManagerFileChecker'
require 'lboot/update/UpdateManagerVerifier'
require 'lboot/update/UpdateManagerDownloader'
require 'lboot/update/UpdateManagerDelegate'

require 'lboot/net/socket/dispatch'
dispatch.TIMEOUT = 15
local http = require 'lboot/net/socket/http'

local _umId = 0
local function _localOnUpdateStart(instance)
  if um and um ~= instance then
    logd('_localOnUpdateStart: stop previous um')
    pcall(function () um:stop() end)
  end
  logd('um[%s]: start, class is %s', tostring(instance.id), tostring(um.class.classname))
  um = instance
end
local function _localOnUpdateComplete(instance)
  if um and um ~= instance then
    logd('_localOnUpdateComplete: stop previous um')
    pcall(function () um:stop() end)
  end
  logd('um[%s]: complete, class is %s', tostring(instance.id), tostring(um.class.classname))
  um = {}
end

local _umDownloader = LuaSocketDownloader
local _umFileChecker = UpdateManagerFileChecker
local _umVerifier = CachedHashVerifier

---

class('UpdateManagerInfo', function (self)
  self:reset()
end)

function UpdateManagerInfo:reset()
  self.firstUpdate = false    -- 是否第一次更新
  self.startTime = os.time()  -- 开始时间
  self.duration = 0           -- 持续时间
  self.speed = 0              -- 平均下载速度
  self.total = 0              -- 总文件个数
  self.package = 0            -- 位于安装包内不用更新的文件个数
  self.localUpdated = 0       -- 位于本地更新包内需解压缩的文件个数
  self.verified = 0           -- 验证不用更新的文件个数
  self.excluded = 0           -- 不需更新的文件个数
  self.downloaded = 0         -- 从网络下载的文件个数
  self.downloading = 0        -- 当前正在下载的文件个数
  self.sizeDone = 0           -- 当前完成大小
  self.sizeTotal = 0          -- 总文件大小
end

function UpdateManagerInfo:isDownloadComplete()
  return (self.downloaded == self.total)
end

---

class('UpdateManagerBase', function (self)
end)

function UpdateManagerBase:downloadMeta(metapath, onComplete)
  local ok, err = pcall(function() self:downloadMetaGZ(metapath, onComplete) end)
  if not ok then
    logd('download meta gzip failed, msg is ' .. tostring(err))
    self:downloadMetaJson(metapath, onComplete)
  end
end

function UpdateManagerBase:downloadMetaGZ(metapath, onComplete)
  local gzpath = metapath .. '.gz'
  prepareFile(metapath)
  prepareFile(gzpath)

  local files = { ['meta.gz']={ dstfile=gzpath } }
  local info = UpdateManagerInfo.new()
  info.total = 1

  local delegate = BasicUpdateManagerDelegate.new(info, self.onLocalProgress, self.onLocalError,
    function (info, msg) -- onComplete
      local content = engine.getCStringFromZipFile(gzpath)
      if content then
        io.writefile(metapath, content)
        onComplete(content)
      else
        self.delegate:onUpdateError(loc('str_loading_error_no_file'))
        scheduler.performWithDelay(5.0, function ()
          self:downloadMetaGZ(metapath, onComplete)
        end, true)
      end
    end)

  _umDownloader.new(nil, self.baseUrl, files,
    info, nil, delegate, self.options):start()
end

function UpdateManagerBase:downloadMetaJson(metapath, onComplete)
  prepareFile(metapath)

  local files = { ['meta.json']={ dstfile=metapath } }
  local info = UpdateManagerInfo.new()
  info.total = 1

  local delegate = BasicUpdateManagerDelegate.new(info, self.onLocalProgress, self.onLocalError,
    function (info, msg) -- onComplete
      local content = engine.getCStringFromFile(metapath)
      if content then
        onComplete(content)
      else
        self.delegate:onUpdateError(loc('str_loading_error_no_file'))
        scheduler.performWithDelay(5.0, function ()
          self:downloadMetaJson()
        end, true)
      end
    end)

  _umDownloader.new(nil, self.baseUrl, files,
    info, nil, delegate, self.options):start()
end

function UpdateManagerBase:isDownloaded(...)
  if self.meta and self.fileChecker then
    local arg = {...}
    for i = 1, #arg do local file = arg[i]
      local fileInfo = self.meta.files[file]
      if fileInfo then
        if self.fileChecker:checkFile(file, fileInfo, true) then
          return false
        end
      else
        return false
      end
    end
    return true
  else
    return false
  end
end

function UpdateManagerBase:isStopped()
  if self.downloader then
    return self.downloader:isStopped()
  else
    return true
  end
end

function UpdateManagerBase:stop()
  logd('um[%s]: stop', self.id)
  self.delegate:onUpdateInterrupted()
  if self.downloader then self.downloader:stop() end
end

function UpdateManagerBase:pause()
  logd('um[%s]: pause', self.id)
  self.delegate:onUpdateInterrupted()
  if self.downloader then self.downloader:pause() end
end

function UpdateManagerBase:resume()
  logd('um[%s]: resume', self.id)
  if self.downloader then self.downloader:resume() end
end

function UpdateManagerBase:onEnterBackground()
  logd('um[%s]: onEnterBackground', self.id)
  -- self:pause()
  self:stop()
end

function UpdateManagerBase:onEnterForeground()
  logd('um[%s]: onEnterForeground', self.id)
  -- self:resume()
end

---

class('UpdateManager', function (self, version, baseUrl, onProgress, onError, onComplete, options)
  _umId = _umId + 1
  self.id = _umId
  self.baseUrl = baseUrl -- 下载更新url
  self.version = version -- 更新至版本号
  self.files = {}        -- 游戏文件列表
  self.info = UpdateManagerInfo.new() -- info to pass to callbacks
  self.delegate = UpdateManagerDelegate.new(self, onProgress, onError, function (info, msg)
    _localOnUpdateComplete(self)
    onComplete(info, msg)
  end)
  self.delegate = DelegateWithComponents.new(self.delegate) -- callbacks

  -- 选项
  self.options = table.merge({
    skipUpdate = false,      -- 直接跳过更新
    skipVersion = nil,       -- 跳过某一版本的更新，并且以后不再更新该版本
    allowStart = nil,        -- 在开始更新时调用的函数，如果返回false则不开始更新
    localUpdater = nil,      -- 提供从本地更新文件的能力
    alwaysDownloadMeta = false, -- 总是下载meta.json，调试用
    promptOnUpdate = true,   -- 是否在更新时弹框提示
    concurrentDownloads = 2, -- 同时下载文件个数
    excludesTagPattern = nil, -- 不需下载的文件的tag pattern
  }, options)

  self.onLocalProgress = onProgress
  self.onLocalError = onError
end, UpdateManagerBase)

function UpdateManager.rootpath()
  local path = '/zszz/01'
  return engine.getWritablePath() .. path
end

function UpdateManager.rootFolder()
  return '/zszz/01'
end

function UpdateManager.metapath()
  return UpdateManager.rootpath() .. '/meta00.json'
end

function UpdateManager.setDownloader(downloader)
  _umDownloader = downloader
end

-- clear update records (force to check update again)
function UpdateManager.clearUpdateRecords()
  engine.saveUserPrefs({
    ['app.lastUpdate'] = '',
    ['app.version.' .. tostring(game.pkgVersion)] = '',
    ['app.version'] = ''
  })

  CachedHashVerifier.clearCache()
end

-- clear all local updates so that original package contents can be used as runtime
function UpdateManager.clearUpdates()
  UpdateManager.clearUpdateRecords()

  local res, msg = rmpath(UpdateManager.rootpath())
  if res == true then
    logd('um[%s]: all previous in-app updates successfully cleared', _umId)
  else
    logd('um[%s]: clearing previous in-app updates failed: ' .. tostring(msg), _umId)
  end

  return res
end

function UpdateManager.getClientVersion()
  local version = engine.loadUserPref(
    'app.version.' .. tostring(game.pkgVersion))

  if version == nil then
    version = ''
  end

  return version
end

function UpdateManager.verifyFiles()
  local metapath = UpdateManager.metapath()
  local meta = cjson.decode(engine.getCStringFromFile(metapath))
  local info = UpdateManagerInfo.new()
  local verifier = _umVerifier.new(meta.hasher, meta.seed)
  local fileChecker = _umFileChecker.new(UpdateManager.rootpath(), info, verifier)

  local files = {}
  for file, fileInfo in pairs(meta.files) do
    if fileChecker:checkFile(file, fileInfo) then
      table.insert(files, file)
    end
  end

  for i = 1, #files do local file = files[i]
    logd('broken: ' .. tostring(file))
  end
  logd("total inconsistent files: " .. tostring(#files))
end

-- start update
function UpdateManager:start()
  logd('um[%s]: start', self.id)
  _localOnUpdateStart(self)

  local currentVersion = UpdateManager.getClientVersion()

  if currentVersion and string.len(currentVersion) > 0 then
    self.info.firstUpdate = false
  else
    self.info.firstUpdate = true
  end

  logd('start update: firstUpdate=' .. tostring(self.info.firstUpdate) ..
    ' currentVersion=' .. tostring(currentVersion) ..
    ' need to update to version=' .. tostring(self.version))

  if self.options.skipUpdate then
    self.delegate:onUpdateSkip(loc('str_lua_0'))
  elseif self.version == currentVersion then
    self.delegate:onUpdateSkip(loc('str_lua_1'))
  elseif self.version == self.options.skipVersion then
    self.delegate:onUpdateComplete(loc('str_lua_0'))
  else
    self.delegate:onUpdateProgress(loc('str_loading_update_list'))
    self:downloadMeta(self.metapath(), function (content)
      self:runWithMeta(content)
    end)
  end
end

function UpdateManager:runWithMeta(content)
  local msg = cjson.decode(content)
  self.files = {}
  self.info:reset()

  self.verifier = _umVerifier.new(msg.hasher, msg.seed)
  self.delegate.verifier = self.verifier
  self.downloader = _umDownloader.new(self.rootpath(), self.baseUrl,
    self.files, self.info, self.verifier, self.delegate, self.options)
  self.downloader = DownloaderWithLocalUpdater.new(self.files, self.info, self.downloader,
      self.options.localUpdater, self.verifier, self.onLocalProgress)
  self.fileChecker = _umFileChecker.new(self.rootpath(),
    self.info, self.verifier, self.delegate, self.options)

  local step = 0
  local totalFiles = 1
  for k, v in pairs(msg.files) do
    totalFiles = totalFiles + 1
  end

  coroutineStart(function (delta)
    for file, fileInfo in pairs(msg.files) do
      if self.fileChecker:checkFile(file, fileInfo) then
        self.info.sizeTotal = self.info.sizeTotal + fileInfo.size
        self.files[file] = { fileInfo=fileInfo, finished=false }
      end

      step = step + 1
      if step % 25 == 0 then
        self.delegate:onUpdateProgress(loc('str_lua_3') ..
          tostring(math.round(step * 100.0 / totalFiles)) .. '%')
        coroutine.yield()
      end
    end

    self.info.total = table.nums(self.files)
    logd('um[%s]: meta received' ..
      ' local=' .. tostring(self.info.localUpdated) ..
      ' download=' .. tostring(self.info.total) ..
      ' downloadSize=' .. tostring(self.info.sizeTotal) ..
      ' total=' .. tostring(totalFiles), self.id)

    if self.info.total > 0 and self.info.sizeTotal > 0 then
      if self.options.promptOnUpdate then
        local totalMB = math.round(self.info.sizeTotal / 1024.0 / 1024, 3)
        OsCommon.showMessageBox{
          title = loc('str_lua_4'),
          message = loc('str_lua_5') .. tostring(self.info.total) ..
                    loc('str_lua_6') .. tostring(totalMB) .. 'MB！',
          button = loc('str_lua_7'),
          onComplete = function () self:startUpdateFiles() end,
        }
      else
        self:startUpdateFiles()
      end
    elseif self.info.localUpdated > 0 then
      self:startUpdateFiles()
    else
      self.delegate:onUpdateComplete(loc('str_lua_8'))
    end
  end)
end

function UpdateManager:startUpdateFiles()
  if self.options.allowStart then
    if not self.options.allowStart() then
      logd('startUpdateFiles: skip because allowStart is false!')
      return
    end
  end

  scheduler.performWithDelay(0, function ()
    self.delegate:onUpdateProgress(loc('str_loading_files'))
    self.downloader:start()
  end, true)
end

-------------------------------------------------------------
-- Resource Update Manager
-- used for updating game resources after entering the game
-------------------------------------------------------------

class('ResourceUpdateManager', function (self, fileList, tagPattern, onProgress, onError, onComplete, options)
  _umId = _umId + 1
  self.id = _umId
  self.fileList = fileList or {}
  self.tagPattern = tagPattern
  self.baseUrl = game.updateBaseUrl
  self.info = UpdateManagerInfo.new()
  self:initDelegate(onProgress, onError, onComplete)

  self.options = table.merge({
    concurrentDownloads = 4,
    globalScheduler = true,
  }, options)
end, UpdateManagerBase)

function ResourceUpdateManager:initDelegate(onProgress, onError, onComplete)
  if not self.delegate then
    self.delegate = BasicUpdateManagerDelegate.new(self.info, onProgress, onError, function (info, msg)
      -- _localOnUpdateComplete(self)
      onComplete(info, msg)
    end)
    self.delegate = DelegateWithComponents.new(self.delegate)
  else
    self.delegate:setCallbacks(onProgress, onError, onComplete)
  end
end

function ResourceUpdateManager:start()
  logd('um[%s]: start', self.id)
  _localOnUpdateStart(self)

  if table.getn(self.fileList) == 0 and not self.tagPattern then
    self.delegate:onUpdateComplete('no files specified')
    return
  end

  self:initMeta(function ()
    self.info:reset()
    self:checkFiles()

    if self.info.total > 0 then
      self.downloader = _umDownloader.new(UpdateManager.rootpath(), self.baseUrl,
          self.files, self.info, self.verifier, self.delegate, self.options)
      self.downloader = DownloaderWithLocalUpdater.new(self.files, self.info, self.downloader,
        self.options.localUpdater, self.verifier, nil)

      self.downloader:start()
    else
      self.delegate:onUpdateComplete('no files to be downloaded')
    end
  end)
end

function ResourceUpdateManager:initMeta(onComplete)
  local metapath = UpdateManager.metapath()

  local function openMeta(content)
    self.meta = cjson.decode(content)
    onComplete()
  end

  if engine.isFileExistsInRawPath(metapath) then
    local content = engine.getDataFromRawPath(metapath)
    openMeta(content)
  else
    self:downloadMeta(metapath, function (content)
      openMeta(content)
    end)
  end
end

function ResourceUpdateManager:checkFiles()
  self.files = {}

  self.verifier = _umVerifier.new(self.meta.hasher, self.meta.seed)
  self.delegate.verifier = self.verifier

  self.fileChecker = _umFileChecker.new(UpdateManager.rootpath(),
    self.info, self.verifier, self.delegate, self.options)

  if self.fileList then
    -- add files in the file list
    for _, file in ipairs(self.fileList) do
      local fileInfo = self.meta.files[file]
      if fileInfo then
        self:checkFile(file, fileInfo)
      else
        logd('um[%s]: ignoring ' .. tostring(file) .. ': can\'t find it in meta.json', self.id)
      end
    end
  end

  if self.tagPattern then
    -- add files whose tags matching pattern
    for file, fileInfo in pairs(self.meta.files) do
      if fileInfo.tags and string.find(fileInfo.tags, self.tagPattern) then
        self:checkFile(file, fileInfo)
      end
    end
  end
end

function ResourceUpdateManager:checkFile(file, fileInfo)
  if self.fileChecker:checkFile(file, fileInfo) then
    self.info.sizeTotal = self.info.sizeTotal + fileInfo.size
    self.info.total = self.info.total + 1
    self.files[file] = { fileInfo=fileInfo, finished=false }
  end
end

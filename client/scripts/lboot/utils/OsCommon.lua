-- OsCommon.lua

class('OsCommon')

local luaj = require('lboot/lib/luaj')
local luaoc = require('lboot/lib/luaoc')
local luacs = require('lboot/lib/luacs')

local OCLASS_IOS_UTILS = 'IOSUtils'
local JCLASS_ANDROID_UTILS = 'com/yousi/lib/AndroidUtils'
local JCLASS_NOTIFICATION = 'net/agasper/unitynotification/UnityNotificationManager'
local OSUtils = LBoot.OSUtils

function OsCommon.showMessageBox(options)
  local title = options.title
  local message = options.message
  local button = options.button
  local onComplete = options.onComplete or (function () end)
  local cancelable = options.cancelable or false -- valid only for android

  if game.platform == 'ios' then
    local ok, ret = luaoc.callStaticMethod(OCLASS_IOS_UTILS, 'showMessageBox', {
      title = title,
      message = message,
      button = button,
      onComplete = onComplete,
      })
  elseif game.platform == 'android' then
    luaj.callStaticMethod(JCLASS_ANDROID_UTILS, 'showMessageBox', {
      title,      -- title
      message,    -- message
      button,     -- ok
      onComplete, -- onComplete
      cancelable, -- cancelable
    })
  elseif game.platform == 'wp8' then
    Wp8Utils:sharedWp8Utils():promptOK(
      title,
      message,
      cancelable,
      onComplete
    )
  elseif game.platform == 'editor' then
    logd('showMessageBox not implemented in editor, calling onComplete')
    onComplete()
  else
    logd('showMessageBox not implemented')
  end
end

function OsCommon.showDialog(options)
  local title = options.title
  local message = options.message
  local buttonOk = options.buttonOk
  local buttonCancel = options.buttonCancel
  local onOk = options.onOk or (function () end)
  local onCancel = options.onCancel or (function () end)
  local cancelable = options.cancelable or false -- for android only

  if game.platform == 'ios' then
    local ok, ret
    ok, ret = luaoc.callStaticMethod(OCLASS_IOS_UTILS, 'showDialog', {
      title = title,
      message = message,
      button = button,
      buttonOk = buttonOk,
      onComplete = function (res)
        logd('dialog closed: ' ..
          ' confirm index=' .. tostring(ret.index) ..
          ' res.action=' .. tostring(res.action) ..
          ' res.buttonIndex=' .. tostring(res.buttonIndex))
        if res.buttonIndex == ret.index then
          onOk()
        else
          onCancel()
        end
      end,
      })
  elseif game.platform == 'android' then
    luaj.callStaticMethod(JCLASS_ANDROID_UTILS, 'showDialog', {
      title,         -- title
      message,       -- message
      buttonOk,      -- ok
      buttonCancel,  -- cancel
      onOk,          -- onOk
      onCancel,      -- onCancel
      cancelable,    -- cancelable
    })
  elseif game.platform == 'wp8' then
    Wp8Utils:sharedWp8Utils():promptYESNO(
      title,
      message,
      cancelable,
      onOk,
      onCancel
    )
  elseif game.platform == 'editor' then
    logd('showDialog not implemented in editor, calling onOk')
    onOk()
  else
    logd('showDialog not implemented')
  end
end

function OsCommon.isInternetConnectionAvailable()
  if game.platform == 'ios' then
    local ok, ret = luaoc.callStaticMethod(OCLASS_IOS_UTILS,
      'isInternetConnectionAvailable', {})
    return ret.ret
  elseif game.platform == 'android' then
    local ok, ret = luaj.callStaticMethod(JCLASS_ANDROID_UTILS,
      'isInternetConnectionAvailable', {}, '()Z')
    return ret
  elseif game.platform == 'wp8' then
    return CCWp8Network:isInternetConnectionAvailable()
  elseif game.platform == 'editor' then
    logd('isInternetConnectionAvailable not implemented in editor, returning true')
    return true
  else
    logd('isInternetConnectionAvailable: not implemented')
  end
end


function OsCommon.setSignalLevel(level, mc)
  if level == 3 then
    mc:setColor(ColorUtil.green)
  elseif level == 2 then
    mc:setColor(ColorUtil.yellow)
  else
    mc:setColor(ColorUtil.red)
  end

end
function OsCommon.isLocalWifiAvailable()
  if game.platform == 'ios' then
    local ok, ret = luaoc.callStaticMethod(OCLASS_IOS_UTILS,
      'isLocalWifiAvailable', {})
    return ret.ret
  elseif game.platform == 'android' then
    local ok, ret = luaj.callStaticMethod(JCLASS_ANDROID_UTILS,
      'isLocalWifiAvailable', {}, '()Z')
    return ret
  elseif game.platform == 'wp8' then
    return CCWp8Network:isLocalWifiAvailable()
  elseif game.platform == 'editor' then
    --logd('isLocalWifiAvailable not implemented in editor, returning true')
    return true
  else
    logd('isLocalWifiAvailable: not implemented')
  end
end

function OsCommon.downloadFile(options)
  local url = options.url
  local filename = options.filename
  local title = options.title or ''
  local desc = options.desc or ''
  local onRequestSuccess = options.onRequestSuccess

  if game.platform == 'android' then
    local ok, ret = luaj.callStaticMethod(JCLASS_ANDROID_UTILS, 'downloadFile', {
      url, -- url
      filename, -- filename
      title,  -- title
      desc, -- description
      onRequestSuccess, -- onRequestSuccess
    })
  else
    logd('downloadFile: not implemented')
  end
end

function OsCommon.getDeviceId()
  if game.platform == 'ios' then
    local ok, ret = luaoc.callStaticMethod(OCLASS_IOS_UTILS,
      'getDeviceId', {})
    return ret.deviceId
  elseif game.platform == 'android' then
    local ok, deviceId = luaj.callStaticMethod(JCLASS_ANDROID_UTILS,
      'getDeviceId', {}, '()Ljava/lang/String;')
    return deviceId
  elseif game.platform == 'editor' then
    logd('getDeviceId not implemented in editor, returning empty string')
    return ''
  end
end

function OsCommon.getDeviceModel()
  if game.platform == 'ios' then
    local ok, ret = luaoc.callStaticMethod(OCLASS_IOS_UTILS,
      'getDeviceModel', {})
    local result = ret.ret
    return result
  elseif game.platform == 'android' then
    local ok, ret = luaj.callStaticMethod(JCLASS_ANDROID_UTILS,
      'getDeviceModel', {}, '()Ljava/lang/String;')
    return ret
  elseif game.platform == 'editor' then
    logd('getDeviceModel not implemented in editor, returning "unity"')
    return 'unity'
  end
end

local function getPackageId()
  if game.platform == 'ios' then
    local ok, ret = luaoc.callStaticMethod(OCLASS_IOS_UTILS,
      'getBundleId', {})
    local result = ret.ret
    return result
  elseif game.platform == 'android' then
    local ok, ret = luaj.callStaticMethod(JCLASS_ANDROID_UTILS,
      'getPackageName', {}, '()Ljava/lang/String;')
    return ret
  elseif game.platform == 'editor' then
    logd('getPackageId not implemented in editor, returning "unity"')
    return 'unity'
  else
    logd('getPackageId: not implemented')
    return ''
  end
end

local function getPackageVersion()
  if game.platform == 'ios' then
    local ok, ret = luaoc.callStaticMethod(OCLASS_IOS_UTILS,
      'getBundleVersion', {})
    local result = ret.ret
    logd('ok='..tostring(ok)..', ret='..result)
    return result
  elseif game.platform == 'android' then
    local ok, ret = luaj.callStaticMethod(JCLASS_ANDROID_UTILS,
      'getVersionName', {}, '()Ljava/lang/String;')
    logd('ok='..tostring(ok)..', ret='..ret)
    return ret
  elseif game.platform == 'editor' then
    logd('getPackageVersion not implemented in editor, returning "unity"')
    return 'unity'
  else
    logd('getPackageVersion: not implemented')
  end
end

function OsCommon.getVersionCode()
  if game.platform == 'android' then
    local ok, ret = luaj.callStaticMethod(JCLASS_ANDROID_UTILS,
      'getVersionCode', {}, '()Ljava/lang/String;')
    logd('ok='..tostring(ok)..', ret='..ret)
    return ret
  else
    logd('getVersionCode: not implemented')
  end
end

function OsCommon.getTimezoneName()
  if game.platform == 'ios' then
    local ok, ret = luaoc.callStaticMethod(OCLASS_IOS_UTILS,
      'getTimezoneName', {})
    return ret.ret
  elseif game.platform == 'android' then
    local ok, timezoneName = luaj.callStaticMethod(JCLASS_ANDROID_UTILS,
      'getTimezoneName', {}, '()Ljava/lang/String;')
    logd('timezoneName...'..timezoneName)
    return timezoneName
  elseif game.platform == 'editor' then
    logd('getTimezoneName not implemented in editor, returning "UTC+8"')
    return 'UTC+8'
  end
end

function OsCommon.showWebView(url, onComplete)
  keepConnectionBegin()

  if game.platform == 'ios' then
    local ok, ret = luaoc.callStaticMethod(OCLASS_IOS_UTILS,
      'showWebView', {
        url = url,
        callback = function(msg)
          if msg and msg.jsonResult then
            local json = cjson.decode(msg.jsonResult)
            onComplete(json)
          end
        end})
    return 0
  elseif game.platform == 'android' then
    local ok, ret = luaj.callStaticMethod(JCLASS_ANDROID_UTILS, 'showWebView', {
      url,
      function(result)
        local msg = cjson.decode(result)
        onComplete(msg)
      end
      })
  elseif game.platform == 'wp8' then
    local ok, ret = luacs.callStaticMethod('MainPage', 'showWebView', {
      url = url,
      callback = function(msg)
        logd("show webview onComplete: " .. tostring(msg))
        if msg then
          logd('show webview result: '..tostring(msg))
          local json = cjson.decode(msg)
          onComplete(json)
        end
      end})
  else
    logd('showWebView not implemented in editor')
  end
end

function OsCommon.showLocalHtml(fileName, onComplete)
  keepConnectionBegin()

  if game.platform == 'ios' then
    local ok, ret = luaoc.callStaticMethod(OCLASS_IOS_UTILS,
      'showLocalHtml', {
        url = fileName,
        callback = function(msg)
          if msg and msg.jsonResult then
            local json = cjson.decode(msg.jsonResult)
            onComplete(json)
          end
        end})
    return 0
  elseif game.platform == 'android' then
    local ok, ret = luaj.callStaticMethod(JCLASS_ANDROID_UTILS, 'showLocalHtml', {
      fileName,
      function(result)
        local msg = cjson.decode(result)
        onComplete(msg)
      end
      })
  else
    logd('showLocalHtml not implemented in editor')
  end
end

function OsCommon.asyncDownloadCached(url, filename, onProgress, onComplete)
  local tmpdir = UpdateManager.rootpath() .. '/cached'
  local tmpfile = tmpdir .. '/' .. filename

  local filepath, exists = prepareFile(tmpfile)

  if exists then
    local mtime = lfs.attributes(filepath, 'modification')
    if os.time() - mtime < 3600 * 24 * 7 then
      onComplete(true, filepath)
      return
    end
  end

  asyncDownloadNative(url, filepath, onProgress, function(success)
    onComplete(success, filepath)
  end)
end

-- onComplete = function({success = true/false})
function OsCommon.asyncDownloadFile(url, filename, onProgress1, onComplete1)
  if game.platform == 'ios' then
    local ok, ret = luaoc.callStaticMethod(OCLASS_IOS_UTILS,
      'asyncDownloadFile', {
        url = url,
        filename = filename,
        onProgress = onProgress1,
        onComplete = onComplete1
        })
    return 0
  elseif game.platform == 'android' then
    local ok, ret = luaj.callStaticMethod(JCLASS_ANDROID_UTILS, 'asyncDownloadFile', {
      url,
      filename,
      function(bytesDownloaded)
        onProgress1(tonumber(bytesDownloaded))
      end,
      function(result)
        if result == 'true' then
          onComplete1({success = true})
        else
          onComplete1({success = false})
        end
      end
      })
  elseif game.platform == 'editor' then
    logd('asyncDownloadFile not implemented in editor, calling onComplete')
    onComplete1({success = false})
  else
    logd('asyncDownloadFile is not implemented for platform: '..tostring(game.platform))
  end
end

function OsCommon.asyncDownloadFiles(fileurls, filepaths, compresses,
  hashes, hasher, seed, concurrentDownloads, onProgress1, onError1, onFileComplete1, onComplete1)
  local fileurlString = table.concat(fileurls, "\n")
  local filepathString = table.concat(filepaths, "\n")
  local compressString = table.concat(compresses, "\n")
  local hashString = table.concat(hashes, "\n")

  if game.platform == 'ios' then
    local ok, ret = luaoc.callStaticMethod(OCLASS_IOS_UTILS, 'asyncDownloadFiles', {
      fileurls = fileurlString,
      filepaths = filepathString,
      compresses = compressString,
      hashes = hashString,
      hasher = hasher,
      seed = seed,
      concurrentDownloads = concurrentDownloads,
      onProgress = function (res)
        onProgress1(res.bytesDownloaded)
      end,
      onError = function (res)
        onError1(res.index)
      end,
      onFileComplete = function (res)
        onFileComplete1(true, tonumber(res.index + 1))
      end,
      onComplete = function (res)
        onComplete1(res.success == true)
      end
      })
    return ok
  elseif game.platform == 'android' then
    local ok, ret = luaj.callStaticMethod(JCLASS_ANDROID_UTILS, 'asyncDownloadFiles', {
      fileurlString,
      filepathString,
      compressString,
      hashString,
      hasher,
      seed,
      concurrentDownloads,
      function (bytesDownloaded) -- onProgress
        onProgress1(tonumber(bytesDownloaded))
      end,
      function (index) -- onError
        onError1(tonumber(index) + 1)
      end,
      function (index) -- onFileComplete
        onFileComplete1(true, tonumber(index) + 1)
      end,
      function (result) -- onComplete
        if result == 'true' then
          onComplete1(true)
        else
          onComplete1(false)
        end
      end
      })
    return ok
  elseif game.platform == 'editor' then
    logd('asyncDownloadFile not implemented in editor, calling onComplete')
    onComplete1({success = false})
  else
    logd('asyncDownloadFiles is not implemented for platform: '..tostring(game.platform))
  end
end

function OsCommon.pauseAsyncDownloadFiles(paused)
  if game.platform == 'ios' then
    local ok, ret = luaoc.callStaticMethod(OCLASS_IOS_UTILS,
      'pauseAsyncDownloadFiles', { paused = paused })
    return ok
  elseif game.platform == 'android' then
    local ok, ret = luaj.callStaticMethod(JCLASS_ANDROID_UTILS,
      'pauseAsyncDownloadFiles', { paused })
    return ok
  elseif game.platform == 'editor' then
    logd('pauseAsyncDownloadFiles not implemented in editor')
  else
    logd('OsCommon.pauseAsyncDownloadFiles is not implemented for platform: '..tostring(game.platform))
  end
end

function OsCommon.cancelAsyncDownloadFiles()
  if game.platform == 'ios' then
    local ok, ret = luaoc.callStaticMethod(OCLASS_IOS_UTILS,
      'cancelAsyncDownloadFiles', {})
    return ok
  elseif game.platform == 'android' then
    local ok, ret = luaj.callStaticMethod(JCLASS_ANDROID_UTILS,
      'cancelAsyncDownloadFiles', {})
    return ok
  elseif game.platform == 'editor' then
    logd('cancelAsyncDownloadFiles not implemented in editor')
  else
    logd('OsCommon.cancelAsyncDownloadFiles is not implemented for platform: '..tostring(game.platform))
  end
end

function OsCommon.unpackZip(zipfile, outpath, onProgress, onComplete)
  if game.platform == 'ios' then
    local ok, ret = luaoc.callStaticMethod(OCLASS_IOS_UTILS,
      'unpackZipFile', {
        zipfile = zipfile,
        outpath = outpath,
        onProgress = function (res) onProgress(res.index, res.filename) end,
        onComplete = function (res) onComplete(res.success) end,
      })
    return ok
  elseif game.platform == 'android' then
    local isFromJar = (not string.match(zipfile, '^/'))
    logd('unpackZip: zipfile=%s isFromJar=%s', zipfile, tostring(isFromJar))
    local ok, ret = luaj.callStaticMethod(JCLASS_ANDROID_UTILS,
      'unpackZipFile', {
        zipfile,
        isFromJar,
        outpath,
        function (res)
          res = cjson.decode(res)
          onProgress(res.index, res.filename)
        end,
        function (res)
          res = cjson.decode(res)
          onComplete(res.success)
        end,
      })
    return ok
  else
    logd('OsCommon.unpackZip is not implemented for platform: '..tostring(game.platform))
  end
end

function OsCommon.getSysBatteryLevel()
  if game.platform == 'ios' then
    local ok, ret = luaoc.callStaticMethod(OCLASS_IOS_UTILS,
      'getIOSBatteryLevel', {})
    if ok then
      return ret.ret
    end
    logd('getSysBatteryLevel not found in IOSUtils')
    return 0
  elseif game.platform == 'android' then
    --  not working on Android 7
    -- local ret = FileUtils.GetStringFromFileNoSearching("/sys/class/power_supply/battery/capacity")
    local ret = OSUtils.GetBatteryLevel()
    if ret then
      return tonumber(ret)/100
    else
      return 0
    end
  elseif game.platform == 'editor' then
    --logd('getSysBatteryLevel not implemented in editor')
    return 1.0
  else
    logd('OsCommon.getSysBatteryLevel is not implemented for platform: '..tostring(game.platform))
    return 0
  end
end

function OsCommon.cancelNotification(id)
  local platform = game.platform
  if platform == 'ios' then
    return LBoot.FVAlert.ClearAlerts()
  elseif platform == 'android' then
    -- return LBoot.FVAlert.CancelNotification(id)
    return luaj.callStaticMethod(JCLASS_NOTIFICATION, 'CancelNotificationLua', {
      id,
    })
  else
    logd('OsCommon.cancelNotification is not implemented for %s', platform)
  end
end


function OsCommon.openUrl(url)
  local platform = game.platform
  logd("OsCommon.openUrl is called by: %s<---->%s;", tostring(platform),tostring(url))
  if platform == 'ios' then
    -- logd("ios open url not implemented")
    CCNative:openURL(url)
  elseif platform == 'android' then
    -- return LBoot.FVAlert.CancelNotification(id)
    return luaj.callStaticMethod(JCLASS_ANDROID_UTILS, 'openUrl', {
      url,
    })
  else
    logd('OsCommon.openUrl is not implemented for %s', platform)
  end
end



function OsCommon.setRepeatingNotification(message, title, time, id)
  local platform = game.platform
  if platform == 'ios' then
    return LBoot.FVAlert.ScheduleAlert(message, title, time)
  elseif platform == 'android' then
    -- return LBoot.FVAlert.SendRepeatingNotification(message, title, time, id)
    local bundle = getPackageId()
    local delay = (time - math.floor(stime())) * 1000
    local rep = 60 * 60 * 24 * 1000
    if delay < 0 then
      delay = delay + rep
    end
    -- logd('id=%s bundle=%s delay=%s rep=%s', tostring(id), tostring(bundle), tostring(delay), tostring(rep))
    return luaj.callStaticMethod(JCLASS_NOTIFICATION, 'SetRepeatingNotificationLua', {
      id,
      delay, -- delay in ms
      title, -- title
      message, -- message
      message, -- ticker
      rep, -- repeat in ms
      1, -- sound
      1, -- vibrate
      1, -- lights
      'app_icon', -- large icon
      'notify_icon_small', -- small icon
      0 * 65535 + 0 * 256 + 0, -- bg color rgb
      bundle, -- bundle
    })
  else
    logd('OsCommon.sendRepeatingNotification is not implemented for %s', platform)
  end
end

-- maxTime in milliseconds
function OsCommon.startRecordAudio(outfile, maxTime, onComplete)
  local platform = game.platform
  if platform == 'ios' then
    local ok, ret = luaoc.callStaticMethod(OCLASS_IOS_UTILS, 'startRecordAudio', {
      outfile = outfile,
      encoding = 1, -- always aac+mp4 for platform compatibility
      maxTime = maxTime,
      quality = 0, -- AVAudioQualityMin
      sampleRate = 22050.0,
      channels = 2,
      depth = 8,
      bitRate = 0,
      onComplete = function (res) onComplete(res) end,
    })
    logd('ret=%s', peek(ret))
    return ok
  elseif platform == 'android' then
    return luaj.callStaticMethod(JCLASS_ANDROID_UTILS, 'startRecordAudio', {
      outfile,
      maxTime,
      44100.0, -- sampleRate
      2.0, -- channels
      12800, -- bitRate
      function (res) onComplete(cjson.decode(res)) end,
    })
  else
    logd('OsCommon.startRecordAudio is not implemented for %s', platform)
  end
end

-- set iOS AudioSession to playback mode after recording
function OsCommon.setAudioSessionPlayback()
  local platform = game.platform
  if platform == 'ios' then
    return luaoc.callStaticMethod(OCLASS_IOS_UTILS, 'setAudioSessionPlayback', {
      active = 1,
    })
  end
end

function OsCommon.stopRecordAudio()
  local platform = game.platform
  if platform == 'ios' then
    local ok, ret = luaoc.callStaticMethod(OCLASS_IOS_UTILS, 'stopRecordAudio', {
    })
    OsCommon.setAudioSessionPlayback()
    return ok
  elseif platform == 'android' then
    return luaj.callStaticMethod(JCLASS_ANDROID_UTILS, 'stopRecordAudio', {
    })
  else
    logd('OsCommon.stopRecordAudio is not implemented for %s', platform)
  end
end

function OsCommon.startPlayAudio(infile, volume, onComplete)
  local platform = game.platform
  if platform == 'ios' then
    return luaoc.callStaticMethod(OCLASS_IOS_UTILS, 'startPlayAudio', {
      infile = infile,
      volume = volume,
      onStart = function () end,
      onComplete = function (res) onComplete(res) end,
    })
  elseif platform == 'android' then
    return luaj.callStaticMethod(JCLASS_ANDROID_UTILS, 'startPlayAudio', {
      infile,
      math.max(volume * 50, 50),
      function () end,
      function (res) onComplete(cjson.decode(res)) end,
    })
  else
    logd('OsCommon.startPlayAudio is not implemented for %s', platform)
  end
end

function OsCommon.stopPlayAudio()
  local platform = game.platform
  if platform == 'ios' then
    return luaoc.callStaticMethod(OCLASS_IOS_UTILS, 'stopPlayAudio', {
    })
  elseif platform == 'android' then
    return luaj.callStaticMethod(JCLASS_ANDROID_UTILS, 'stopPlayAudio', {
    })
  else
    logd('OsCommon.stopPlayAudio is not implemented for %s', platform)
  end
end

function OsCommon.exit(keepProcess)
  if game.platform == 'android' then
    if keepProcess then
      luaj.callStaticMethod(JCLASS_ANDROID_UTILS, 'finishActivities', {})
    else
      luaj.callStaticMethod(JCLASS_ANDROID_UTILS, 'exit', {})
    end
  elseif game.platform == 'wp8' then
    Wp8Utils:sharedWp8Utils():promptTerminateApp(
      loc('str_title_exit_wp8'),
      loc('str_desc_exit_wp8')
    )
  else
    logd('OsCommon.exit not implemented for platform: '..tostring(game.platform))
  end
end
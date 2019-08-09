class('AudioRecordUtil')

local m = AudioRecordUtil
local RECORDING_MAX_TIME = 14 * 1000
local DOWNLOADS_KEEP_TIME = 7 * 24 * 3600
local AUDIO_TEXT_HEADER = 0xAD
local MAX_AUDIO_LENGTH = 1024 * 500


function m.createLongPressTracker(node, startFunc, stopFunc, cancelFunc, intervalFunc, beforeStartCheck)
  local tracker = nil
  tracker = LongPressTracker.new({
    rctrans = node.transform,
    triggerTime = 0,
    slideCancelVector = Vector2.new(1000, 180),
    startFunc = function (tracker)
      m.startRecordAudio(tracker)
    end,
    stopFunc = function (tracker)
      OsCommon.stopRecordAudio()
    end,
    cancelFunc = function (tracker)
      if tracker._cancelFunc then tracker._cancelFunc() end
      OsCommon.stopRecordAudio()
    end,
    intervalFunc = intervalFunc,
  })
  tracker._startFunc = startFunc
  tracker._stopFunc = stopFunc
  tracker._cancelFunc = cancelFunc
  tracker.beforeStartCheck = beforeStartCheck
  return tracker
end

function m.updateLongPressTracker(tracker, startFunc, stopFunc, cancelFunc, intervalFunc, beforeStartCheck)
  tracker._startFunc = startFunc
  tracker._stopFunc = stopFunc
  tracker._cancelFunc = cancelFunc
  tracker.intervalFunc = intervalFunc
  tracker.beforeStartCheck = beforeStartCheck
end

function m.clickToPlay(node, text, isAudioId, onAudioStart, onAudioEnd)
  if isAudioId == nil then
    isAudioId = m.isAudioId(text)
  end

  isAudioId = (not not isAudioId)
  local cg = node.gameObject:getComponent(CanvasGroup)
  if cg then
    cg:set_interactable(isAudioId)
    cg:set_blocksRaycasts(isAudioId)
  end

  if isAudioId then
    node:onClick(function ()
      logd('checkPlayAudio: audioId=%s', text)
      m.downloadAndPlay(text, onAudioStart, onAudioEnd)
    end)
  else
    node:unregisterClick()
  end
end

function m.encodeAudioText(data, duration)
  local len = string.len(data)
  local raw = string.pack('b>I>IA', AUDIO_TEXT_HEADER, len, duration, data)
  logd('encodeAudioText: len=%s duration=%s rawlen=%s', len, duration, string.len(raw))
  return raw
end

function m.isAudioText(data)
  local i, header, len, duration = string.unpack(data, 'b>I>I', 1)
  logd('isAudioText: total=%s header=%s duration=%s len=%s',
    string.len(data), tostring(header), tostring(duration), tostring(len))
  if header == AUDIO_TEXT_HEADER and len > 0 then
    local _i, d = string.unpack(data, 'A' .. len, i)
    -- logd('isAudioText: d=%s', d and string.len(d) or '')
    if d and string.len(d) == len then
      return true
    end
  end
  return false
end

function m.isAudioId(text)
  local duration = string.match(text, 'ad:%d+_%d+_i%d:%d+:(%d+)')
  -- logd('isAudioId: text=%s duration=%s', string.len(text), tostring(duration))
  if duration then
    return text, duration
  else
    return false
  end
end

function m.recordPath()
  local path = UpdateManager.rootpath() .. '/record'
  mkpath(path)
  return path
end

function m.downloadPath()
  local path = UpdateManager.rootpath() .. '/audio_download'
  mkpath(path)
  return path
end

function m.extname()
  if game.ios then
    return '.m4a'
  else
    return '.mp4'
  end
end

function m.startRecordAudio(tracker)
  if tracker.beforeStartCheck and (not tracker.beforeStartCheck()) then
    return 
  end
  OsCommon.stopPlayAudio()
  md.isPlayingAudio = false
  local outfile = m.recordPath() .. string.format('/out%s', m.extname())
  local startTime = engine.realtime()

  local ok = OsCommon.startRecordAudio(outfile, RECORDING_MAX_TIME, function (result)
    logd('startRecordAudio: result=%s', peek(result))
    sm:restoreChannelVolumes()
    if result.success then
      local duration = math.ceil(engine.realtime() - startTime)
      local audio = m.stopRecordAudio(tracker, outfile, duration)
      logd('startRecordAudio: success audio=%s _stopFunc=%s', tostring(audio ~= nil), tostring(tracker._stopFunc))
      if tracker.cancelled then
        logd('startRecordAudio: tracker was cancelled')
      else
        if tracker._stopFunc then tracker._stopFunc(audio, duration) end
      end
    else
      loge('startRecordAudio: fail status=%s', tostring(result.status))
      FloatingTextFactory.makeFramed{text=loc('str_record_failed')}
      if tracker._stopFunc then tracker._stopFunc(nil, 0) end
      if result.status == -100 then
        OsCommon.showMessageBox({
          title = loc('str_record_permission_title'),
          message = loc('str_record_permission_msg'),
          button = loc('str_record_permission_btn'),
        })
      end
    end
  end)

  if ok then
    sm:setChannelVolumes(0)
    if tracker._startFunc then tracker._startFunc(nil) end
  else
    FloatingTextFactory.makeFramed{text=loc('str_record_not_supported')}
  end
end

function m.stopRecordAudio(tracker, outfile, duration)
  OsCommon.stopRecordAudio()

  logd('outfile=%s', tostring(outfile))
  if not outfile then return nil end

  if (lfs.attributes(outfile, 'mode') == 'file' and lfs.attributes(outfile, 'size') > 0) then
    local data = io.readfile(outfile)
    if string.len(data) < MAX_AUDIO_LENGTH then
      return m.encodeAudioText(data, duration)
    else
      FloatingTextFactory.makeFramed{text=loc('str_record_too_long')}
    end
  else
    FloatingTextFactory.makeFramed{text=loc('str_record_failed')}
  end

  return nil
end

function m.downloadAndPlay(audioId, onAudioStart, onAudioEnd)
  local downloadPath = m.downloadPath()
  local basename = string.gsub(string.gsub(audioId, 'ad:', ''), ':', '_')
  local filepath = downloadPath .. string.format('/%s%s', basename, m.extname())

  if (lfs.attributes(filepath, 'mode') == 'file' and lfs.attributes(filepath, 'size') > 0) then
    -- logd('has audio file %s', filepath)
    m.startPlayAudio(filepath, onAudioStart, onAudioEnd)
  else
    md:rpcDownloadAudio(audioId, function (result)
      if result.data then
        io.writefile(filepath, result.data, 'wb+')
        -- logd('write audio data %s', string.len(result.data))
        m.startPlayAudio(filepath, onAudioStart, onAudioEnd)
      else
        FloatingTextFactory.makeFramed{text=loc('str_record_play_expired')}
      end
    end)
  end

  m.cleanupDownloadPath(downloadPath)
end

local lastCleanupTime = os.time()

function m.cleanupDownloadPath(path)
  local now = os.time()
  if now - lastCleanupTime < 1800 then
    return
  end

  logd('cleanupDownloadPath')
  lastCleanupTime = now

  for n in lfs.dir(path) do
    -- logd('cleanupDownloadPath n=%s', tostring(n))
    if string.sub(n, 1, 1) ~= '.' then
      local name = path .. '/' .. n
      local mode = lfs.attributes(name, 'mode')
      if mode == 'file' and string.match(n, string.format('%s$', m.extname())) then
        local modtime = lfs.attributes(name, 'modification')
        if now - modtime > DOWNLOADS_KEEP_TIME then
          logd('modtime=%s delete old audio file %s', modtime, name)
          engine.deleteFile(name)
        end
      end
    end
  end
end

function m.startPlayAudio(infile, onAudioStart, onAudioEnd)
  local volume = 1.0
  local ok = OsCommon.startPlayAudio(infile, volume, function (result)
    sm:restoreChannelVolumes()
    if onAudioEnd then
      onAudioEnd()
    end
    if result.success then
      logd('play audio finished')
    else
      loge('play failed! status=%s', tostring(result.status))
      logd('delete audio file %s', infile)
      engine.deleteFile(infile)
      FloatingTextFactory.makeFramed{text=loc('str_record_play_failed')}
    end
  end)

  if ok then
    sm:setChannelVolumes(0)
    if onAudioStart then
      onAudioStart()
    end
  else
    FloatingTextFactory.makeFramed{text=loc('str_record_play_not_supported')}
  end
end

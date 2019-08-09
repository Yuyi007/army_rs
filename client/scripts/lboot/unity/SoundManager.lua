class('SoundManager', function(self)
  self:init()
  self.enableMusic = true
  self.enableSound = true
end)

local AudioSource = UnityEngine.AudioSource
local AudioClip = UnityEngine.AudioClip
local Yield = UnityEngine.Yield
local unity = unity

local m = SoundManager
local MAX_NUM_CHANNELS = 10
local DSP_BUFFER_SIZE = 64 -- 64 fixes the buffer size
local MAX_PLAYER_CHANNELS = 3
local MAX_PLAYING_SOUNDS = 6

local FADE_TIME = 2.0

function m:init()
  self.clips = {}
  self.asyncs = {}
  self.playingClipsHandlers = {}
  self.playingClipsNum = 0
  self.soundLock = {}
  self:initAudioChannels()

  OsCommon.setAudioSessionPlayback()
end

function m:clear()
  unity.beginSample('SoundManager.clear')

  self.soundLock = {}
  self:clearPlayingClips()
  each(function(_, v) v:clear() end, self.asyncs)
  table.clear(self.asyncs)
  self:purgeClips(true)

  unity.endSample()
end

function m:clearPlayingClips()
  for k, v in pairs(self.playingClipsHandlers) do
    scheduler.unschedule(v)
  end
  table.clear(self.playingClipsHandlers)
  self.playingClipsNum = 0
end

function m:purgeClips(unload)
  -- logd('SoundManager: purgeClips destroy=%s', tostring(destroy))
  local clips = self.clips
  for uri, clip in pairs(clips) do
    if unload then
      logd('[SoundManager] unload clip %s', uri)

      if not uri:match('bgm_001') then
        unity.Resources.UnloadAsset(clip)
      end
    end
    clips[uri] = nil
  end
end

function m:playerMaxChannel()
  return MAX_PLAYER_CHANNELS
end

function m:initAudioChannels()
  self.SoundRoot = GameObject.Find('/SoundRoot') or GameObject('SoundRoot')
  GameObject.DontDestroyOnLoad(self.SoundRoot)

  local sources = self.SoundRoot:GetComponents(AudioSource)
  self.channels = {}
  self.oldVolumes = {}

  -- Init 10 AudioSource, the 1st is used for theme music, the rest are for efx sounds
  if not sources or #sources == 0  then
    for i = 1, MAX_NUM_CHANNELS do
      self.channels[i] = self.SoundRoot:AddComponent(AudioSource)
      if i == 1 then unity.decorateAudioSource(self.channels[1]) end
    end
  else
    for i = 1, MAX_NUM_CHANNELS do
      self.channels[i] = sources[i]
    end
  end

  for i = 1, #self.channels do
    local ch = self.channels[i]
    self.oldVolumes[i] = ch:get_volume()
  end
end

function m:findSoundChannel()
  for i = 3, MAX_NUM_CHANNELS do
    local ss = self.channels[i]
    if not_null(ss) and not ss:get_isPlaying() and not self.soundLock[i] then
      self.soundLock[i] = true
      return ss, i
    end
  end

  return self.channels[3], 3
end

function m:findMusicChannel()
  return self.channels[1]
end

function m:findEngineChannel()
  return self.channels[2]
end

function m:setChannelVolumes(volume)
  for i = 1, #self.channels do
    local ch = self.channels[i]
    local vol = ch:get_volume()
    -- self.oldVolumes[i] = vol
    -- logd('setChannelVolumes i=%s old=%s now=%s', i, vol, volume)
    ch:set_volume(volume)
  end
end

function m:restoreChannelVolumes()
  for i = 1, #self.channels do
    local ch = self.channels[i]
    local vol = self.oldVolumes[i]
    -- logd('restoreChannelVolumes i=%s old=%s', i, vol)
    ch:set_volume(vol)
  end
end

function m:getSoundLoader(uri)
  local loader = self.asyncs[uri]
  if not loader then
    loader = CachedAssetLoader.new(uri, self.clips, unity.loadSound, unity.loadSoundAsync)
    self.asyncs[uri] = loader
  end
  return loader
end

function m:getClip(uri)
  uri = uri:lower()
  local loader = self:getSoundLoader(uri)
  return loader:load()
end

function m:getClipAsync(uri, onComplete)
  uri = uri:lower()
  local loader = self:getSoundLoader(uri)
  loader:loadAsync(onComplete)
end

function m:playEngineSound(sound)
  if not sound then return end
  logd("[engine] play engine sound")
  self:getClipAsync('Sounds/'..sound, function(clip)
    if not clip then return end
    local ss = self:findEngineChannel()

    ss:set_clip(clip)
    ss:set_loop(true)
    ss:set_time(0)
    ss:set_pitch(0.5)
    ss:PlayScheduled(0)
  end)
end

function m:setEngineSpeed(speed)
  local pitch = 0.4 + (speed/4000)
  if pitch > 1 then
    pitch = 1
  end
  local ss = self:findEngineChannel()
  ss:set_pitch(pitch)
end

function m:stopEngineSpeed()
  local ss=self:findEngineChannel()
  logd("[engine] stop engine sound")
  ss:set_mute(true)
  ss:set_loop(false)
  ss:set_clip(nil)
end

function m:resumeEngineSound()
  local ss=self:findEngineChannel()
  logd("[engine] resume engine sound")
  ss:set_mute(false)
  ss:set_loop(true)
end

function m:playSound(sound, beginCallback)
  if not sound then return end
  self:playSoundExt({
    sound = sound,
    beginCallback = beginCallback
  })
end

function m:stopSound(audioSource)
  if not_null(audioSource) then
    audioSource:stop()
  end
end

function m:playSoundUri(uri)
  -- logd('playSoundUri: uri=%s trace=%s', tostring(uri), debug.traceback())
  if not uri then return end
  self:getClipAsync(uri, function(clip)
    if not clip then return end
    if is_null(clip) then return end
    local ss, idx = self:findSoundChannel()
    if is_null(ss) then return end
    ss:set_clip(clip)
    ss:set_loop(false)
    ss:Play(0)
    scheduler.performWithDelay(clip.length, function()
      self.soundLock[idx] = false
    end)
  end)
end

function m:playSoundExt(options)
  local sound = options.sound
  local beginCallback = options.beginCallback
  if not sound then return end
  if not self.enableSound and beginCallback == nil then return end
  if sound == '' then return end
  -- logd('playSoundExt: sound=%s trace=%s', tostring(sound), debug.traceback())
  self:getClipAsync('Sounds/'..sound, function(clip)
    -- loge('playSound %s', peek(clip))
    if not clip then return end
    if is_null(clip) then return end
    local ss, idx = self:findSoundChannel()
    if is_null(ss) then return end
    -- logd(">>>> [play] sound ".. sound.." mute "..tostring(ss.mute)..tostring(sm:getEnableSound()).."  "..debug.traceback())
    ss:set_clip(clip)
    ss:set_loop(false)
    ss:Play(0)
    scheduler.performWithDelay(clip.length, function()
      self.soundLock[idx] = false
    end)
    if beginCallback then
      beginCallback(ss)
    end
  end)
end

function m:playSoundWithCallbacks(sound, onBegin, onFinish)
  -- logd('playSoundWithCallbacks: sound=%s trace=%s', tostring(sound), debug.traceback())
  if not sound then return end
  self:playSoundExt({
    sound = sound,
    beginCallback = function(ss)
      local length = ss.clip.length
      onBegin(ss)
      scheduler.performWithDelay(length, onFinish)
    end
  })
end

function m:playMusicAtLogin(music)
  if not music then return end

  self:getClipAsync('Sounds/'..music, function(clip)
    if not clip then return end
    local ss = self:findMusicChannel()
    if ss:get_clip() == clip then return end

    ss:set_clip(clip)
    ss:set_loop(true)
    ss:set_time(0)
    ss:PlayScheduled(0)
  end)
end

-----
-- clipStartTime 这个参数，如果有值，它是指从这段剪辑的某一个时间点开始播放
--
function m:playMusic(music, clipStartTime)
  -- logd('SoundManager playMusic: %s, %s, %s', peek(music), peek(clipStartTime), debug.traceback())
  if not music then return end
  -- logd(">>>> [play] music ".. music.. " mute "..tostring(self:findMusicChannel().mute).."  "..debug.traceback())
  -- logd('playMusic music=%s trace=%s', tostring(music), debug.traceback())
  self:getClipAsync('Sounds/'..music, function(clip)
    if not clip then return end
    local ss = self:findMusicChannel()

    ss:set_clip(clip)
    ss:set_loop(true)
    if clipStartTime then
      ss:set_time(clipStartTime)
    else
      ss:set_time(0)
    end
    ss:PlayScheduled(0)

    ------------------------------------------
    -- if already paused by someone
    -- continue pause until unpaused by someone
    ------------------------------------------
    if self:isSoundStoryPaused() then
      self:onStoryPauseMusic(self.__csPaused)
    end

  end)
end

function m:stopMusic()
  local ss = self:findMusicChannel()
  if not_null(ss) then ss:Stop() end
end

function m:setEnableMusic(hasMusic)
  self.enableMusic = hasMusic
  self:muteMusic(not hasMusic)
end

function m:setEnableSound(hasSound)
  self.enableSound = hasSound
  self:muteSound(not hasSound)
end

function m:getEnableMusic()
  return self.enableMusic
end

function m:getEnableSound()
  return self.enableSound
end

function m:getCurMusicMute()
  return (not self.enableMusic) or self:findMusicChannel().mute or self:isSoundStoryPaused()
end

function m:getCurSoundMute()
  return (not self.enableSound) or self.channels[2].mute or self:isSoundStoryPaused()
end

-- 关闭背景音乐
function m:muteMusic(shouldMute)
  local ss = self:findMusicChannel()
  shouldMute = shouldMute and shouldMute or not self.enableMusic
  ss:set_mute(shouldMute)
  -- logd('[play] muteMusic %s', peek(shouldMute)..debug.traceback())
end

function m:muteSound(shouldMute)
  for i = 2, MAX_NUM_CHANNELS do
    local ss = self.channels[i]
    ss:set_mute(shouldMute)
  end
  local cc = rawget(_G, 'cc')
  if cc and cc.scene then
      self:muteSceneSound(cc.scene, shouldMute)
  end
  -- logd("[play] mute sound "..tostring(shouldMute)..debug.traceback())
end

-- 暂停音乐
function m:pauseMusic()
  -- logd('pauseMusic %s', debug.traceback())
  local ss = self:findMusicChannel()
  if not_null(ss) then ss:Pause() end
end

-- 重新开始播放暂停的音乐
function m:unPauseMusic()
  local ss = self:findMusicChannel()
  if not_null(ss) then ss:UnPause() end
end

--静音 或 按设置 恢复所有音乐(仅限场景音效 背景音 UI声音)
function m:mute(shouldMute, curScene)
  -- logd("[play] should mute %s music enable %s  sound enable %s"..debug.traceback(), tostring(shouldMute), tostring(self.enableMusic), tostring(self.enableSound))
  if shouldMute then
    local ss = self:findMusicChannel()
    self:muteMusic(shouldMute)
    self:muteSound(shouldMute)
    if curScene then
      self:muteSceneSound(curScene, shouldMute)
    end
  else
    self:muteMusic(not self.enableMusic)
    self:muteSound(not self.enableSound)
    if curScene then
      self:muteSceneSound(curScene, not self.enableSound)
    end
  end
end

function m:muteEnvSound(shouldMute, curScene)
  if shouldMute then
    if curScene then
      self:muteSceneSound(curScene, shouldMute)
    end
  else
    if curScene then
      self:muteSceneSound(curScene, not self.enableSound)
    end
  end
  self:muteNpcSound(shouldMute)
end

function m:muteNpcSound(shouldMute)
  self.muteNpcEfx = shouldMute
  md:signal('mute_npc_sound'):fire(shouldMute)
end

function m:muteSceneSound(scene, shouldMute)
  if scene.citySoundList then
    for k, v in pairs (scene.citySoundList) do
      v:mute(shouldMute)
    end
  end
end

function m:initAudioSoucesOnView(view, maxChannels)
  local sources = view.gameObject:GetComponents(AudioSource)
  view.__audioSources = {}
  for asrc in Slua.iter(sources) do
    table.insert(view.__audioSources, asrc)
  end

  maxChannels = maxChannels or 1
  -- local maxChannels = 1
  -- if view.maxChannels then
  --   if type(view.maxChannels) == 'function' then
  --     maxChannels = view:maxChannels()
  --   end
  -- end
  view.__maxChannels = maxChannels

  -- logd('initAudioChannels a %s, %s', #view.__audioSources, maxChannels)
  while #view.__audioSources < maxChannels do
    -- logd('initAudioChannels b %s, %s', #view.__audioSources, maxChannels)
    local asrc = view.gameObject:AddComponent(AudioSource)
    self:set3DAudioSource(asrc)
    table.insert(view.__audioSources, asrc)
  end
end

function m:set3DAudioSource(asrc)
  asrc:set_loop(false)
  asrc:set_rolloffMode(1)
  asrc:set_maxDistance(300)
  asrc:set_minDistance(15)
  asrc:set_panStereo(0)
  asrc:set_dopplerLevel(0)
  asrc:set_spatialize(true)
  asrc:set_spatialBlend(1)
end

function m:playSoundOnView(view, options)
  local sound = options.sound
  local beginCallback = options.beginCallback
   -- logd("<<<< sounds on view")
  if not sound then return end
  -- if self.playingClipsNum >= MAX_PLAYING_SOUNDS then
  --   -- logd('playSoundOnView failed num:%s', self.playingClipsNum)
  --   return
  -- end

  if not view.__audioSources then
    -- loge('view %s has no __audioSources', view.classname)
    self:initAudioSoucesOnView(view,2)
    -- return
  end

  view.__curASIndex = view.__curASIndex or 0
  if view.__curASIndex >= view.__maxChannels then
    loge('playSoundOnView failed num:%s', view.__curASIndex)
    return
  end

  if not self.enableSound and beginCallback == nil then
    return 
  end
  -- logd('playSoundOnView: sound=%s trace=%s', tostring(sound), debug.traceback())
  self:getClipAsync('Sounds/'..sound, function(clip)

    local maxChannels = view.__maxChannels or 1
    if options.last then
      view.__curASIndex =  maxChannels - 1
    end

    if not clip then return end

    local as = view.__audioSources[view.__curASIndex + 1]
    -- logd("<<<< sound enable :%s",sm:getEnableSound())
    as:set_mute(not sm:getEnableSound())
    as:set_clip(clip)
    -- as:set_loop(false)
    -- logd("<<<< play")
    as:Play(0)
    if beginCallback then
      beginCallback(as)
    end

    -- view.__curASIndex = (view.__curASIndex + 1) % maxChannels

    local handler = {}
    -- logd("<<<< clip length:%s",clip.length)
    handler.handler = scheduler.performWithDelay(clip.length, function()
      table.removeVal(self.playingClipsHandlers, handler.handler)
      -- self.playingClipsNum = self.playingClipsNum - 1
      view.__curASIndex = view.__curASIndex - 1
    end)
    table.insert(self.playingClipsHandlers, handler.handler)
    view.__curASIndex = view.__curASIndex + 1
  end)
end



function m:onStoryPauseMusic(callerName)
  -- logd('SoundManager onStoryPauseMusic %s %s %s', peek(self.__csPaused), peek(callerName), debug.traceback())
  self.__csPaused = callerName
  sm:pauseMusic()
  sm:muteEnvSound(true, cc.scene)
end

function m:onStoryUnpauseMusic(callerName)
  -- logd('SoundManager onStoryUnpauseMusic %s %s %s', peek(self.__csPaused), peek(callerName), debug.traceback())
  if self.__csPaused ~= callerName then
    return
  end
  self.__csPaused = nil
  sm:unPauseMusic()
  sm:muteEnvSound(false, cc.scene)
end

function m:isSoundStoryPaused()
  return not not self.__csPaused
end

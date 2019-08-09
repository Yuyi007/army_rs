


View3D('ParticleView', nil, function(self, go, options)
  self.options = table.merge({}, options)

  self.fvprShaderChanged = false

  if go then
    self:bind(go)
  end
end)

local m = ParticleView

m.totalCount = 0
m.liveCount = 0

local ParticleSystem         = UnityEngine.ParticleSystem
local Animator               = UnityEngine.Animator
local ParticleSystemRenderer = UnityEngine.ParticleSystemRenderer
local Collider               = UnityEngine.Collider
local ParticleStorable       = Game.ParticleStorable
local FVParticleRoot         = LBoot.FVParticleRoot
local FVParticleScaling      = LBoot.FVParticleScaling
local MeshRenderer           = UnityEngine.MeshRenderer
local Renderer               = UnityEngine.Renderer
local unity                  = unity
local layer                  = unity.layer('ParticleEffect')

local emptyMatArray = {}
local emptyArray = {}

local EMPTY_INFO = {
  has_animator = true,
}

function m.destroyAll()
  m.totalCount = 0
  m.liveCount = 0

  if m.durationCache then
    table.clear(m.durationCache)
  end
end

function m:init()
  local go = self.gameObject

  local refBundle = uoc:getAttr(go, 'bundleFile')

  if refBundle then
    self.particleInfo = cfg.particles_duration[refBundle] or EMPTY_INFO
  else
    self.particleInfo = EMPTY_INFO
  end

  self.particles = go:getComponentsInChildren(ParticleSystem)

  -- only get the components of the Animator if it really has any valid animator (with controllers) on it
  if self.particleInfo.has_animator then
    self.animators = go:getComponentsInChildren(Animator)
  else
    self.animators = emptyArray
  end

  self.fvpr              = go:getComponent(FVParticleRoot)
  self.particleStorable  = go:getComponent(ParticleStorable)

  if self.fvpr then
    unity.decorateFVParticleRoot(self.fvpr)
    self.initialRotation = self.fvpr:get_Rotation()[3]
    self.initialScale = self.fvpr:get_Scale()[3]
  end

  self.initialLoops = {}
  local particles = self.particles
  for i = 1, #particles do
    self.initialLoops[i] = particles[i].loop
  end

  m.totalCount = m.totalCount + 1
end

function m:exit()
  self:_reopenExit()


  if m.totalCount > 0 then
    m.totalCount = m.totalCount - 1
  end

  self.particles = nil
  self.animators = nil
  self.fvpr = nil
  self.particleStorable = nil

  if self.audio then
    self.audio:stop()
    self.audio = nil
  end

  if self.filter then
    self.filter:set_sharedMesh(nil)
    self.filter = nil
  end

  self.particleInfo = nil

end

function m:reopenInit()

  self.forceHidden = false

  m.liveCount = m.liveCount + 1

  self.elapsed = 0
  self.timeScale = 1

  if self.options.disableSounds == nil then
    self.options.disableSounds = (not sm:getEnableSound())
  end

  local cc = rawget(_G, 'cc')
  if cc and not cc.isCombat and self.fvpr then

    self.fvpr:setEnable(false, self.fvprShaderChanged)
    self.fvprShaderChanged = true
  end

  local go = self.gameObject
  self:initGameObject(go)
  self:initScale()
  self:initRotation()
  self:initLoop()
  self:setVisibleCheck(self.options.visibleCheck)

  local duration = m.getCachedDuration(go)
  if not duration then
    self:calcDuration()
    m.setCachedDuration(go, self.duration)
  else
    self.duration = duration
  end

  self:pause()
  self:show()
end

function m:reopenExit()
  -- logd('[%s] ParticleView.reopenExit self=%s', tostring(self.gameObject), tostring(self))

  m.liveCount = m.liveCount - 1

  self:_reopenExit()
end

function m:_reopenExit()
  if self.audio then
    self.audio:stop()
  end

  if self.follower then
    self.follower:reopenExit()
    self.follower = nil
  end

  self.destroyCb = nil
  self.loopOnceCb = nil
  self.duration = nil

  local options = self.options
  for k, v in pairs(options) do
    options[k] = nil
  end

  self:reset()
  self:hide()
end

function m:initGameObject(go)
  local customCache = uoc:getCustomAttrCache(go)
  -- logd('go=%s customCache=%s', tostring(go), peek(customCache))

  local qsettings = QualityUtil.cachedQualitySettings()
  local isRenderToTexture = not not qsettings.enableHighQuality
  local distortionEnabled = isRenderToTexture

  if customCache.distortionEnabled ~= distortionEnabled then
    local particleRenderers = go:getComponentsInChildren(ParticleSystemRenderer)

    for i = 1, #particleRenderers do local pr = particleRenderers[i]
      local material = pr:get_sharedMaterial()
      if material and material:get_shader():get_name() == 'Custom/Mobile/Particles/DistortionScalable' then
        pr:get_gameObject():setVisible(distortionEnabled)
      end
    end

    customCache.distortionEnabled = distortionEnabled
  end

  if not customCache.layerFixed then
    self:setLayerOpt(self:getLayer(), true)
    customCache.layerFixed = true
  end
end

function m:getLayer()
  return layer
end

function m.setCachedDuration(go, duration)
  local uri = uoc:getAttr(go, 'bundleFile')
  m.durationCache = m.durationCache or {}
  if uri then
    m.durationCache[uri] = duration
  end
end

function m.getCachedDuration(go)
  local uri = uoc:getAttr(go, 'bundleFile')
  m.durationCache = m.durationCache or {}
  if uri then
    return m.durationCache[uri]
  else
    return nil
  end
end

function m:setTimeScale(val)
  if val then
    self.timeScale = self.duration / val
    -- logd('setTimeScale: val=%s duration=%s timeScale=%s', val, self.duration, self.timeScale)
  end
end

function m:setVisibleCheck(val)
  self.options.visibleCheck = val

  if val then
    local go = self.gameObject
    local renderer = go:addComponent(UnityEngine.MeshRenderer)
    optimizeRenderer(renderer, emptyMatArray)
    go:addComponent(LBoot.LuaVisibleBehaviour)
    self.transform = go:get_transform()
    self.seen = false
    self:setEnabled(false)

    local tmgo = gp:getPrefab('prefab/model/trigger_mesh')
    local mesh = tmgo:getComponent(UnityEngine.MeshFilter)
    local filter = go:addComponent(UnityEngine.MeshFilter)
    filter:set_sharedMesh(mesh:get_sharedMesh())
    self.filter = filter
  else
    self.seen = true
  end
end

-- only rotates along z axis
function m:setRotation(rot)
  self.options.rotation = rot
  self:initRotation()
end

-- only rotates along z axis
function m:initRotation()
  local fvpr = self.fvpr
  local rotation = self.options.rotation or self.initialRotation
  if fvpr then
    fvpr:set_Rotation(Vector3(0, 0, rotation))
  end
end

function m:setScale(scale)
  self.options.scale = scale
  self:initScale()
end

function m:initScale()
  local fvpr = self.fvpr
  local scale = self.options.scale or self.initialScale

  -- logd('ParticleView setScale %s, %s, %s', peek(scale), self.gameObject.name, debug.traceback())

  if fvpr and scale then
    fvpr:setFVScale(Vector3(scale, scale, scale))
  end
end

function m:initLoop()
  local particles = self.particles
  for i = 1, #particles do
    particles[i].loop = self.initialLoops[i]
  end
end

function m:setEfxType(efxType)
  self.options.efxType = efxType
end

function m:setDisableSounds(disableSounds)
  -- logd("ParticleView setDisableSounds %s %s ", tostring(disableSounds), debug.traceback())
  self.options.disableSounds = disableSounds
end

function m:setAutoDestroy(val)
  self.options.autoDestroy = val
end

function m:setProcessAfterLoopOnce(val)
  self.options.processAfterLoopOnce = val
end

function m:setDestroyCb(val)
  self.destroyCb = val
end

function m:setLoopOnceCb(cb)
  self.loopOnceCb = cb
end

function m:setLoop(val)
  local particles = self.particles
  for i = 1, #particles do
    particles[i]:set_loop(val)
  end
end

function m:muteSound(shouldMute)
  if self.audio then
    self.audio:set_mute(shouldMute)
  end
end

function m:initPlayAudio()
  local efxType = self.options.efxType
  if efxType then
    local sound, loop = efxType.sound, efxType.loop
    if not sound then return end

    sound = table.random(sound)

    if loop then
      if self.audio then return end
      self.audio = self.gameObject:addComponent(unity.AudioSource)
      sm:set3DAudioSource(self.audio)
      if not self.options.disableSounds then
        -- logd('ParticleView.initPlayAudio: 1 go=%s trace=%s',
        --   tostring(self.gameObject), debug.traceback())
        self.audio:playSound(sound, (not not loop))
      end
    else
      if not self.options.disableSounds then
        -- logd('ParticleView.initPlayAudio: 2 go=%s trace=%s',
        --   tostring(self.gameObject), debug.traceback())
        sm:playSound(sound)
      end
    end
  end
end

function m:playSound()
  if self.audio then
    if not self.options.disableSounds then
      -- logd('ParticleView.play: go=%s trace=%s', tostring(self.gameObject), debug.traceback())
      self.audio:Play(0)
    end
  end
end

function m:setFollower(follower, needUpdateFollower)
  self.follower = follower
  if needUpdateFollower then
    self:updateFollower(0.01)
  end
end

function m:updateFollower(deltaTime)
  unity.beginSample('ParticleView.updateFollower')

  local follower = self.follower
  if follower then
    -- logd('[%s] updateFollower class=%s', tostring(self.gameObject), tostring(follower.class.classname))
    follower:update(deltaTime)
  end

  unity.endSample()
end

function m:setEnabled(enable)
  if self.forceHidden then
    enable = false
  end

  local particles = self.particles
  local animators = self.animators
  -- local particleScalings = self.particleScalings

  if particles then
    for i = 1, #particles do
      particles[i]:get_gameObject():setVisible(enable)
    end
  end

  if animators then
    for i = 1, #animators do
      animators[i]:set_enabled(enable)
    end
  end

  -- if particleScalings then
  --   for i = 1, #particleScalings do
  --     particleScalings[i]:set_enabled(enable)
  --   end
  -- end
end

function m:reset()
  self.elapsed = 0

  local particles = self.particles
  local animators = self.animators

  for i = 1, #particles do
    particles[i]:Simulate(0, false, true)
  end
  for i = 1, #animators do
    animators[i]:set_enabled(false)
    animators[i]:Update(0)
  end
end

function m:restart()
  self:reset()
  self:play()
end

function m:pause()
  local particles = self.particles
  local animators = self.animators

  if particles then
    for i = 1, #particles do
      particles[i]:Pause()
    end
  end

  if animators then
    for i = 1, #animators do
      animators[i]:set_enabled(false)
    end
  end
end

function m:stop()
  local particles = self.particles
  local animators = self.animators

  if particles then
    for i = 1, #particles do
      particles[i]:Stop()
    end
  end

  if animators then
    for i = 1, #animators do
      animators[i]:set_enabled(false)
    end
  end
end

function m:play()
  if self.destroyed then return end
  if not self.seen then end

  self:initPlayAudio()

  local particles = self.particles
  local animators = self.animators

  for i = 1, #particles do
    particles[i]:Play()
  end
  for i = 1, #animators do
    animators[i]:set_enabled(true)
  end

  local options = self.options

  if options.autoDestroy then
    local duration = self.duration - self.elapsed
    if duration < 0 then duration = 0 end
    self:performWithDelay(duration, function()
      if self.destroyCb then self.destroyCb(self) end
      self:destroy()
    end)
  elseif options.processAfterLoopOnce then
    local duration = self.duration - self.elapsed
    if duration < 0 then duration = 0 end
    self:performWithDelay(duration, function()
      if self.loopOnceCb then self.loopOnceCb(self) end
    end)
  end
end

function m:update(deltaTime)
  unity.beginSample('ParticleView.update')

  -- logd('[%s] update deltaTime=%s destroyed=%s hidden=%s', tostring(self.gameObject),
  --   deltaTime, tostring(self.destroyed), tostring(self.hidden))

  if self.destroyed then
    unity.endSample()
    return
  end
  if self.hidden then
    unity.endSample()
    return
  end

  deltaTime = deltaTime * self.timeScale
  self.elapsed = self.elapsed + deltaTime
  -- logd('[%s] update elapsed=%s', tostring(self.gameObject), self.elapsed)

  local particles = self.particles
  local animators = self.animators
  for i = 1, #particles do
    particles[i]:Simulate(deltaTime, false, false)
  end
  for i = 1, #animators do
    animators[i]:Update(deltaTime)
  end

  self:updateFollower(deltaTime)

  unity.endSample()
end

function m:calcDuration()
  local duration = nil

  local durationCfg = self.particleInfo
  if durationCfg then
    if durationCfg.stored_duration then
      self.duration = durationCfg.stored_duration
      return
    else
      duration = durationCfg.system_duration
    end
  end

  if not duration then
    local particleStorable = self.particleStorable
    if particleStorable and particleStorable:get_duration() > 0 then
      self.duration = particleStorable:get_duration()
      return
    end
  end

  local particles = self.particles
  local animators = self.animators

  -- only iterate through particles if the duration config has not been found
  if not duration then
    duration = 0

    for i = 1, #particles do
      local p = particles[i]
      local dur = p:get_duration()
      if dur > duration then duration = dur end
    end
  end

  for i = 1, #animators do
    local a = animators[i]
    local state = a:GetCurrentAnimatorStateInfo(0)
    local len = state:get_length()
    if len > duration then duration = len end
  end

  self.duration = duration
end

function m:show()
  if self.forceHidden then
    return
  end
  -- logd('%s show %s', self.gameObject.name, debug.traceback())

  self.hidden = false
  self:setVisible(true)
end

function m:hide()
  -- logd('%s hide %s', self.gameObject.name, debug.traceback())

  self:unscheduleAll()
  self.hidden = true
  self:setVisible(false)
  self.loopOnceCb = nil
end

function m:setForceHide(val)
  self.forceHidden = val
  if val then
    self:setEnabled(false)
  end
end

function m:OnBecameVisible()
  unity.beginSample('ParticleView.OnBecameVisible')
  -- logd('[%s] OnBecameVisible', tostring(self.gameObject))

  self.seen = true
  self:setEnabled(true)
  self:play()

  unity.endSample()
end

function m:OnBecameInvisible()
  unity.beginSample('ParticleView.OnBecameInvisible')
  -- logd('[%s] OnBecameInvisible', tostring(self.gameObject))

  self.seen = false
  self:setEnabled(false)
  self:pause()

  unity.endSample()
end

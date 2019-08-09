class('ParticleFactory', function (self)
end)

local m = ParticleFactory
local QualityUtil = QualityUtil
local ParticleView = ParticleView

m.debug = nil
m.RES_THROTTLED = -1

local THROTTLE_LV_1 = 1
local THROTTLE_LV_2 = 2
local THROTTLE_MAX_LIVE = 100

local function _makeEfx(group, name, throttleMode, onComplete)
  if throttleMode == THROTTLE_MAX_LIVE then
    local qsettings = QualityUtil.cachedQualitySettings()
    local maxLiveParticles = qsettings.maxLiveParticles

    if maxLiveParticles > 0 then
      local count = ParticleView.liveCount
      if m.debug then
        logd('[ParticleFactory] name=%s live=%d maxLive=%d', name, count, maxLiveParticles)
      end
      if count > maxLiveParticles then
        return m.RES_THROTTLED
      end
    end
  elseif throttleMode then
    local qsettings = QualityUtil.cachedQualitySettings()
    local particleLevel = qsettings.particleLevel
    if m.debug then
      logd('[ParticleFactory] name=%s mode=%d level=%d', name, throttleMode, particleLevel)
    end
    if particleLevel >= throttleMode then
      return m.RES_THROTTLED
    end
  end

  local tag = string.format('%s/%s', group, name)
  local bundleFile = BundleUtil.getEffectBundleFile(name)

  if not unity.prefabExists(bundleFile) then
    loge('ParticleFactory._makeEfx: %s not exist %s', bundleFile, debug.traceback())
    return
  end
  -- logd('_makeEfx: group=%s name=%s bundlefile:%s', group, name, bundleFile)

  return ViewFactory.makeAsync(group, tag, bundleFile, onComplete)
end

--------------------------------------------------------------
------------------  Particle Views Pooling -------------------
function m.makeDustEffect(tid, name, onComplete)
  return _makeEfx('particles', "dust/"..name, nil, onComplete)
end

function m.makeNotrigenEffect(tid, name, onComplete)
  return _makeEfx('particles', "notrigen/"..name, nil, onComplete)
end

function m.makeCarEffect(tid, name, onComplete)
  return _makeEfx('particles', tid.."/"..name, nil, onComplete)
end

function m.makeCompetitiveEffect(name, onComplete)
  return _makeEfx('particles', "competitive/"..name, nil, onComplete)
end

function m.makeCommonEffect(name, onComplete)
  return _makeEfx('particles', "common/"..name, nil, onComplete)
end

function m.makeSkillEffect(tid, name, onComplete)
  return _makeEfx('particles', tid.."/"..name, nil, onComplete)
end






class('ClipUtil')

local m = ClipUtil

local AnimatorStorable          = Game.AnimatorStorable
local Animator                  = UnityEngine.Animator
local AnimationEvent            = UnityEngine.AnimationEvent
local RuntimeAnimatorController = UnityEngine.RuntimeAnimatorController

function m._getClipTime(view3d, stateName)
  local clipName = m._getClipName(view3d, stateName)
  if clipName then
    return cfg.animClips[clipName] or 0, clipName
  end

  return 0, nil
end

function m._getClipLoop(view3d, stateName)
  local clipName = m._getClipName(view3d, stateName)
  if clipName then
    return cfg.animLoops[clipName] or false
  end

  return false
end

function m._getClipName(view3d, stateName)
  if not view3d.gameObject then return nil end

  if not view3d.animator then
    view3d.animator = view3d.gameObject:getComponent(unity.Animator)
  end

  local animator = view3d.animator
  if not animator then return nil end

  local controller = unity.as(animator:get_runtimeAnimatorController(), RuntimeAnimatorController)
  if not controller then return nil end

  local controllerName = uoc:getAttr(controller, 'name', true)
  if controllerName:match('^ms_') then
    controllerName = controllerName:gsub('ms_', '')
  end

  local controllerConfig = cfg.animators2[controllerName]
  if controllerConfig then
    local stateConfig = controllerConfig[stateName]
    if stateConfig then
      return stateConfig.clip
    end
  end

  return nil
end

function m.getClipPair(view3d, stateName)
  if stateName then
    local time, clipName = m.getClipTime(view3d, stateName)
    if clipName then
      return { clipName = clipName, stateName = stateName, clipLength = time }
    end
  end
  return nil
end

function m.getClipCache(view3d, stateName)
  local clipCaches = view3d.clipCaches

  if not clipCaches then
    clipCaches = {}
    view3d.clipCaches = clipCaches
  end

  local cacheItem = clipCaches[stateName]
  if not cacheItem then
    local clipLength, clipName = m._getClipTime(view3d, stateName)
    local clipLoop = m._getClipLoop(view3d, stateName)

    if clipName then
      cacheItem = {}
      cacheItem[1] = clipName
      cacheItem[2] = clipLength
      cacheItem[3] = clipLoop
      clipCaches[stateName] = cacheItem
    end
  end

  return cacheItem
end

function m.getClipName(view3d, stateName)
  local cache = m.getClipCache(view3d, stateName)
  if cache then
    return cache[1]
  end
  return nil
end

function m.getStatesByClip(controllerName, clipName)
  local config = cfg.clips[controllerName]
  if not config then return nil end
  local o = config[clipName]
  if not o then return nil end
  return o.state_list
end

function m.shoudSkipEvent(controllerName, clipName)
  local config = cfg.clips[controllerName]
  if not config then return true end
  local o = config[clipName]
  if not o then return true end
  return o.skip_event
end

function m.getClipTime(view3d, stateName)
  local cache = m.getClipCache(view3d, stateName)
  if cache then
    return cache[2] or 0, cache[1]
  end

  return 0, nil
end

function m.getClipLoop(view3d, stateName)
  local cache = m.getClipCache(view3d, stateName)
  if cache then
    return cache[3] or false
  end

  return false
end

function m.clear()
  if m.initedAnimators then
    table.clear(m.initedAnimators)
  end
end

local defaultStateNameAccept = function() return true end

function m.initAnimEventsByGameObject(go)
  m.initedAnimators = m.initedAnimators or {}

  local animator = go:getComponent(Animator)
  if not animator then
    logd('[%s] initAnimEvents no animator', tostring(go))
    return
  end

  local animatorController = unity.as(animator:get_runtimeAnimatorController(), RuntimeAnimatorController)
  if not animatorController then
    logd('[%s] initAnimEvents no animatorController', tostring(go))
    return
  end

  local controllerName = uoc:getAttr(animatorController, 'name', true)
  if m.initedAnimators[controllerName] then
    -- logd('[%s] initAnimEvents initedAnimators[%s]=true', tostring(go), tostring(controllerName))
    return
  end

  local clips = animatorController:get_animationClips()

  for i = 1, #clips do
    local clip = clips[i]
    local length = #clip:get_events()
    local skipAdd = false
    local clipName

    if length > 0 then
      skipAdd = true
    else
      clipName = clip:get_name()
      -- clip to state is one-to-many
      skipAdd = m.shoudSkipEvent(controllerName, clipName)
    end

    if not skipAdd then
      -- Important: the stringParameter must use the clip.name instead of statename
      -- as different state might refer to the same clip, but each clip can only have one
      -- anim end event
      -- only add the anim_end event
      local edEvt = AnimationEvent()
      local clipLength = cfg.animClips[clipName] or 2
      edEvt:set_time(clipLength)
      edEvt:set_functionName('OnAnimEvent')
      edEvt:set_stringParameter(clipName .. '#anim_end')
      clip:AddEvent(edEvt)
    end
  end

  m.initedAnimators[controllerName] = true
end

function m.initAnimEvents(view3d)
  if not view3d.gameObject then
    logd('[%s] initAnimEvents gameObject is nil', tostring(view3d.id))
    return
  end
  if not view3d.animator then
    view3d.animator = view3d.gameObject:getComponent(Animator)
  end
  m.initAnimEventsByGameObject(view3d.gameObject)
end

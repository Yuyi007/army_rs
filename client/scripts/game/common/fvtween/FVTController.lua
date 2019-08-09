class('FVTController', function(self)

end)

local fvtc = FVTController

function fvtc.init()
  fvtc.reset()
end

function fvtc.reset()
  fvtc.tweens = {}
  fvtc.counter = 0
  fvtc.frameRemovals = {}
end

local tPrefix = 'tween_'
local maxCounter = 2^30
function fvtc.genTweenId()
  fvtc.counter = fvtc.counter + 1
  if fvtc.counter > maxCounter then
    fvtc.counter = 0
  end
  return tPrefix .. tostring(fvtc.counter)
end

function fvtc.addTween(tween)
  if fvtc.tweens[tween.id] then
    return
  end

  -- gen tween id
  local tweenId = tween.id
  if not tweenId then
    tweenId = fvtc.genTweenId()
    tween.id = tweenId
  end

  -- local trace = debug.traceback()
  -- logd('addTween %s %d: %s', tostring(tween.id),
  --   table.nums(fvtc.tweens), trace)
  -- tween._trace = trace

  -- insert tween by id
  fvtc.tweens[tweenId] = tween
end

function fvtc.delTween(tween)
  if not tween or not tween.id then
    return
  end

  -- logd('delTween %s %d: %s', tostring(tween.id),
  --   table.nums(fvtc.tweens), debug.traceback())

  -- delete tween by id
  fvtc.tweens[tween.id] = nil
end

function fvtc.update(deltaTime)
  -- logd('fvtc tweens=%d', table.nums(fvtc.tweens))

  local tweens = fvtc.tweens
  local frameRemovals = fvtc.frameRemovals

  for id, tween in pairs(tweens) do
    -- logd('fvtc id=%s tween entity=%s trace=%s',
    --   tostring(id), tostring(tween.entityId), tostring(tween._trace))
    -- local entity = cc.findHero(tween.entityId)
    -- if entity then
    --   logd('fvtc entity=%s seen=%s', entity.id, entity.seen)
    -- end
    tween:tick(deltaTime)
    if tween:isTweenDone() then
      -- logd('remove UV %s', tostring(tween.id))
      frameRemovals[#frameRemovals + 1] = tween
    end
  end

  for i = #frameRemovals, 1, -1 do
    local v = frameRemovals[i]
    fvtc.delTween(v)
    frameRemovals[i] = nil
  end
end

function fvtc.tweenCount()
  return table.nums(fvtc.tweens)
end


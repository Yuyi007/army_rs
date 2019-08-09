class('AudioSourceDecorator')

local m = AudioSourceDecorator

function m.decorate(o)
  local mt = getmetatable(o)
  local t = m.funcs()
  for k, v in pairs(t) do
    rawset(mt, k, v)
  end
end

function m.funcs()
  local mt = {}

  function mt.play(self, uri, loop)
    loop = loop or false
    sm:getClipAsync(uri, function(clip)
      if not clip then return end
      if is_null(self) then return end
      self:set_clip(clip)
      self:set_loop(loop)
      self:Play(0)
    end)
  end

  function mt.playSound(self, sound, loop)
    local uri = 'sounds/efx/'..sound
    self:play(uri, loop)
  end

  function mt.stop(self)
    if is_null(self) then return end
    self:set_playOnAwake(false)
    self:Stop()
    self:set_clip(nil)
  end

  return mt
end

setmetatable(m, {__call = function(t, ...) m.decorate(...) end })
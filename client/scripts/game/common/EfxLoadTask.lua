class('EfxLoadTask', function(self, efxId, loadFunc, onComplete)
  self.efxId = efxId
  self.loadFunc = loadFunc
  self.onComplete = onComplete
  self.particle = nil
  self.shouldStop = nil
  self:construct()
end)

local m = EfxLoadTask

function m:construct()
  m.idCounter = m.idCounter or 0
  m.idCounter = m.idCounter + 1
  self.id = m.idCounter
end

function m:reopenInit(efxId, loadFunc, onComplete)
  m.idCounter = m.idCounter or 0
  m.idCounter = m.idCounter + 1
  self.id = m.idCounter

  self.efxId = efxId
  self.loadFunc = loadFunc
  self.onComplete = onComplete
  self.particle = nil
  self.shouldStop = nil
end

function m:reopenExit()
  if self.particle then
    self.particle:destroy()
  end
  self.particle = nil
  self.efxId = nil
  self.loadFunc = nil
  self.onComplete = nil
  self.shouldStop = nil
end

function m:run()
  local res = false
  if self.loadFunc then
    local r = self.loadFunc(self.efxId, function(particle)
      if self.shouldStop then
        particle:destroy()
        self:recycle()
        return
      end
      self.particle = particle
      if self.onComplete then
        self.onComplete(self, particle)
      end
      self:updateParticleFollower(0)
    end)
    res = (r ~= ParticleFactory.RES_THROTTLED)
  end


  if not res then
    self:recycle()
  end
  return res
end

function m:updateParticleFollower(deltaTime)
  if self.particle then
    self.particle:updateFollower(deltaTime)
  end
end

function m:destroy()
  if self.particle then
    self.particle:destroy()
    self.particle = nil
    self:recycle()
  else
    self.shouldStop = true
  end
end

function m:recycle()
  ObjectFactory.recycle(self)
end































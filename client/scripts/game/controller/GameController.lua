class('GameController', function(self)
  self:init()
end)

local m = GameController
local ic = IntervalChecker

function m:init()
  self.taskQueue = HeavyTaskQueue.new()
end

-- TODO correctly reset schedulers and signals
function m:reset()

end

function m:signal(t)
  local signal = self.signals[t]
  if not signal then
    signal = Signal.new()
    self.signals[t] = signal
  end
  return signal
end

function m:clearSignals()
  for k, signal in pairs(self.signals) do
    signal:clear()
    self.signals[k] = nil
  end
end

function m:cleanup()
  self.taskQueue:flushTasks()
end


class('Repeater', function(self, config)
  self.num = config.num or 1
  self.count = 0
end, Decorator)

local m = Inverter

function m:running()
  if self.count < self.num then
    self.control:running()
    self.count = self.count + 1
  else
    self.control:success()
  end
end

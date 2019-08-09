class('Inverter', function(self, config)
end, Decorator)

local m = Inverter

function m:success()
  self.control:fail()
end

function m:fail()
  self.control:success()
end

class('Failer', function(self, config)
end, Decorator)

local m = Failer

function m:success()
  self.control:fail()
end

function m:fail()
  self.control:fail()
end
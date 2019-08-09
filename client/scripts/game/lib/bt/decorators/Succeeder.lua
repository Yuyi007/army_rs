
class('Succeeder', function(self, config)
end, Decorator)

local m = Succeeder

function m:success()
  self.control:success()
end

function m:fail()
  self.control:success()
end
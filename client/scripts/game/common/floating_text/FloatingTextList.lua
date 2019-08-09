class('FloatingTextList', function(self)
  self.messages = {}
  self.index = 1
end)

local m = FloatingTextList

local mInstance = nil

function FloatingTextList.instance()
  if mInstance == nil then
    mInstance = FloatingTextList.new()
    ui:signal("leave_main_scene"):add(function()
      if mInstance then
        mInstance:stop()
      end
    end)
  end
  return  mInstance
end

function FloatingTextList.setInstance(inst)
  mInstance = inst
end

-- options{color}
function m:addMessage(message, onComplete, extOptions)
  table.insert(self.messages, {message=message, onComplete=onComplete, extOptions = extOptions})
  self:show()
end

function m:addMessages(addMessages)
   for k,v in pairs(addMessages) do
     table.insert(self.messages, {message=v})
   end
   self:show()
end

function m:show()
  if self.floatingHandler ~= nil then return end
  local fun = function()
    if self.index > table.getn(self.messages) then
      self:stop()
    else
      FloatingTextFactory.makeNormal({onComplete=self.messages[self.index].onComplete, text=self.messages[self.index].message, extOptions=self.messages[self.index].extOptions})
      self.index = self.index + 1
    end
  end
  self.floatingHandler = scheduler.schedule(fun, 0.8)
  fun()
end

function m:stop()
  scheduler.unschedule(self.floatingHandler)
  self.floatingHandler = nil
  self.messages = {}
  self.index = 1
end
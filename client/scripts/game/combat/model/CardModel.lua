class('CardModel', function(self, options)
  self.options  = nil
  self.name     = nil
  self.weight   = nil
  self.color    = nil
  self.belongto = nil
  self.view     = nil
  self:init(options)
end)

local m = CardModel 

function m:init(options)
  self.options  = options
	self.name     = options.name
	self.weight   = options.weight
	self.color    = options.color
	self.belongto = options.belongto
  -- logd(">>>>>>options:%s",inspect(self.weight))
end

function m:setCardView(view)
  self.view = view
end

function m:setBelongto(sendTo)
  if not sendTo then return end
  self.belongto = sendTo 
end

function m:destory()
  self.name     = nil
  self.weight   = nil
  self.color    = nil
  self.belongto = nil
end
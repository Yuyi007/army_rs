View('DeskView', nil, function(self, gameObject, parent)
  self:bind(gameObject)
  self.parent = self
end)

local m = DeskView

function m:init()
  logd(">>>>>[DeskView]:init")
  for i =1,3 do 
  	self["showpoint_img"..i]:setVisible(false)
  end	
end

function m:exit()
  logd(">>>>>[DeskView]:exit")
  for i =1,3 do 
  	self["showpoint_img"..i]:setVisible(false)
  end	
end

function m:setIdentity(sp)
  -- self.head:setSprite(sp)
end

function m:setShowPoint(cards)
  if #cards ~= 3 then return end
  for i,card in pairs(cards) do
  	self["showpoint_img"..i]:setVisible(true)
  	self["showpoint_img"..i]:setSprite(card.name)
  end	
end

function m:hideCreatPoint()
  self.createpoint:setVisible(false)
end

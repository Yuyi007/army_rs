View('MainSlotView', 'prefab/slot_ui', function(self, index, data, parent, funcOnDrag, funcOnPointerUp, funcOnPointerEnter, funcOnPointerExit)
	self.index = index
	self.data = data
	self.parent = parent
	self.funcOnDrag = funcOnDrag
	self.funcOnPointerUp = funcOnPointerUp
	self.funcOnPointerEnter = funcOnPointerEnter
	self.funcOnPointerExit = funcOnPointerExit
	self.dragOn = false
end)

local m = MainSlotView


function m:init()
	self:updateUI()
	self:initEventTrigger()
end


function m:exit()
	-- body
end

function m:update(index, data)
	self.index = index
	self.data = data
	self:updateUI()
end

function m:updateUI(sp)
	if sp then self.data.img = sp end
	logd(">>>>>img:%s",tostring(sp))
	self.root_img:setSprite(self.data.img)
end

function m:initEventTrigger()
	self.root:addEventTrigger('Drag', function(eventData)
		self.root_img:setVisible(false)
		if self.funcOnDrag then self.funcOnDrag(self.parent, self.data.img, self, eventData) end
	end)

	self.root:addEventTrigger('PointerUp', function(eventData)
    logd(">>>>>>up")
		if self.funcOnPointerUp then self.funcOnPointerUp(self.parent, function(success)
			  if success == 0 then
			  	self.root_img:setVisible(true)
			  elseif success == 1 then
			  	self.root_img:setVisible(false)
			    self.data.img = nil
			  else
			  	self.root_img:setVisible(true)
			  end 				  
		  end) 
	  end
	end)

	self.root:addEventTrigger('PointerEnter', function(eventData)
    logd(">>>>>>enter")
	  if self.funcOnPointerEnter then self.funcOnPointerEnter(self.parent, self.data.img, self) end	 
	end)
  
  self.root:addEventTrigger('PointerExit', function(eventData)
    logd(">>>>>>PointerExit")
    if self.funcOnPointerExit then self.funcOnPointerExit(self.parent) end
	end)

end


View("CardView", "prefab/ui/card/card_ui", function(self)
  self.isSelect = false
  self.model = nil
  self.drag = true
end)

local m = CardView
local Input = UnityEngine.Input

function m:reopenInit(options)
  self:initTouch()
  self.options = options
  self.transform:set_localEulerAngles(Vector3.zero)
end

function m:reopenExit()   
end

function m:setModel(model)
  if model == nil then return end 
  self.model = model
end

function m:setImage()
  if self.model.belongto == CHARACTER.ME or self.model.belongto == CHARACTER.DESK then
  	--显示牌的正面
    self.icon:setSprite(self.model.name)
  else
  	--显示牌的背面
    self.icon:setSprite('FixedBack')
  end
end

function m:setImageBack()
  self.icon:setSprite('CardBack')
end


function m:belongToPos()
  local pos = self.transform:get_localPosition()
  if self.isSelect then
    pos = pos + Vector3.static_up * 10
  else
    pos = pos - Vector3.static_up * 10
  end   
  self.transform:set_localPosition(pos)
end

function m:setCardPos(parent ,index)
  self.transform:setParent(parent, false)
  self.transform:SetSiblingIndex(index)

  if self.model.belongto == CHARACTER.ME then
    self.transform:set_localPosition( Vector3.static_right * 30 * index)

    --防止还原
    if self.isSelect then
      local pos = self.transform:get_localPosition()
      pos = pos + Vector3.static_up * 20
      self.transform:set_localPosition(pos)
    end
  end

  if self.model.belongto == CHARACTER.DESK then
    index = index - 1
    self.transform:set_localPosition( Vector3.static_right * 30 * index)
    self.transform:set_localEulerAngles(Vector3.zero)
  end  

  if(self.model.belongto == CHARACTER.LEFT or self.model.belongto == CHARACTER.RIGHT) then
    -- local pos = self.transform:get_localPosition()
    local pos =   Vector3.static_left * 8 * index - Vector3.static_up * 8 * index
    self.transform:set_localPosition(pos)
    self.transform:set_localEulerAngles(Vector3(240,0, 105))
  end

end



function m:destroyView()
  self:destroy()
end

function m:onSelect()
  if self.model.belongto == CHARACTER.ME then
    self.isSelect = not self.isSelect
    self:belongToPos()
    if self.isSelect then sm:playSound('Sound/select') end
  end  
end

function m:initTouch()
  self.btnSelect:addEventTrigger("PointerDown", function ()
    cc:setDragValue(true)
    self:onSelect()
  end)
  
  self.btnSelect:addEventTrigger("PointerEnter", function ()
    if cc.onEnter == true then 
      self.drag = false 
    else
      self.drag = true 
    end  
      
    if self.drag == false then self:onSelect() end
  end)

  self.btnSelect:addEventTrigger("PointerExit", function ()
    if self.drag == false and cc.onEnter == true then
      self.drag = true
    end
  end)

  self.btnSelect:addEventTrigger("PointerUp", function ()
    cc:setDragValue(false)
  end)

end





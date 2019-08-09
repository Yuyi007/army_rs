class('SliderUtil', function(self,env)
  self.env = env
  self.off =  env.weight   
  self.dragEnd = false     
  self.parentView = env.view    
  self.height    = env.height  --sv的高度 
  self.weight    = env.weight  --sv的宽度     
  self.sv        = env.sv    
  self.gird      = env.gird    --有多少技能表格
  --self.offset  sv的坐标x - 第一张图片宽度的一半(以这个作为缩放) 
  self.content = env.content 
  self.info = {}  
  --logd(">>>>>>>>>env.offset4:"..inspect(self.offset))
  self.signwv =env.weight-(env.weight/2)*(1/3)  --暂时用不到(content最左边和最右边的图片移动位置)
end)

local m = SliderUtil

function m:init()
  self.sv:addEventTrigger('BeginDrag',function (eventData)
    self.beginposx = eventData.position[1]
    -- if self.Hcenter then 
    --   scheduler.unschedule(self.Hcenter)
    --   self.Hcenter = nil
    -- end
    --self.sv.scrollRect:set_horizontal(true)
  end)
  self.sv:addEventTrigger('Drag',function (eventData)
    --self.sv.scrollRect:set_movementType( UI.ScrollRect.MovementType.Elastic)
    self.sv:setScrollMoveType(1)  
  end) 
  self.sv:addEventTrigger('EndDrag',function (eventData)
    --self.sv.scrollRect:set_horizontal(true)
     --self.sv.scrollRect:set_movementType( UI.ScrollRect.MovementType.Unrestricted )
     self.sv:setScrollMoveType(0)
     self:updateCenter(function(info)
        --logd(">>>>>>>>>>info:"..inspect(info))
        self.parentView:update(info)
     end)
  end)
  self:initGird()
  
end

function m:initGird()
  logd(">>>>>>>>self.sv:"..inspect(self.sv.transform:get_position().x))
   for k,view in pairs(self.gird) do
    --logd(">>>>>>>>>>K:"..inspect(k))
      if k == 1 then 
       self.firstView = view
       --logd(">>>>>>>>>>>>>view:"..inspect(view.transform:get_localPosition().x))
       --logd(">>>>>>>>>>>>view1:"..inspect(self.weight))
       self.offset = self.sv.rectTransform:get_rect():get_width()/2-view.rectTransform:get_rect():get_width()/2

       --self.offset = 78--self.weight - view.transform:get_position().x 
       --logd(">>>>>>self.offset:"..inspect(self.offset))
      elseif k ==2 then 
        --logd(">>>>>>>>>>>>>view:"..inspect(view.transform:get_position().x))
      elseif k == #(self.gird) then 
       self.lastView = view
      end  
  end
  self:startFrameUpdate()     
end

 function m:startFrameUpdate()
    self.hFrameUpdate = scheduler.scheduleWithUpdate(function()
      self:onFrame()
    end, 0.025)
 end

function m:onFrame()
   self:UpdateDrag()
end

function m:sethorBegin()
   self.Hhontziontal = scheduler.scheduleWithUpdate(function()
       if (self.firstViewPos.x - self.weight) > #(self.gird)*self.offset  then --or math.abs(self.lastViewPos.x - self.weight) >= self.offset
          --logd(">>>>>>>>self.signwv:"..inspect(self.offset))
          scheduler.unschedule(self.Hcenter)
          scheduler.unschedule(self.Hhontziontal)
          self.Hcenter = nil 
          self.Hhontziontal = nil
          --self.sv.scrollRect:set_horizontal(false)
        end  
    end, 0.025)
end

function m:sethorStop()
    if self.Hhontziontal then 
      scheduler.unschedule(self.Hhontziontal)
      self.Hhontziontal = nil 
    end
    self.sv.scrollRect:set_horizontal(true)
end

function m:UpdateDrag() --拖拽中更新图片缩放

  for k,view in pairs(self.gird) do 
    local tx = view.transform:get_position().x
    --logd(">>>>>>>>>>>>>>>tx:"..inspect(tx))
    local offset = math.abs(tx-self.weight)
    if k == 1 then 
       --logd(">>>>>>>>>>offset:"..inspect(offset))
    end   
    if offset == self.offset then 
       view.transform:set_localScale(Vector3.one)
    else 
      local value = 1 + 0.5*(1-offset/self.offset)
      local scale = Vector3(value,value,value)
      view.transform:set_localScale(scale)
    end 
  end
  --local tt1 =  self.firstView.transform:get_position().x - self.weight
  --local tt2 =  self.lastView.transform:get_position().x - self.weight
  --local pos = self.content.transform:get_localPosition()
  --
  --if tt1 >= self.offset or tt2 <= (-self.offset) then 
    --logd(">>>>>>>>>>>tt:"..inspect(tt))
    --self.content.transform:set_localPosition(pos)
    --self:updateCenter()
  --   self.sv.scrollRect:set_horizontal(false)
  -- else
  --   self.sv.scrollRect:set_horizontal(true)
  -- end  
end

function m:updateCenter(onComplete)  --拖放结束后离最近的一张图片更新到中间
    for k,view in pairs(self.gird) do 
      local viewx = view.transform:get_position().x
      local value = math.abs(viewx - self.weight)
      -- if value =math.abs(view.transform:get_localPosition().x - self.middlecenter)
      if value < self.off then 
        self.off = value 
        self.currentView = view 
      end 
    end  
    self:ScheduleToCenter()
    self.off = self.weight
    local imagename = self.currentView.image:get_sprite().name
    self.info['image'] = imagename
    --logd(">>>>>>>>>>>self.info:"..inspect(self.info))
    if onComplete then 
       onComplete(self.info)
    end   
end

function m:ScheduleToCenter()

  --logd(">>>>>>>>>>>self.currentView2:"..self.currentView.rectTransform:get_rect():get_width())
  --logd(">>>>>>>>>>>self.currentView3:"..self.content.rectTransform:get_rect():get_width())
  --logd(">>>>>>>>>>>self.currentView4:"..self.content.rectTransform:get_localPosition().x)
    if self.Hcenter then 
      scheduler.unschedule(self.Hcenter)
      self.Hcenter = nil
    end    
    local value = self.currentView.transform:get_position().x - self.weight 
    local moveEndValue = self.content.rectTransform:get_localPosition().x-value
    local curX =self.content.rectTransform:get_localPosition().x
    local elapsedTime = 0
      self.Hcenter = scheduler.scheduleWithUpdate(
         function(deltaTime)
        elapsedTime = elapsedTime + 3
      --logd(">>>>>>>>>>curX:"..inspect(curX))
      if value > 0 then --向左移动
        self.contentX = curX-elapsedTime
        self.content.rectTransform:set_localPosition(Vector3.new(self.contentX,0,0))
        if self.contentX <= moveEndValue then
          scheduler.unschedule(self.Hcenter)
          self.Hcenter = nil
        end      
      elseif value < 0 then  --向右移动
        self.contentX = curX+elapsedTime
        self.content.rectTransform:set_localPosition(Vector3.new(self.contentX,0,0))
        if self.contentX >= moveEndValue then
          scheduler.unschedule(self.Hcenter)
          self.Hcenter = nil
        end
      end
    end)    
end

function m:stopFrameUpdate()
    if self.hFrameUpdate then 
      scheduler.unschedule(self.hFrameUpdate)
      self.hFrameUpdate = nil 
    end  
end

View('PopNameView', 'prefab/ui/room/pop_name_ui', function(self, parent)
  self.animType  = "level2"
  self.parent = parent
  -- self.name   = ""
end)

local m = PopNameView

function m:init()
	
end

function m:exit()
  self:stopHName()
  self.InputName:setString('')	
end

function m:onBtnRoll()  
	self:stopHName()
	local nameArray = cfg.name
	self.btnRoll_roll:setVisible(true)
	self.btnRoll_def:setVisible(false)
  self.Hname =  scheduler.performWithDelay(2,function ()
  	local i =  math.random(table.getn(nameArray))
  	local name = nameArray[i]
  	self.InputName:setString(name)
  	self.btnRoll_roll:setVisible(false)
  	self.btnRoll_def:setVisible(true)
  end)
end

function m:onBtnConfirm()
  local name = self.InputName:getString()
   
  if name ~= "" then
    if string.byte(name) > 127 then
      local _, count = string.gsub(name, "[^\128-\193]", "")
      if count > 6 then
        FloatingTextFactory.makeFramedTwo {text = loc('str_name_six_limit',3), 
        color = ColorUtil.red }
        return
      end  
    end 
    md:rpcChangeName(name, function(msg)
    	self.parent:getName(msg.name)
    end)
  end 
	ui:pop()
end

function m:onBtnCancel()
	ui:pop()
end

function m:onBtnClose()
	ui:pop()
end

function m:stopHName()
	if self.Hname then
  	scheduler.unschedule(self.Hname)
  	self.Hname = nil 
  end 
end
View("RoomView", "prefab/room_ui", function(self, roomInfo)
  self.pos = {}
  self.roomInfo = roomInfo
  self.members = roomInfo['members']
end)

local m = RoomView

function m:init()
	self:initUI()
	self:setPlyPos()
  self:initSignal()
end

function m:initUI()
	for i = 1,3 do 
		self['py'..i..'_ready']:setVisible(false)
		self['py'..i..'_name']:setVisible(false)
	end	
end

function m:setPlyPos()
	RoomUtil.setRoomPos(self.members, self.pos)
end

function m:initSignal()
	
end

function m:unSignal()
	-- body
end

function m:updateInfo()
	if table.getn(self.pos) == 0 then 
		FloatingTextFactory.makeFramed{text=loc('房间无人')}
		ui:pop()
		return
	end

  if self.pos['me'] then
    local info  = self.pos['me'] 
    self.py1_name:setVisible(true)
  	self.py1_name:setString(info.name)
  end

  if self.pos['right'] then
  	local info = self.pos['right']
  	self.py2_name:setVisible(true)
  	self.py2_name:setString(info.name)
  end

  if self.pos['left'] then
  	local info = self.pos['left']
  	self.py2_name:setVisible(true)
  	self.py2_name:setString(info.name)
  end	

end

function m:exit()
	self:unSignal()
end



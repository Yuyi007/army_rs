View("RoomSlotView", "prefab/room_slot_ui", function(self, index, data, parent)
  self.index = index
  self.data  = data
  self.parent= parent 
end)

local m = RoomSlotView

function m:init()
	self:updateInfo()
end

function m:update(index, data)
	self.index = index
	self.data  = data
	self:updateInfo()
end

function m:exit()
	
end

function m:updateInfo()
	local type = self.data['type']
	local members = self.data['members']
	local creator = self.data['creator']

	local str = RoomUtil.setStringModel(type)
	self.mod:setString(str)

	str = RoomUtil.getHouseName(creator, members)
	if str then self.house:setString(str) end

	str = RoomUtil.getRoomPlyNum(members)
	str = string.format("%d/3", tonumber(str))
  self.plyNum:setString(str)

end
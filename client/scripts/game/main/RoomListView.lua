View("RoomListView", "prefab/room_list_ui", function(self)
  self.slots = {}
end)

local m = RoomListView

function m:init()
  self:getRoomList()
end

function m:exit()
  
end

function m:onBtnCreate()
  md:rpcCreateRoom("PVP",function (roomInfo)
  	self.roomInfo = roomInfo
  end)
end

function m:getRoomList()
	md:rpcGetRoomList(function (msg)
	  local rooms = msg['room_infos']
    self:updateList(rooms)
	end)
end

function m:onBtnRefresh()
  self:getRoomList()
end

function m:updateList(data)
	data = data or {}
	self.rooms = data
  logd("[RoomListView] rooms:%s", inspect(self.rooms))
	local env = {
    view  = self,
    list  = self.rooms,
    sv    = self.svRoom,
    dir   = 'v',
    slotHeight = 46.6,
    slotWidth = 707,
    slots = self.slots,
    getSlot = self.getSlot,
    updateSlot = self.getSlot,
    shouldReset = false,
    isAnimate    = false,
    onComplete = function()

    end
   }
   ScrollListUtil.MakeVertListOptimized(env)
end

function m:getSlot(index, data)
	local slot = nil
  if self.slots[index] == nil then
    slot = RoomSlotView.new(index, data, self)--ViewFactory.make('RoomSlotView', self, index, data)
    self.slots[index] = slot
  else
    slot = self.slots[index]
    slot:update(self, index, data)
  end
  return slot
end
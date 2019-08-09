View("MainRoomView", "prefab/ui/room/main_room_ui", function(self)
 
end)

local m = MainRoomView
-- local Input = UnityEngine.Input

function m:reopenInit()
 

end

function m:reopenExit()
  
end

function m:onBtnPVP()
  local view = RoomListView.new()
  ui:push(view)
end







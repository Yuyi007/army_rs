View("MainRoomView", "prefab/main_room_ui2", function(self)
 
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







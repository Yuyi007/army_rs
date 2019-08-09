class('RoomUtil')

local m = RoomUtil

function m.getStringModel(str)
	local s = nil
	if str == "PVP" then
    s = "网络版"
  else
  	s = "单机版"
  end
  return s	
end

function m.getHouseName(creator, members)
	for _,info in pairs(members) do
		if info.uid == creator then
			return info.name
		end
	end
	return nil		
end

function m.getRoomPlyNum(members)
  local i = 0
  for _,info in pairs(members) do
  	if info ~= -1 then i = i + 1 end
  end	
  return i
end

function m.getRoomPos(members)
  local uid = md.chief.id
  for i,info in pairs(members) do
    if info.uid == uid then
      return i , info
    end
  end
  return false,false    
end

function m.setRoomPos(members, pos)
  local index, info = m.getRoomPos(members)
  if info == false then return end
  pos['me'] = info
  local rIndex = index + 1 > 3 and 1 or index + 1
  local lIndex = index + 2 > 3 and 1 or index + 2
  for i,data in pairs(members) do
    if i == rIndex then pos['right'] = data end
    if i == lIndex then pos['left'] = data end
  end 
end
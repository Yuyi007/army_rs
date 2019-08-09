-- ModelRpc.lua

-- Modifications to game model should only be performed from this file
-- and ModelRpc* files

local dump = function(t)
  if type(t) == 'table' then
    local msg = json.encode(t)
    print(msg)
  else
    print(tostring(t))
  end
end

function Model:rpcGetGameData(onComplete)
  mp:sendMsg(151, {}, function (msg)
    if msg.success == false then return end
    self:applyGetGameDataResult(msg)
    
    onComplete(msg)
    
    if md:hasInstance() then
      reportGameData('enterServer')
    end
  end)
end

function Model:rpcResumeGameData(onComplete)
  local version = self.version or - 1
  logd('rpcResumeGameData: current version is %s', tostring(version))
  
  mp:sendMsg(152, {version = version}, function (msg)
    if msg.success ~= false then
      if msg.same then
        logd('rpcResumeGameData: data was not touched, safely resuming')
      else
        logd('rpcResumeGameData: data has changed, latest version is %s', tostring(msg.md_ver))
        self:applyGetGameDataResult(msg)
      end
    end
    if md then
      md:signal('resume_game'):fire()
    end
    onComplete(msg)
  end)
end

function Model:rpcCreateInstance(name, onComplete)
  mp:sendMsg(155, {name = name}, function(msg)
    if msg.success ~= false then
      self:applyGetGameDataResult(msg)
    end
    
    onComplete(msg)
    
    if md:hasInstance() then
      reportGameData('createRole')
    end
    
  end, mp.queueOptsHasMask)
end


function Model:rpcCreateNewInstance(name,gender,icon, onComplete)
  mp:sendMsg(155, {name = name,gender=gender,icon=icon}, function(msg)
    if msg.success ~= false then
      self:applyGetGameDataResult(msg)
    end
    onComplete(msg)
    if md:hasInstance() then
      reportGameData('createRole')
    end
  end, mp.queueOptsHasMask)
end

function Model:rpcChooseInstance(id, onComplete)
  mp:sendMsg(154, {id = id}, function(msg)
    if msg.success == false then return end
    local ActionRecord = Game.ActionRecord
    self:applyGetGameDataResult(msg)

    logd("[md:pid()]:%s", tostring(md:pid()))
    ActionRecord.setPid(md:pid())

    onComplete(msg)
  end, mp.queueOptsHasMask)
end

function Model:rpcGetRoomList(onComplete)
  mp:sendMsg(158, {}, function(msg)
    if not msg.success then return end
    onComplete(msg)
  end)
end

function Model:rpcGetRoomInfo(id, onComplete)
  mp:sendMsg(159, {id = id}, function(msg)
    if not msg.success then return end
    onComplete(msg.room_info)
  end)
end


function Model:rpcCreateRoom(type, onComplete)
  mp:sendMsg(160, {type = type}, function(msg)
    if not msg.success then return end
    
    if msg.cur_room_id then
      local inst = self:curInstance()
      inst.cur_room_id = msg.cur_room_id
    end
    onComplete(msg.room_info)
  end)
end

function Model:rpcJoinRoom(id, side, seat, ready, houseCreator)
  mp:sendMsg(161, {id = id, side = side, seat = seat, ready = ready, houseCreator = houseCreator}, function(msg)
    if not msg.success then 
      return 
    end
    if msg.cur_room_id then
      local inst = self:curInstance()
      inst.cur_room_id = msg.cur_room_id
    end
  end)
end

function Model:rpcLeaveRoom(id, onComplete)
  mp:sendMsg(162, {id = id}, function(msg)
    -- if not msg.success then return end
    
    local inst = self:curInstance()
    inst.cur_room_id = nil
    
    onComplete(msg)
  end)
end

function Model:rpcSendTestData(data, onComplete)
  mp:sendMsg(1001, {data = data }, function(msg)
    onComplete(msg)
  end)
end

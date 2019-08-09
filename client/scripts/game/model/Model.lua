class('Model', function(self)
  self.account = Account.new()
  self:init()
end)

local PRE_PROCESS = {
}

local PRE_PROCESS_SINGLE = {
}

local LOOKUP = {
  items       = true, -- gen func md:items()
  fragments   = true, -- gen func md:fragments()
  coins       = true, -- gen func md:coins()
}

local SINGLE_LOOKUP = {
  item       = true,  -- gen func md:item(tid)
}

-- generate functions for delegating lookup to current instance
-- like md:items(), md:props()
for k, v in pairs(LOOKUP) do
  Model[k] = function(self)
    if PRE_PROCESS[k] then
      return self['preProcess' .. string.capitalize(k)](self)
    else
      local instance = self:curInstance()

      if instance == nil then
        return {}
      else
        return instance[k]
      end
    end
  end
end

-- generate functions for delegating lookup with id
-- like md:item(tid), md:prop(id)
for k, v in pairs(SINGLE_LOOKUP) do
  Model[k] = function(self, id)
    if PRE_PROCESS_SINGLE[k] then
      return self['preProcess' .. string.capitalize(k)](self, id)
    else
      local instance = self:curInstance()
      local key = k..'s'
      if instance then
        local list = instance[key]
        if list then return list[id] end
      end
      return nil
    end
  end
end

function Model:init()
  self.account:init()
  self:initSignals()
  self.unReadMailNum       = 0
  self.mails               = self.mails or {}
  self.readInfos           = self.readInfos or {}
  self.redeemInfos         = self.redeemInfos or {}
  self.recoFrdData         = { data = {}, updateTime = 0}
end

function Model:isCurInstance(id)
  if not self.chief then return false end
  return id == self.chief.cur_inst_id
end

function Model:getRecoFriends(onGetData)
  local now = stime()

  local updateTime = self.recoFrdData.updateTime 
  
  local function updateRecoData()
    self:rpcGetRangeFriends(function(msg)
      self.recoFrdData.data = msg
      self.recoFrdData.updateTime = now
      onGetData(self.recoFrdData.data)
    end)
  end 
  
  if updateTime == 0 then 
    updateRecoData()
  else
    local elapse = now - updateTime
    if elapse >= 60 * 10 then
      updateRecoData()
    else
      onGetData(self.recoFrdData.data)
    end
  end
end


function Model:getChatCacheList()
  if self.chatCacheList == nil then self.chatCacheList = {} end
  return self.chatCacheList
end

function Model:clearChatCacheList()
  self.chatCacheList = nil
  self.chats = nil
end

function Model:setLobby(pid, lid)
  logd('setLobby %s %s', tostring(pid), tostring(lid))
  self.lobby = self.lobby or {}
  self.lobby[pid] = lid
end


function Model:getLobby(pid)
  self.lobby = self.lobby or {}
  return self.lobby[pid] or 'offline'
end

function Model:hasInstance()
  return self:curInstance() ~= nil
end

-- pid - a unique player id
-- chiefId_instanceId
function Model:pid()
  if self.chief and self.chief.cur_inst_id then
    return self.chief.zone .. '_' .. self.chief.id .. '_' .. self.chief.cur_inst_id
  end

  return nil
end

function Model:tid()
   if self.chief and self.chief.id then
    return self.chief.id 
  end

  return nil
end

function Model:instId()
  return self.chief.cur_inst_id
end

function Model:curInstance()
  if not self then error('Do not use md.curInstance()') end
  local chief = self.chief
  if chief == nil or chief.cur_inst_id == nil then return nil end
  return self.instances[chief.cur_inst_id]
end

function Model:instance()
  return self:curInstance()
end

function Model:updateChats(chat, isTop)
  self.chats = self.chats or {}
  local mypid = self:pid()
  -- local list = string.split(chat.cid, "_", 1)
  -- chat.cid = list[1]
  isTop = isTop == nil and true or isTop
  -- print("!!!!!!!!!=====model===updatechat======"..inspect(chat))
  if chat.ch_id then
    self.chats[chat.ch_id] = self.chats[chat.ch_id] or {}
    if isTop == true then
      table.insert(self.chats[chat.ch_id], 1, chat)
    else
      table.insert(self.chats[chat.ch_id], chat)
    end
    if #self.chats[chat.ch_id] > 20 then
      table.remove(self.chats[chat.ch_id])
    end
  end
end

function Model:updateFrdChats(chat, isTop)
  self.chats = self.chats or {}
  local mypid = self:pid()
  isTop = isTop == nil and true or isTop
  if chat.frompid == mypid then
    self.chats[chat.topid] = self.chats[chat.topid] or {}
    if isTop == true then
      table.insert(self.chats[chat.topid], 1, chat)
    else
      table.insert(self.chats[chat.topid], chat)
    end
    if #self.chats[chat.topid] > 20 then
      table.remove(self.chats[chat.topid])
    end
  elseif chat.topid == mypid then
    self.chats[chat.frompid] = self.chats[chat.frompid] or {}
    if isTop == true then
      table.insert(self.chats[chat.frompid], 1, chat)
    else
      table.insert(self.chats[chat.frompid], chat)
    end
    if #self.chats[chat.frompid] > 20 then
      table.remove(self.chats[chat.frompid])
    end
  end  
end

function Model:updateTeamInfo(teamInfo)
  self:curInstance().team_info = teamInfo
end

require 'game/model/ModelPrivate'
require 'game/model/ModelRpc'
require 'game/model/ModelFuns'

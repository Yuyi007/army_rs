class("Verify", function(self) end)

local m = Verify

local ITEMS_KEY = "members"
local STAT_KEY = "stat"

function m:init(agent, _token)
  self.token = _token
  self.frameInfos = {}
  self.agent2client = {}
  self.client2agent = {}
  self.frameTimestamp = {}

  self.interval = 5 * 1000      -- check clear per 5s
  self.frameTimeout = 5* 1000
  self:startClearData()
end

function m:getPlayerCount(roomToken)
  return 3
end

function m:sendData2Client(agent, msg)
  skynet.send(".agent", "lua", "sockSendMsg", msg)
end

function m:clear(agent)
  self.frameInfos = {}
  print("room info clear -- token:", self.token, " agent", agent)
  -- skynet.send(".agent", "lua", "test")

  local msg = {}
  msg.res = "ok"
  --self:sendData2Client(agent, msg)
  skynet.send(agent, "lua", "sockSendMsg", msg)
end

function m:frameCheck(agent, msg)
  print("frameCheck:", agent, inspect(msg))
  --print(">>frameinfos:", inspect(self.frameInfos))

  local frame = tostring(msg["frame"])    -- frame index
  local type= tostring(msg["type"])       -- data type   1001 ~ 9999
  local cid = tostring(msg["pid"])        -- client id
  local value = msg["data"]               -- data value
  self.client2agent[cid] = agent

  if self.frameInfos[frame] == nil then
    self.frameInfos[frame] = {}
    self.frameTimestamp[frame] = skynet.now()
  end

  local frameList = self.frameInfos[frame]

  if frameList[type] == nil then
    frameList[type] = {}
    frameList[type][ITEMS_KEY] = {}
    frameList[type][STAT_KEY] = {}
  end

  local itemList = frameList[type][ITEMS_KEY]
  local statList = frameList[type][STAT_KEY]

  itemList[cid] = value;
  if statList[value] == nil then
    statList[value] = 1
  else
    statList[value] = statList[value] + 1
  end

  -- get max
  local _max = 0
  for k,v in pairs(statList) do
    if k ~= ":max" then
      if _max < v then
        _max = v
      end
    end
  end
  statList[":max"] = _max

  print("token", self.token, "frameinfos:", inspect(self.frameInfos[frame]))

  -- do check
  local verifyFail = {}
  verifyFail["msg"] = "frame check failed!"
  verifyFail["frame"] = msg["frame"]
  verifyFail["type"] = msg["type"]
  verifyFail["token"] = self.token
  verifyFail["data"] = value
  verifyFail[ITEMS_KEY] = itemList

  local bcheck = false
  local cnt = 0
  for k,v in pairs(itemList) do
    cnt = cnt + 1
    if cnt >= 2 then 
      bcheck = true
      break
    end
  end

  if bcheck then 
    local eData = nil

    for k,v in pairs(itemList) do    
      local clientid = k

      local curCount = statList[v]
      print("compare", k, v, curCount, _max)

      if curCount < 2 then        
        verifyFail["pid"] = clientid
        verifyFail["data"] = v

        local toagent = self.client2agent[clientid]
        print(inspect(verifyFail))
        if toagent then
          skynet.send(toagent, "lua", "sockSendMsg", verifyFail)
          -- skynet.error(inspect(verifyFail))
        end
        eData = eData or inspect(verifyFail)
      end
    end

    if eData then
      skynet.error(eData)
    end

  end
end

function m:checkData()
  local tnow = skynet.now()
  local delList = {}
  for k,v in pairs(self.frameTimestamp) do
    if tnow - v > self.frameTimeout then
      table.insert(delList, k)
      self.frameInfos[k] = nil
    end
  end

  for _,v in pairs(delList) do
    self.frameTimestamp[v] = nil
  end

  print("@@@@ clear timeout frames ### token", self.token, "frameinfos:", inspect(self.frameInfos), inspect(self.frameTimestamp))
end

function m:startClearData()
  self:stopClearData()
  self.hChecker = Scheduler.schedule(self.interval, function()
      self:checkData()
    end)
end

function m:stopClearData()
  if self.hChecker then
    Scheduler.unschedule(self.hChecker)
    self.hChecker = nil
  end
end
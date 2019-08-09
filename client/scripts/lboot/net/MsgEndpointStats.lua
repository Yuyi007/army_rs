-- MsgEndpointStats.lua

--[[
  Stats (in/out rate, total etc.) management related part of the MsgEndpoint class
  All metric values are in bytes or bytes/second
]]--

local string = string
local engine = engine

MsgEndpoint.allTimeSent = MsgEndpoint.allTimeSent or 0
MsgEndpoint.allTimeReceived = MsgEndpoint.allTimeReceived or 0
MsgEndpoint.allTimeDetailed = MsgEndpoint.allTimeDetailed or {}
local allTimeSent = MsgEndpoint.allTimeSent
local allTimeReceived = MsgEndpoint.allTimeReceived
local allTimeDetailed = MsgEndpoint.allTimeDetailed

-- init this module
function MsgEndpoint:initStats()
  self.curSent = 0
  self.curReceived = 0
  self.curDetailed = {}

  self.allSent = 0
  self.allReceived = 0
  self.allDetailed = {}

  self.sentRate = 0
  self.receiveRate = 0
  self.detailedRate = {}

  self.keyPool = {}
  self.pollUpdateStatsInterval = 0.5 -- in seconds
  self:scheduleUpdateStats()
end

-- destroy this module
function MsgEndpoint:destroyStats()
  self:unscheduleUpdateStats()
end

function MsgEndpoint:unscheduleUpdateStats()
  -- logd("mp[%d]: unscheduleUpdateStats handle=%s",
  --   self.id, tostring(self.handleUpdateStats))

  if self.handleUpdateStats then
    scheduler.unschedule(self.handleUpdateStats)
    self.handleUpdateStats = nil
  end
end

function MsgEndpoint:scheduleUpdateStats()
  -- start polling for result
  self:unscheduleUpdateStats()

  self.handleUpdateStats = scheduler.schedule(function ()
    self:updateStats()
  end, self.pollUpdateStatsInterval, false, true)

  -- logd("mp[%d]: scheduleUpdateStats handle=%s",
  --   self.id, tostring(self.handleUpdateStats))
end

function MsgEndpoint:getKey(type, prefix)
  local keyPool = self.keyPool
  local item = keyPool[type]
  local key
  if item then
    key = item[prefix]
    if not key then
      key = string.format('%s-%d', prefix, type)
      item[prefix] = key
    end
  else
    key = string.format('%s-%d', prefix, type)
    item = {}
    item[prefix] = key
    keyPool[type] = item
  end
  return key
end

function MsgEndpoint:recordSent(data, packet)
  local len = string.len(data)
  local key = self:getKey(packet.type, 'out')

  self.curDetailed[key] = self.curDetailed[key] or 0
  self.curDetailed[key] = self.curDetailed[key] + len
  self.curSent = self.curSent + len
end

function MsgEndpoint:recordReceived(data, packet)
  local len = string.len(data)
  local key = nil

  if packet.number == 0 then
    key = self:getKey(packet.type, 'push')
  else
    key = self:getKey(packet.type, 'in')
  end

  self.curDetailed[key] = self.curDetailed[key] or 0
  self.curDetailed[key] = self.curDetailed[key] + len
  self.curReceived = self.curReceived + len
end

function MsgEndpoint:updateStats()
  engine.beginSample('updateStats')

  -- compute rate
  -- clear cur stats and add to all stats
  self.allSent = self.allSent + self.curSent
  allTimeSent = allTimeSent + self.curSent
  self.allReceived = self.allReceived + self.curReceived
  allTimeReceived = allTimeReceived + self.curReceived
  self.sentRate = self.curSent / self.pollUpdateStatsInterval
  self.receiveRate = self.curReceived / self.pollUpdateStatsInterval
  self.curSent = 0
  self.curReceived = 0

  for k, len in pairs(self.curDetailed) do
    if len == 0 then
      self.detailedRate[k] = 0
    else
      self.allDetailed[k] = self.allDetailed[k] or 0
      self.allDetailed[k] = self.allDetailed[k] + len
      allTimeDetailed[k] = allTimeDetailed[k] or 0
      allTimeDetailed[k] = allTimeDetailed[k] + len
      self.detailedRate[k] = self.detailedRate[k] or 0
      self.detailedRate[k] = len / self.pollUpdateStatsInterval
      self.curDetailed[k] = 0
    end
  end

  engine.endSample()
end

function MsgEndpoint:printStats(yield)
  -- return if not inited yet
  if self.id == -1 then return end

  logd('---------------------------------------------------------')
  logd('mp[%d]: current all detailed sent=%d received=%d', self.id, self.allSent, self.allReceived)

  local kvs = self:sortedDetailedStats(self.allDetailed, yield)
  local max = math.min(#kvs, 10)
  for i = 1, max do
    logd('k=%s v=%d', kvs[i][1], kvs[i][2])
  end

  logd('---')
  logd('mp: all time detailed sent=%d received=%d', allTimeSent, allTimeReceived)

  kvs = self:sortedDetailedStats(allTimeDetailed, yield)
  max = math.min(#kvs, 10)
  for i = 1, max do
    logd('k=%s v=%d', kvs[i][1], kvs[i][2])
  end

  logd('---------------------------------------------------------')
end

function MsgEndpoint:sortedDetailedStats(detailed, yield)
  -- select keys that hold current max values
  local kvs = {}
  for k, v in pairs(detailed) do
    table.insert(kvs, {k, v})
  end
  if yield then coroutine.yield() end
  table.sort(kvs, function (a, b) return a[2] > b[2] end)

  return kvs
end

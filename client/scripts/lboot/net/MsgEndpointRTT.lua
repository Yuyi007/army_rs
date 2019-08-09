-- MsgEndpointRTT.lua

--[[
  RTT (Round Trip Time) management related part of the MsgEndpoint class
  All RTT values are in MS (milliseconds)
]]--

local table, ceil = table, math.ceil

-- init this module
function MsgEndpoint:initRTT()
  self.averageRTT = 0
  self.lastRTT = 0

  self.maxFrameTimeSampleNum = 6
  self.frameTimeSamples = {}
  self.totalFrameTime = 0
  self.averageFrameTime = 0
  self.isDroppingFrames = false
end

-- destroy this module
function MsgEndpoint:destroyRTT()
end

-- sample round-trip time

function MsgEndpoint:recordRTT(sendTime, sentPacket)
  -- if it's dropping frames in recent frames, rtt sampled may be larger than actual
  if self.isDroppingFrames then return end

  local now = engine.realtime()
  local timeDiff = now - sendTime
  if timeDiff >= 0 then
    self.lastRTT = timeDiff * 1000
    -- logd("mp[%d]: recordRTT packet=%s lastRTT=%f", self.id, sentPacket:toString(true), self.lastRTT)
    self.averageRTT = 0.7 * self.averageRTT + 0.3 * self.lastRTT
  else
    logw("mp[%d]: recordRTT invalid timeDiff=%f", self.id, timeDiff)
  end
end

function MsgEndpoint:getLastRTT()
  return ceil(self.lastRTT)
end

function MsgEndpoint:getAverageRTT()
  return ceil(self.averageRTT)
end

-- sample frame time

function MsgEndpoint:sampleFrameTime(frameTime)
  -- return if not inited yet
  if self.id == -1 then return end

  local frameTimeSamples = self.frameTimeSamples
  frameTimeSamples[#frameTimeSamples + 1] = frameTime

  local maxSampleNum = self.maxFrameTimeSampleNum
  if #frameTimeSamples > maxSampleNum then
    table.remove(frameTimeSamples, 1)
  end

  self.averageFrameTime = 0.9 * self.averageFrameTime + 0.1 * frameTime

  -- check if it's dropping frames in recent frames
  self.isDroppingFrames = false

  local threshold = 0.2 * self.averageFrameTime
  local nSamples = #frameTimeSamples
  for i = nSamples, (nSamples > maxSampleNum and nSamples - maxSampleNum or 1), -1 do
    local time = frameTimeSamples[i]
    if time - self.averageFrameTime > threshold or time > 75 then
      self.isDroppingFrames = true
      -- logd('mp[%d]: isDroppingFrames i=%d time=%f average=%f', self.id, i, time, self.averageFrameTime)
      return
    end
  end
end

-- Statsd client..
local skynet = require "skynet"
socket  = require "skynet.socket"

local math = require "math"
local os = require "os"


math.randomseed(os.time())

class("StatsdClient", function(self) 
  self.bStats = true
  self.udp = nil
end)
local stClient = StatsdClient

function stClient:init()
  if skynet.getenv("statsd_host") == nil then 
    self.bStats = false 
  else
    self.bStats = true
  end

  self.ns = skynet.getenv("statsd_namespace") or "rs"
  local udpPort = skynet.getenv("udpport") or 6668
  local namespace = self.ns .. ".combat" .. tostring(udpPort) 

  self.host = skynet.getenv("statsd_host") or "127.0.0.1"
  self.port = skynet.getenv("statsd_port") or 8125
  self.namespace  = namespace 
  self.packet_size = 508 --  RFC791

  
  if self.ns ~= "rs" then
    self.udp = socket.udp(function(data, size, from) end)

    socket.udp_connect(self.udp, self.host, self.port)
  else
    self.udp = ".stat"
  end
end

function stClient:send_to_socket(data)
  if self.ns ~= "rs" then
    socket.write(self.udp, data)

    print ("statsd client send data ", data)
  else
    skynet.send(".stat", "lua", "sendData", data)
  end

  return true, ""
end

function stClient:make_statsd_message(stat, delta, kind, sample_rate)
  -- Build prefix
  local prefix = ""

  if self.udp == nil then self:init() end
  if self.namespace ~= nil then prefix = self.namespace.."." end

  -- Escape the stat name
  stat = stat:gsub("[:|@]", "_")

  -- Append the sample rate
  local rate = ""

  if sample_rate ~= 1 then rate = "|@"..sample_rate end

  return prefix..stat..":"..delta.."|"..kind..rate
end

function stClient:send(stat, delta, kind, sample_rate, neg)
  local packet_size = packet_size

  local msg
  local stat_type = type(stat)
  if stat_type == 'table' then sample_rate = delta end
  sample_rate = sample_rate or 1
  if not (sample_rate == 1 or math.random() <= sample_rate) then
    return
  end

  if stat_type == 'table' then
    local t, size = {}, 0
    for s, v in pairs(stat) do
      if kind == 'c' then
        if type(s) == 'number' then
          -- this is array or kyes ( increment{'register', 'register_accept'})
          s, v = v, 1
        end
        v = neg and -v or v
      end
      msg = self:make_statsd_message(s, v, kind, sample_rate)
      size = size + #msg

      if t[1] and (size > packet_size) then
        local msg = table.concat(t, "\n")
        local ok, err = self:send_to_socket(msg)
        if not ok then return nil, err end
        t, size = {}, 0
      end

      t[#t + 1] = msg
    end
    msg = table.concat(t, "\n")
  else
    msg = self:make_statsd_message(stat, delta, kind, sample_rate)
  end

  return self:send_to_socket(msg)
end

-- Record an instantaneous measurement. It's different from a counter in that
-- the value is calculated by the client rather than the server.
function stClient:gauge(stat, value, sample_rate)
  if self.bStats == false then return end

  return self:send(stat, value, "g", sample_rate)
end

function stClient:counter_(stat, value, sample_rate, ...)
  return self:send(stat, value, "c", sample_rate, ...)
end

-- A counter is a gauge whose value is calculated by the statsd server. The
-- client merely gives a delta value by which to change the gauge value.
function stClient:counter(stat, value, sample_rate)
  if self.bStats == false then return end

  return self:counter_(stat, value, sample_rate)
end

-- Increment a counter by `value`.
function stClient:increment(stat, value, sample_rate)
  if self.bStats == false then return end

  return self:counter_(stat, value or 1, sample_rate, false)
end

-- Decrement a counter by `value`.
function stClient:decrement(stat, value, sample_rate)
  if self.bStats == false then return end

  value = value or 1
  if type(stat) == 'string' then value = -value end
  return self:counter_(stat, value, sample_rate, true)
end

-- A timer is a measure of the number of milliseconds elapsed between a start
-- and end time, for example the time to complete rendering of a web page for
-- a user.
function stClient:timer(stat, ms)
  return self:send(stat, ms, "ms")
end

-- A histogram is a measure of the distribution of timer values over time,
-- calculated by the statsd server. Not supported by all statsd implementations.
function stClient:histogram(stat, value)
  return self:send(stat, value, "h")
end

-- A meter measures the rate of events over time, calculated by the Statsd
-- server. Not supported by all statsd implementations.
function stClient:meter(stat, value)
  return self:send(stat, value, "m")
end

-- A set counts unique occurrences of events between flushes. Not supported by
-- all statsd implementations.
function stClient:set(stat, value)
  return self:send(stat, value, "s")
end

return StatsdClient:new()


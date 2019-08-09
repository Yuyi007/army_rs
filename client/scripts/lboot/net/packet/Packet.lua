-- Packet.lua

class('Packet', function (self, length, number, type, encoding, data, part)
  self.length = length
  self.number = number
  self.type = type
  self.encoding = encoding
  self.data = data -- msg encoded
  self.msg = nil -- data decoded
  self.part = nil
end)

Packet.defaultFormat = GenLongPacketFormat

function Packet.parsePacket(packet, data)
  packet = packet or Packet.new()

  if data == nil or string.len(data) < 1 then
    return nil
  end
  
  local format = Packet.defaultFormat
  if format:parse(packet, data) then
    -- logd('parsed packet: %s', packet:toString())
    return packet
  end

  return nil
end

function Packet.generatePacket(packet)
  local format = Packet.defaultFormat
  return format:generate(packet)
end

--

function Packet:reset()
  self:resetData()
  self.part = nil
end

function Packet:resetData()
  self.length = nil
  self.number = nil
  self.type = nil
  self.encoding = nil
  self.data = nil
  self.msg = nil
end

function Packet:toString(simple)
  if self:isValid() then
    if simple then
      return string.format("n=%d len=%d t=%d e=%d", self.number, self.length, self.type, self.encoding)
    elseif self.data then
      return string.format("n=%d len=%d t=%d e=%d data=%s", self.number, self.length, self.type,
        self.encoding, self.data:toHexString())
    elseif self.msg then
      return string.format("n=%d len=%d t=%d e=%d msg=%s", self.number, self.length, self.type,
        self.encoding, tostring(cjson.encode(self.msg)))
    else
      return "<invalid>"
    end
  else
    if simple then
      return string.format("n=%d t=%d", self.number, self.type)
    elseif self.number and self.type and self.msg then
      return string.format("n=%d t=%d msg=%s", self.number, self.type,
        tostring(cjson.encode(self.msg)))
    elseif self.number and self.type and self.data then
      return string.format("n=%d t=%d data=%s", self.number, self.type,
        string.len(self.data))
    else
      return "<invalid>"
    end
  end
end

function Packet:isValid()
  return (self.length and self.number and self.type and self.encoding and (self.data or self.msg))
end

function Packet:parse(data)
  return Packet.parsePacket(self, data)
end

function Packet:generate()
  return Packet.generatePacket(self)
end

function Packet:decode(codec, codecState)
  if self.data then
    codec = codec or ClientEncoding

    -- logd(">>>>>self.number:%s", tostring(self.number))
    -- logd(">>>>self.encoding:%s", tostring(self.encoding))

    if self.number == 0 then
      -- a broadcast message

      self.msg = codec.decode(self.data, self.encoding, codecState)
    else
      -- a response message
      self.msg = codec.decode(self.data, self.encoding, codecState)
    end


    self.data = nil
  else
    logd('Packet.decode: no data field, already decoded? %s %s', self:toString(), debug.traceback())
  end
end

function Packet:encode(codec, codecState)
  if self.msg then
    codec = codec or ClientEncoding
    codecState = self.codecState or codecState
    self.data, self.encoding = codec.encode(self.msg, self.encoding, codecState)
    -- logd(">>>>codec stat:%s self.encoding:%s", inspect(codecState), inspect(self.encoding))
    
    self.msg = nil
  else
    logd('Packet.encode: no msg field, already encoded? %s %s', self:toString(), debug.traceback())
  end
end

function Packet:parseDecode(data, codec, codecState)
  local packet = self:parse(data)
  if packet then
    self:decode(codec, codecState)
  end
  return packet
end

function Packet:generateEncode(codec, codecState)
  self:encode(codec, codecState)
  return self:generate()
end

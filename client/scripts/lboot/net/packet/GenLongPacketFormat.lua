-- GenLongPacketFormat.lua

--[[
GenLongPacketFormat Wire format:
  ------------------------------------------------------------------------------
  | length | message_number | message_type | encoding_type |message_serialized |
  ------------------------------------------------------------------------------
  |    4   |      4         |       2      |       1       |    length - 7    |
  ------------------------------------------------------------------------------
]]--

class('GenLongPacketFormat', function (self)
end)

function GenLongPacketFormat:parse(packet, data)
  local header = nil
  local i = 1
  i, packet.length = string.unpack(data, '>I', i)
  if packet.length then
    local payloadLen = packet.length - 7
    i, packet.number, packet.type, packet.encoding, packet.data =
      string.unpack(data, '>I>HbA' .. payloadLen, i)
      -- logd(">>>packet.number:%s", tostring(packet.number))
      -- logd(">>>packet.type:%s", tostring(packet.type))
      -- logd(">>>packet.encoding:%s", tostring(packet.encoding))
      -- logd(">>>packet.data:%s", tostring(packet.data))
    if packet:isValid() then
      if string.len(data) >= i then
        packet.part = string.sub(data, i)
      else
        packet.part = nil
      end
      return true
    else
      packet.part = data
    end
  end

  return nil
end

function GenLongPacketFormat:generate(p)
  p.length = string.len(p.data) + 7
  return string.pack('>I>I>HbA', p.length,
    p.number, p.type, p.encoding, p.data)
end

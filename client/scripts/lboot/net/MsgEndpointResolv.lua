-- MsgEndpointResolv.lua

function MsgEndpoint:tryResolveAndReplaceHost()
  local chunks = { self.host:match("(%d+)%.(%d+)%.(%d+)%.(%d+)") }
  if (#chunks ~= 4) then
    require 'lboot/net/socket/dns2'
    local ip = socket.dns2.resolve(self.host)
    if ip then
      logd('replacing host to ip: ' .. tostring(self.host) .. ' -> ' .. tostring(ip))
      self.host = ip
      return ip
    else
      logd('no dns result for %s', tostring(self.host))
    end
  end

  return nil
end
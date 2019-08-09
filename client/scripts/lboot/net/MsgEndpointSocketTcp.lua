-- MsgEndpointTcpConn.lua

--[[
  Tcp connection
]]--

function MsgEndpoint:initTcpConn()
  self.conn = nil
  self.tcpNoDelay = (self.tcpNoDelay ~= nil and self.tcpNoDelay or true)

  logd('mp[%d]: init tcp socket no. %d', self.id, self.id)
end

function MsgEndpoint:destroyTcpConn()
  self.conn = nil
end

function MsgEndpoint:closeTcpConn()
  if self.conn then
    self.conn:shutdown()
    self.conn:close()
    self.conn = nil
  end
end

function MsgEndpoint:connectTcp()
  local connMsg
  self.conn, connMsg = socket.getconn(self.host)

  if self.conn ~= nil then
    logd('mp[%d]: tcp socket created', self.id)

    self.conn:settimeout(self.connectTimeout)
    self.conn:setoption('tcp-nodelay', self.tcpNoDelay)

    local res, msg = self.conn:connect(self.host, self.port)

    if res == 1 then
      logd('mp[%d]: tcp connected to %s:%d', self.id, self.host, self.port)
      return true
    else
      logd('mp[%d]: tcp connect failed: %s', self.id, tostring(msg))
      self.conn = nil
    end
  else
    logd('mp[%d]: cannot create tcp socket: %s', self.id, tostring(connMsg))
  end

  return false
end

function MsgEndpoint:sendTcp(data)
  -- for large packets (like error diagnostic messages)
  -- it takes time to send
  self.conn:settimeout(self.sendTimeout)

  return self.conn:send(data)
end

function MsgEndpoint:receiveTcp(packet, recvSize)
  self.conn:settimeout(0)

  -- NOTE that according to implementation of LuaSocket, receive always returns
  -- strings for received data and partial data, even if it's empty.
  return self.conn:receive(recvSize, packet.part)
end

function MsgEndpoint:getLocalIp()
  if self.conn == nil then
    return nil
  else
    local name = self.conn:getsockname()
    return name
  end
end

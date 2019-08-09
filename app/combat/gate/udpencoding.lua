require "lfractor"
local msgpack = require "cmsgpack"
local lxyssl = require "lxyssl"


class("UdpEncoding", function(self) end)

local m = UdpEncoding

m.key = "!@#%$SFG2esxi09w&()^>?"

function m.decryptRc4(text)
  return lxyssl.rc4(m.key):crypt(text)
end

function m.encryptRc4(text)
  return lxyssl.rc4(m.key):crypt(text)
end


function m.encode(msg)
	local buf = msgpack.pack(msg)
	local encrypted = m.encryptRc4(buf)
	return encrypted
end


function m.decode(data)
	local decrypted = m.decryptRc4(data)
	--print(">>>>>>>>decode data:", tostring(decrypted))
	local msg = msgpack.unpack(decrypted)
	--print(">>>>>>>>decoded:", inspect(msg))
	return msg
end


local msgpack = _G['cmsgpack']
local lxyssl = _G['lxyssl']

class("CombatMsgEncoding", function(self) end)

local m = CombatMsgEncoding

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
	local msg = msgpack.unpack(decrypted)
	return msg
end



package.cpath = "luaclib/?.so;fcgi/?.so"
package.path = "lualib/?.lua;fcgi/?.lua;"

if _VERSION ~= "Lua 5.3" then
	error "Use lua 5.3"
end

local config = require "config"
local fcgi = require "lfcgi"

local socket = require "luasocket"
local msgencoding  = require "msgencoding"

local host = msgencoding:host()
local request = host:attach()

local addr = config.addr
local port = config.port
local sock = nil

local function connect()
	if sock then return true end

	sock = assert(socket.tcp())
	local ret, err = sock:connect(addr, port)
	if not err then
		sock:settimeout(0)
		return true
	end
	return false
end

local function send_package(pack)
	if not connect() then return end

	local package = string.pack(">s2", pack)
	local ret, err, _ = sock:send(package)
	if err == 'closed' then
		sock = nil
		return false
	end
	return true
end

local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end

	return text:sub(3,2+s), text:sub(3+s)
end

local function recv_package(last)
	if not sock then return nil, last, nil end

	local result
	result, last = unpack_package(last)
	if result then
		return result, last, nil
	end

	local ret, err, partial = sock:receive('*a')
		
	if err == "closed" then
		sock = nil
		return nil, last, err
	end

	if not partial or partial == '' then
		return nil, last, nil
	end

	return unpack_package(last .. partial)
end

local last = ""
local function dispatch_package()
	local ret = ""
	while true do
		local v, err
		v, last, err = recv_package(last)
		if err == 'closed' then
			break
		end

		if v then
			local t, session, res = host:dispatch(v)
			if res then
				ret = res['result']
				if not ret then
					ret = ""
				else
					ret = string.gsub(ret, "\"", '"')
					ret = ret..'\n'
				end
			end
			break
		end
	end
	return ret
end

local session = 0

local function send_request(name, args)
	session = session + 1
	local str = request(name, args, session)
	return send_package(str)
end


--[[ test
send_request("set", { what = "hello", value = "world" })
send_request("set", { what = "integer", value = 100 })
send_request("set", { what = "my", value = "我 去 哈哈 wewer 12312321!@#$%^&*()" })
send_request("get", {what = "hello"})

send_request("get", {what = "hello"})
sock:close()
data = dispatch_package()
]]

local function processRequest(params)
	if not params then return "" end

	local data = ""
	local suc = send_request("forwardcmd", {args=params})
	if suc then
		data = dispatch_package()
	end
	return data
end

local function processResponse(data)
	local status = "HTTP/1.1 200 OK \n"
	local res = status
	local dataLen = "Content_Leghth:"..fcgi.datalen(data).."\n"
	local dataType = "Content-type: application/json\n\n"
	res = res..dataLen
	res = res..dataType
	res = res..data
	fcgi.response(res)
	fcgi.finish()
end

--connect()
--local data = processRequest("{\"cmd\":\"set\",\"what\":\"hello\",\"value\":\"world\"}")
--processResponse(data)

while fcgi.accept()>=0 do
	local params = fcgi.getdata()
	local data = processRequest(params)
	processResponse(data)
end

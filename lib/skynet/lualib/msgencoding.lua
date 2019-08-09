local core = require "cmsgpack"
local assert = assert

MsgEncoding = {}
local host = {}

local host_mt = { __index = host }

function MsgEncoding:host()
  local obj = {
    __proto = self,
    __session = {},
  }
  return setmetatable(obj, host_mt)
end

MsgEncoding.pack = core.pack
MsgEncoding.unpack = core.unpack

local function gen_msg(name, type, session, content)
  local res = {}
  res['header'] = {name=name, type=type, session=session}
  res['content'] = content
  return res
end

local function gen_response(name, session)
  return function(args)
    local res = gen_msg(name, 1, session, args)
    --local res = {}
    --res['header'] = {name=name, type=1, session=session}
    --res['content'] = args
    return core.pack(res)
  end
end

local function print_tbl(tbl, deep)
  deep = deep + 1
  if type(tbl) == 'table' then
    for k, v in pairs(tbl) do
      local str = ""
      for i = 1, deep do
        str = str .. " "
      end
      --str = str .. "------- k:" .. tostring(k) .. " v:" .. tostring(v)
      print(str)
      print_tbl(v, deep)
    end
  end
end

function host:dispatch(...)
  local res = core.unpack(...)

  --print_tbl(res, 0)

  if type(res.header.type) == 'number' then
    res.header.type = math.floor(res.header.type)
  end

  if type(res.header.session) == 'number' then
    res.header.session = math.floor(res.header.session)
  end
----------------
  if res.header.type == 0 then
    if res.header.session then
      return "REQUEST", res.header.name, res.content, gen_response(res.header.name, res.header.session)
    else
      return "REQUEST", res.header.name, res.content
    end
  else
    -- response
    local session = assert(res.header.session, "session not found")
    local response = assert(self.__session[session], "Unknown session")
    self.__session[session] = nil

    return "RESPONSE", session, res.content
  end
end

function host:attach()
  return function(name, args, session)
    if session then
      self.__session[session] = true
    end

    args = args or {}
    local res = gen_msg(name, 0, session, args)
    return core.pack(res)
  end
end

return MsgEncoding

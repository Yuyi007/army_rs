--[[
  retrieve string from string table and format it with parameters
  example: loc('str_days_ago', days)
  or get the name of anything with its tid
  example: heroName = loc('HC203'); itemName = loc('ID001')
  or just format a string
  example: loc('%s级', 12) => '12级'
--]]

class('loc')

local m  = loc
local st = nil
local mt = {}
local string = string
local table = table
local unity = unity

local doLocStr = function(strId)
  --  avoid dynamic strings to populate string db cache
  if strId and string.match(strId, '^%a[%w_]*$') then
    return st[strId]
  else
    return nil
  end
end

mt.__call = function(t, strId, a1, a2, a3, a4, a5, a6)
  unity.beginSample('loc.__call')

  if not st then m.init() end
  if not strId then
    unity.endSample()
    return ''
  end
  if type(strId) ~= 'string' then
    unity.endSample()
    return tostring(strId)
  end
  if not st then
    unity.endSample()
    return strId
  end

  if a6 then
    unity.endSample()
    error('loc only support 5 args!')
  end
  local argNum = 0
  if a5 then argNum = 5; a5 = doLocStr(a5) or a5 end
  if a4 then argNum = 4; a4 = doLocStr(a4) or a4 end
  if a3 then argNum = 3; a3 = doLocStr(a3) or a3 end
  if a2 then argNum = 2; a2 = doLocStr(a2) or a2 end
  if a1 then argNum = 1; a1 = doLocStr(a1) or a1 end

  local res = ''
  local strIdConverted = doLocStr(strId)
  if strIdConverted then
    if argNum > 0 then
      local status
      status, res = pcall(string.format, strIdConverted, a1, a2, a3, a4, a5)
      if not status then res = strIdConverted end
    else
      res = strIdConverted
    end
  else
    if argNum > 0 then
      local status
      status, res = pcall(string.format, strId, a1, a2, a3, a4, a5)
      if not status then res = strId end
    else
      res = strId
    end
  end

  unity.endSample()
  return res
end

setmetatable(m, mt)

local json = cjson

function m.preinit()
  local cfg = rawget(_G, 'cfg')
  if cfg and cfg.strings then
    st = cfg.strings
  end
end

function m.init()
  m.preinit()
end

function m.unicodeChars(unicodeString)
  local chars = {}
  for uchar in string.gfind(unicodeString, "([%z\1-\127\194-\244][\128-\191]*)") do
    table.insert(chars, uchar)
  end

  return chars
end

function m.trimString(unicodeString, length)
  local cnt = 0
  local result = {}
  for i, s in ipairs(m.unicodeChars(unicodeString)) do
    if #s > 1 then
      cnt = cnt + 2
    else
      cnt = cnt + 1
    end
    if cnt <= length then
      result[#result + 1] = s
    end
  end

  if cnt > length then
    result[#result + 1] = '...'
  end

  return table.concat(result)
end

function m.fixExplicitLineBreaks(str)
  return str .. string.rep(' ', string.count(str, '\n'))
end

function m.color(colorStr, str)
  return string.format('<color=%s>%s</color>', colorStr, loc(str))
end

function m.lines(...)
  return table.concat({...}, '\n')
end

function m.join(...)
  return table.concat({...}, '')
end







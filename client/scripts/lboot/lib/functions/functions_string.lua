
function string.split(str, sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    string.gsub(str, pattern, function(c) fields[#fields+1] = c end)
    return fields
end

function string.capitalize(str)
if str == nil then return nil end
  local len = string.len(str)
  if len <= 0 then return str end
  local ch = string.sub(str, 1, 1)
  if ch < 'a' or ch > 'z' then
    return str
  end
  ch = string.char(string.byte(ch) - 32)
  if len == 1 then
    return ch
  else
    return ch .. string.sub(str, 2, len)
  end
end

function string:at(idx)
  return string.sub(self, idx, idx)
end

function string:first()
  return string.sub(self, 1, 1)
end

function string:last()
  local len = string.len(self)
  return string.sub(self, len, len)
end

function string:tohex()
  return (self:gsub(".", function (x)
   return ("%02x"):format(x:byte())
  end))
end

function string:toHexString(sep)
  sep = sep or ','
  return (self:gsub(".", function (x)
   return string.format("%s%s", ("%02x"):format(x:byte()), sep)
  end))
end

function string:toIntegerString(sep)
  sep = sep or ','
  local n = string.len(self)
  local i = 1
  local byte
  local bytes = {}
  while i <= string.len(self) do
    i, byte = string.unpack(self, 'b', i)
    table.insert(bytes, byte)
  end
  return table.concat(bytes, sep)
end

function string:rfind(pattern, init, plain)
  local r = string.reverse(self)
  local k = r:find(pattern, init, plain)
  if k then
    return string.len(self) - k + 1
  else
    return nil
  end
end

function string.pack_package(text)
  if text == nil then
    return ""
  end
  local size = #text
  if size <= 0 then
    return ""
  end
  local c1 = math.floor(size/256)
  local c2 = size%256
  text = string.char(c1) .. string.char(c2) .. text
  return text
end

function string.strip(s)
  return s:gsub("^%s+", ""):gsub("%s+$", "")
end

function string.unpack_package(text)
  if text == nil then
    return nil, nil
  end
  local size = #text
  if size <= 1 then
    return nil, nil
  end
  local c1 = string.sub(text, 1, 1)
  local c2 = string.sub(text, 2, 2)
  local text = string.sub(text, 3, #text)
  local len = string.byte(c1) * 256 + string.byte(c2)
  return len, text
end

local utf8 = require 'utf8'

function string.utf8sub(str, startChar, numChars)
  return utf8.sub(str, startChar, numChars)
end

function string.utf8len(str)
  return utf8.len(str)
end

function string.utf8MakeShort(str, len)
  if utf8.len(str) > len then
    return utf8.sub(str, 1, len) .. '...'
  else
    return str
  end
end

function string.utf8trim(str, len)
  if utf8.len(str) > len then
    return utf8.sub(str, 1, len)
  else
    return str
  end
end

function string.utf8Escape(str)
  return utf8.escape(str)
end


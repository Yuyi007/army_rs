-- functions-debug.lua

function vardump(value, depth, key)
  local linePrefix = ""
  local spaces = ""

  if key ~= nil then
    linePrefix = "["..key.."] = "
  end

  if depth == nil then
    depth = 0
  else
    depth = depth + 1
    for i=1, depth do spaces = spaces .. "  " end
  end

  if type(value) == 'table' then
    local mTable = getmetatable(value)
    if mTable == nil then
      print(spaces ..linePrefix.."(table) ")
    else
      print(spaces .."(metatable) ")
        value = mTable
    end
    for tableKey, tableValue in pairs(value) do
      vardump(tableValue, depth, tableKey)
    end
  elseif type(value)  == 'function' or
      type(value) == 'thread' or
      type(value) == 'userdata' or
      value   == nil
  then
    print(spaces..tostring(value))
  else
    print(spaces..linePrefix.."("..type(value)..") "..tostring(value))
  end
end

-- counts table
table.debugCounts = function(self)
  local n = function (t, k)
    local name = type(t)
    if name == 'table' then
      local classname = rawget(t, 'classname')
      if classname then
        name = 'class'
      else
        local cls = rawget(t, 'class')
        if cls and type(cls) == 'table' and rawget(cls, 'classname') then
          name = rawget(cls, 'classname')
        end
      end
    elseif name == 'function' then
      if string.find(k, 'SelectorProxy_', 1, true) == 1 then
        name = 'function (SelectorProxy)'
      end
    end
    return name
  end

  local counts = Ordered()
  local f = function(t, k)
    local name = n(t, k)
    counts[name] = (counts[name] or 0) + 1
  end

  local seen = {}
  local d
  d = function(t, k)
    if seen[t] then return end
    f(t, k)
    seen[t] = true
    for k1, v in pairs(t) do
      if type(v) == "table" then
        d(v, k1)
      elseif type(v) == 'number' then
        f(v, k1)
      elseif type(v) == 'string' then
        f(v, k1)
      elseif type(v) == 'function' then
        f(v, k1)
      elseif type(v) == "userdata" then
        f(v, k1)
      else
        f(v, k1)
      end
    end
  end

  d(self, '')
  for k, v in opairs(counts) do
    print(k .. ': ' .. v)
  end
end

-- find references of specified class
function table.debugReferences(self, classname)
  local n = function (t, k)
    local name = type(t)
    if name == 'table' then
      local classname = rawget(t, 'classname')
      if classname then
        name = 'class'
      else
        local cls = rawget(t, 'class')
        if cls and type(cls) == 'table' and rawget(cls, 'classname') then
          name = rawget(cls, 'classname')
        end
      end
    end
    if k then
      name = name .. '(' .. k .. ')'
    end
    return name
  end

  local seen = {}
  local d
  d = function(t, k)
    if seen[t] then return end
    seen[t] = true
    for k1, v in pairs(t) do
      if type(v) == "table" then
        if n(v) == classname then
          print(n(t, k) .. '.' .. n(v, k1))
        else
          d(v, k1)
        end
      end
    end
  end

  d(self, classname)
end

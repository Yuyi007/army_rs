
class('StructureData', function (self)
  -- Enable this only in development to avoid field access overhead
  -- Comment it out in production
  if game.debug > 0 then
    StructureData.lockFields(self, self.class, self.class.allFields)
  end
end)

local m = StructureData

function m.init()
end

function m:reopenInit()
end

function m:reopenExit()
end

function m:reset()
  for _, v in pairs(self.class.allFields) do
    self[v] = nil
  end
end


function m.fromData(data)
  return nil
end

function m.toFighterData(data)
  local d = fromData(data)
  if d then
    return d:toFighterData()
  else
    return nil
  end
end

function m:toFighterData()
  return nil
end

function m.lockFields(self, clz, fields)
  local fieldsLookup = {
    class = true,
    classname = true,
    lockFields = true,
    copyData = true,
    reopenInit = true,
    reopenExit = true,
    reset      = true,
    toFighterData = true,
    fromData = true,
    init = true,
  }
  for i = 1, #fields do
    fieldsLookup[fields[i]] = true
  end

  local mt = getmetatable(self)
  mt.__newindex = function (t, name, v)
    if fieldsLookup[name] then
      rawset(t, name, v)
    else
      error(string.format('You are declaring an undefined variable %s for structure %s',
        name, clz.classname))
    end
  end
  mt.__index = function (t, name)
    if fieldsLookup[name] then
      local o = rawget(t, name)
      if o then return o end
      local tClass = rawget(t, 'class')
      if tClass then return rawget(tClass, name) end
      return nil
    else
      error(string.format('You are reading an undefined variable %s for structure %s',
        name, clz.classname))
    end
  end
end

-- copy from self to data
function m.copyData(self, data)
  data = data or {}
  for _, k in pairs(self.class.allFields) do
    data[k] = self[k]
  end
  return data
end

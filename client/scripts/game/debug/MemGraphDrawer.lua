
class('MemGraphDrawer')

local m = MemGraphDrawer

function m.startDraw(parent, x, y, width, height)
  if m.drawHandle then return end

  m.drawHandle = coroutineStart(function (delta)
    m.graph = BarGraph.new(parent, {x=x, y=y, width=width, height=height})
    m.graph:init()
    coroutine.yield()

    while true do
      local memResult = m.traverseMemory(true)
      m.drawMemGraph(memResult)
      coroutine.yield()
    end
  end, 0, {global=false})
end

function m.stopDraw()
  if m.drawHandle then
    scheduler.unschedule(m.drawHandle)
    m.drawHandle = nil
    m.graph:exit()
    m.graph = nil
  end
end

m.trackTypes = {
  -----------------------------------
  -- [class track types]
  -----------------------------------
  -- MainSceneView = true,
  -- InteriorSceneView = true,
  -- MainUIView = true,
  -- CutsceneInstance = true,
  -- MainScenePlayer = true,
  -- MainSceneModel = true,
  -- NormalNpc = true,
  -- NpcModel = true,
  -- DialogNpc = true,
  -- InteractableNpc = true,
  -- GhostNpc = true,
  -- EnemyNpc = true,
  -- NpcNearEffect = true,
  -- AvatarCustomizer = true,
  -- UVAnimator = true,
  -- Navigator = true,
  -- AnimParticlePlayer = true,
  -- TableViewController = true,
  -- PveFightScene = true,
  -- CombatUIView = true,
  -- CombatFighter3D = true,
  -- FighterModel = true,
  -- BotFighter3D = true,
  -- BotFighterModel = true,
  -- Projectile3D = true,
  -- ProjModel = true,
  -- CombatMessenger = true,
  -- FighterActor = true,
  -- SimpleRoamActor = true,
  -- ProjectileActor = true,
  -- NoneActor = true,
  -- ParticleView = true,
  -----------------------------------

  -----------------------------------
  -- [user data track types]
  -----------------------------------
  -- ['unity:GameObject'] = true,
  -- ['unity:Transform'] = true,
  -----------------------------------

  -----------------------------------
  -- [preliminary track types]
  -----------------------------------
  ['nil'] = true,
  ['boolean'] = true,
  ['number'] = true,
  ['string'] = true,
  ['userdata'] = true,
  ['function'] = true,
  ['thread'] = true,
  ['table'] = true,
  -----------------------------------
}

function m.traverseMemory(yield, ignores)
  luagc()

  -- logd('traverse memory start')
  local trackTypes = m.trackTypes
  local trackFile = nil
  if trackTypes then
    trackFile = m.openTrackFile()
  end

  local i = 0
  local res = {}
  local visited = {}
  local memResult = {total = 0, sorted = {}}
  local f = function(from, to, how, value, path)
    if visited[to] then return end
    visited[to] = true

    local typeName = nil
    local size = 0

    -- if how == 'key' then
      local t = type(to)
      if t == 'table' then
        local cls = rawget(to, 'class')
        if type(cls) == 'table' then
          typeName = tostring(rawget(cls, 'classname'))
        end
      elseif t == 'function' then
        typeName = 'function'
      elseif t == 'thread' then
        typeName = 'thread'
      elseif t == 'string' then
        typeName = 'string'
      elseif t == 'userdata' then
        local mt = getmetatable(to)
        if type(mt) == 'table' then
          local __typename = rawget(mt, '__typename')
          if __typename then
            typeName = 'unity:' .. __typename
          else
            typeName = 'userdata:plain'
          end
        else
          typeName = 'userdata:mt['.. type(mt) ..']'
        end
        -- logd('typename: %s userdata: %s', typeName, tostring(to))
      end
    -- end

    if typeName then
      res[typeName] = res[typeName] or {
        typeName = typeName,
        count = 0,
        size = 0,
      }
      local info = res[typeName]
      local size = estimateNumOfBytes(to, t)
      info.count = info.count + 1
      info.size = info.size + size

      if trackTypes and (trackTypes[typeName] or trackTypes[t]) then
        if trackFile then
          local inObjTable = string.match(path, '.objTable.')
          if not inObjTable then
            if t == 'nil' then
              m.writeTrackTypeNil(trackFile, typeName, t, from, to, how, value, path, size)
            elseif t == 'boolean' then
              m.writeTrackTypeBoolean(trackFile, typeName, t, from, to, how, value, path, size)
            elseif t == 'number' then
              m.writeTrackTypeNumber(trackFile, typeName, t, from, to, how, value, path, size)
            elseif t == 'string' then
              m.writeTrackTypeString(trackFile, typeName, t, from, to, how, value, path, size)
            elseif t == 'userdata' then
              m.writeTrackTypeUserdata(trackFile, typeName, t, from, to, how, value, path, size)
            elseif t == 'function' then
              m.writeTrackTypeFunction(trackFile, typeName, t, from, to, how, value, path, size)
            elseif t == 'thread' then
              m.writeTrackTypeThread(trackFile, typeName, t, from, to, how, value, path, size)
            elseif t == 'table' then
              m.writeTrackTypeTable(trackFile, typeName, t, from, to, how, value, path, size)
            else
              error('unknown type t')
            end
          end
        else
          logd('found %s: path=%s', typeName, tostring(path))
        end
      end
    end

    i = i + 1
    if yield and i % 2500 == 0 then coroutine.yield() end
  end

  local ignoreobjs = {visited, res, memResult, f}
  if yield then
    local co, main = coroutine.running()
    table.insert(ignoreobjs, co)
  end
  if ignores then
    for i = 1, #ignores do local v = ignores[i]
      table.insert(ignoreobjs, v)
    end
  end

  -- peekSchedulerData()

  if trackFile then
    gc.traverseG({edge=f}, ignoreobjs, true)
    gc.traverseRegistry({edge=f}, ignoreobjs, true)
    m.closeTrackFile(trackFile)
  else
    gc.traverseG({edge=f}, ignoreobjs, false)
  end

  if yield then coroutine.yield() end

  -- logd('traverse memory end')
  i = 0
  for k, v in pairs(res) do
    memResult.total = memResult.total + v.size
    table.insert(memResult.sorted, v)

    i = i + 1
    if yield and i % 2000 == 0 then coroutine.yield() end
  end
  if yield then coroutine.yield() end

  table.sort(memResult.sorted, function (a, b) return a.size > b.size end)
  if yield then coroutine.yield() end

  if trackFile then
    logd('memResult.sorted=%s', inspect(memResult.sorted))
  end
  -- logd('analyse memory end')

  return memResult
end

function m.openTrackFile()
  local fileRoot = nil
  if game.platform == 'editor' then
    fileRoot = '/tmp'
  elseif game.platform == 'android' then
    fileRoot = '/sdcard/race'
  else
    return nil
  end

  if not m.fileNo then m.fileNo = 1 end
  local fileName = fileRoot .. '/ddd-' .. m.fileNo .. '.txt'
  local file = io.open(fileName, 'w+')
  m.fileNo = m.fileNo + 1
  logd('Track file opened: %s', fileName)
  return file
end

function m.closeTrackFile(file)
  file:close()
  logd('Track file closed')
end

function m.writeTrackTypeNil(file, typeName, toType, from, to, how, value, path, size)
  file:write(tostring(path))
  file:write(' (nil): ')
  file:write(' size=')
  file:write(size)
  file:write(' from=')
  file:write(m.safeTostring(from))
  file:write('\n')
end

function m.writeTrackTypeBoolean(file, typeName, toType, from, to, how, value, path, size)
  file:write(tostring(path))
  file:write(' (boolean): ')
  file:write(to)
  file:write(' size=')
  file:write(size)
  file:write(' from=')
  file:write(m.safeTostring(from))
  file:write('\n')
end

function m.writeTrackTypeNumber(file, typeName, toType, from, to, how, value, path, size)
  file:write(tostring(path))
  file:write(' (number): ')
  file:write(to)
  file:write(' size=')
  file:write(size)
  file:write(' from=')
  file:write(m.safeTostring(from))
  file:write('\n')
end

function m.writeTrackTypeString(file, typeName, toType, from, to, how, value, path, size)
  file:write(tostring(path))
  file:write(' (string): ')
  file:write(to)
  file:write(' size=')
  file:write(size)
  file:write(' from=')
  file:write(m.safeTostring(from))
  file:write('\n')
end

function m.writeTrackTypeUserdata(file, typeName, toType, from, to, how, value, path, size)
  file:write(tostring(path))
  file:write(' (userdata) (')
  file:write(typeName)
  file:write(') : to=')
  file:write(m.safeTostring(to))
  file:write(' size=')
  file:write(size)
  file:write(' from=')
  file:write(m.safeTostring(from))
  file:write('\n')
end

function m.writeTrackTypeFunction(file, typeName, toType, from, to, how, value, path, size)
  file:write(tostring(path))
  file:write(' (function): ')
  file:write(peek(debug.getinfo(to, 'S')))
  file:write('\n')
  local i = 1
  while true do
    local n, v = debug.getupvalue(to, i)
    if not n then break end
    file:write('upvalue ')
    file:write(i)
    file:write(': ')
    file:write(m.safeTostring(v))
    file:write('\n')
    i = i + 1
  end
  file:write(' size=')
  file:write(size)
  file:write(' from=')
  file:write(m.safeTostring(from))
  file:write('\n')
end

function m.writeTrackTypeThread(file, typeName, toType, from, to, how, value, path, size)
  file:write(tostring(path))
  file:write(' (thread): ')
  file:write(' size=')
  file:write(size)
  file:write(' from=')
  file:write(m.safeTostring(from))
  file:write('\n')
end

function m.writeTrackTypeTable(file, typeName, toType, from, to, how, value, path, size)
  file:write(tostring(path))
  file:write(' (table) (')
  file:write(typeName)
  file:write(') : to=')
  file:write(m.safeTostring(to))
  file:write(' \n')
  local keyNum = 0
  for k, v in pairs(to) do
    file:write(k)
    file:write(' ')
    -- file:write(tostring(v))
    keyNum = keyNum + 1
  end
  file:write(' size=')
  file:write(size)
  file:write(' keys=')
  file:write(keyNum)
  file:write(' from=')
  file:write(m.safeTostring(from))
  file:write('\n')
end

function  m.safeTostring(obj)
  local ok, res = pcall(tostring, obj)
  return res
end

function m.drawMemGraph(result)
  if not result then return end

  for i = 1, #result.sorted do local v = result.sorted[i]
    if i > m.graph.barNum then break end

    local percent = 100.0 * v.size / result.total
    local text = string.format("%s %.1f %d", v.typeName, v.size / 1024 / 1024, v.count)

    m.graph:updateBar(i, percent, text)
  end
end

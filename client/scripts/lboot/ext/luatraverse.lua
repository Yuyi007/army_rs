-------------------------------------------------------------------------------
-- This module implements a function that traverses all live objects.
-- You can implement your own function to pass as a parameter of traverse
-- and give you the information you want. As an example we have implemented
-- countreferences and findallpaths
--
-- Alexandra Barros - 2006.03.15
-------------------------------------------------------------------------------

module("gc", package.seeall)

local List = {}

function List.new ()
  return {first = 0, last = -1}
end

function List.push (list, value)
  local last = list.last + 1
    list.last = last
    list[last] = value
end

function List.pop (list)
    local first = list.first
    if first > list.last then error("list is empty") end
    local value = list[first]
    list[first] = nil
    list.first = first + 1
    return value
end

function List.isempty (list)
  return list.first > list.last
end

-- Counts all references for a given object
function countreferences(value)
  local count = -1
  local f = function(from, to, how, v)
    if to == value then
      count = count + 1
    end
  end
  traverse({edge=f}, {count, f})
  return count
end

-- Prints all paths to an object
function findallpaths(obj)

  local comefrom = {}
  local f = function(from, to, how, value)
    if not comefrom[to] then comefrom[to] = {} end
    table.insert(comefrom[to], 1, {f = from, h = how, v=value})
  end

  traverse({edge=f}, {comefrom, f})


  local function printpath(to)
    if not to or comefrom[to].visited or to == _G then
      print("-----")
      return
    end
    comefrom[to].visited = true
    for i=1, #comefrom[to] do
      local tfrom = comefrom[to][i].f
      print("from: ", tfrom, "\nhow:", comefrom[to][i].h,
          "\nvalue:", comefrom[to][i].v)
      printpath(tfrom)
    end
  end

  printpath(obj)

end

function traverseG(funcs, ignoreobjs, withpath)
  return traverse(_G, '_G', funcs, ignoreobjs, withpath)
end

function traverseRegistry(funcs, ignoreobjs, withpath)
  return traverse(debug.getregistry(), 'reg', funcs, ignoreobjs, withpath)
end

-- Main function
-- 'funcs' is a table that contains a funcation for every lua type and also the
-- function edge edge (traverseedge).
function traverse(rootTable, rootTableName, funcs, ignoreobjs, withpath)

  -- The keys of the marked table are the objetcts (for example, table: 00442330).
  -- The value of each key is true if the object has been found and false
  -- otherwise.
  local env = {marked = {}, list=List.new(), funcs=funcs, withpath=withpath}

  if ignoreobjs then
    for i=1, #ignoreobjs do
      env.marked[ignoreobjs[i]] = true
    end
  end

  env.marked["gc"] = true
  env.marked[gc] = true

  local path = withpath and rootTableName or nil

  -- marks and inserts on the list
  edge(env, nil, rootTableName, "isname", nil, path)
  edge(env, nil, rootTable, "key", rootTableName, path)

  -- traverses the active thread
  -- inserts the local variables
  -- interates over the function on the stack, starting from the one that
  -- called traverse
  path = withpath and rootTableName .. '.local' or nil
  for i=2, math.huge do
    local info = debug.getinfo(i, "f")
    if not info then break end
    for j=1, math.huge do
      local n, v = debug.getlocal(i, j)
      if not n then break end

      edge(env, nil, n, "isname", nil, path)
      edge(env, nil, v, "local", n, path)
    end
  end

  while not List.isempty(env.list) do
    local item = List.pop(env.list)
    local obj, path = unpack(item)
    local t = type(obj)
    gc["traverse" .. t](env, obj, path)

  end

end

local pathConcat = {'', '.', ''}

function traversetable(env, obj, path)

  local f = env.funcs.table
  if f then f(obj) end

  for key, value in pairs(obj) do
    if env.withpath then
      if path then
        local keyType = type(key)
        pathConcat[1] = path
        pathConcat[3] = (keyType == 'string' or keyType == 'number') and key or 'key-' .. keyType
        local path2 = table.concat(pathConcat)
        edge(env, obj, key, "iskey", nil, path2)
        edge(env, obj, value, "key", key, path2)
      else
        edge(env, obj, key, "iskey", nil, 'anon_table')
        edge(env, obj, value, "key", key, 'anon_table')
      end
    else
      edge(env, obj, key, "iskey", nil, nil)
      edge(env, obj, value, "key", key, nil)
    end
  end

  local mtable = debug.getmetatable(obj)
  if mtable then
    if env.withpath then
      local path2 = path and path .. ':table_mt' or 'table_mt'
      edge(env, obj, mtable, "ismetatable", nil, path2)
    else
      edge(env, obj, mtable, "ismetatable", nil, nil)
    end
  end

end

function traversestring(env, obj, path)
  local f = env.funcs.string
  if f then f(obj) end

end

function traverseuserdata(env, obj, path)
  local f = env.funcs.userdata
  if f then f(obj) end

  local mtable = debug.getmetatable(obj)
  if mtable then
    if env.withpath then
      local path2 = path and path .. ':userdata_mt' or 'userdata_mt'
      edge(env, obj, mtable, "ismetatable", nil, path2)
    else
      edge(env, obj, mtable, "ismetatable", nil, nil)
    end
  end

  local fenv = debug.getfenv(obj)
  if fenv then
    if env.withpath then
      local path2 = path and path .. ':userdata_fenv' or 'userdata_fenv'
      edge(env, obj, fenv, "environment", nil, path2)
    else
      edge(env, obj, fenv, "environment", nil, nil)
    end
  end

end

function traversefunction(env, obj, path)
  local f = env.funcs.func
  if f then f(obj) end

  -- gets the upvalues
  local path2 = nil

  local i = 1
  while true do
    local n, v = debug.getupvalue(obj, i)
    if not n then break end -- when there is no upvalues
    if env.withpath then
      path2 = path and path .. (':upvalue-' .. i) or ('upvalue-' .. i)
    end
    edge(env, obj, n, "isname", nil, path2)
    edge(env, obj, v, "upvalue", n, path2)
    i = i + 1
  end

  local fenv = debug.getfenv(obj)
  if env.withpath then
    path2 = path and path .. ':func_fenv' or 'func_fenv'
    edge(env, obj, fenv, "enviroment", nil, path2)
  else
    edge(env, obj, fenv, "enviroment", nil, nil)
  end

end

function traversethread(env, t, path)
  local f = env.funcs.thread
  if f then f(t) end

  local path2 = nil
  if env.withpath then
    path2 = path and path .. ':thread_local' or 'thread_local'
  end

  for i=1, math.huge do
    local info = debug.getinfo(t, i, "f")
    if not info then break end
    for j=1, math.huge do
      local n, v = debug.getlocal(t, i , j)
      if not n then break end
      -- print(n, v)

      edge(env, nil, n, "isname", nil, path2)
      edge(env, nil, v, "local", n, path2)
    end
  end

  local fenv = debug.getfenv(t)
  local path2 = nil
  if env.withpath then
    path2 = path and path .. ':thread_fenv' or 'thread_fenv'
    edge(env, t, fenv, "enviroment", nil, path2)
  else
    edge(env, t, fenv, "enviroment", nil, nil)
  end

end


-- 'how' is a string that identifies the content of 'to' and 'value':
--    if 'how' is "iskey", then 'to' é is a key and 'value' is nil.
--    if 'how' is "key", then 'to' is an object and 'value' is the name of the
--    key.
function edge(env, from, to, how, value, path)

  local t = type(to)

  if to and (t~="boolean") and (t~="number") and (t~="new") then
    -- If the destination object has not been found yet
    if not env.marked[to] then
      env.marked[to] = true
      List.push(env.list, {to, path}) -- puts on the list to be traversed
    end

    local f = env.funcs.edge
    if f then f(from, to, how, value, path) end

  end

end
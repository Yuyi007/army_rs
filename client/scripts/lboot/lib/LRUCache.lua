
class('LRUCache', function(self, maxSize)
  self.hasht = {}
  self.list = LuaList()
  self.maxSize = maxSize
  self.stats = { get = 0, hit = 0 }
end)

function LRUCache:get(name)
  local stats = self.stats
  stats.get = stats.get + 1
  local i = self.hasht[name]
  if i then
    local list = self.list
    list:remove(i)
    list:unshift(i)
    stats.hit = stats.hit + 1
    return i.value, true
  end
  return nil, false
end


function LRUCache:set(name, value)
  local list = self.list
  local hasht = self.hasht
  if list.length >= self.maxSize then
    local r = list:pop()
    hasht[r.name] = nil
  end
  local i = { name = name, value = value }
  hasht[name] = i
  list:unshift(i)
end

function LRUCache:size()
  return self.list.length
end

function LRUCache:hitrate()
  local stats = self.stats
  if stats.get > 0 then
    return (stats.hit + 0.0) / stats.get
  else
    return 0
  end
end

function LRUCache:dump()
  local list = self.list
  logd('LRUCache dump size=%s', list.length)
  local i = 1
  for item in list:iterate() do
    logd('i=%d name=%s value=%s', i, tostring(item.name), tostring(item.value))
    i = i + 1
  end
end

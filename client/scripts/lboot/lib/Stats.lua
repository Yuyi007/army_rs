
class('Stats', function(self)
  self.table = {}
end)

function Stats:increment(name)
  local t = self.table
  t[name] = t[name] or 0
  t[name] = t[name] + 1
  return t[name]
end

function Stats:tostring()
  local s = ''
  for name, value in pairs(self.table) do
    s = s .. ' ' .. name .. '=' .. value
  end
  return s
end
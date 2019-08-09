class("Jsonable", function(self) 
    self.__attrs = {}
    self.__ref_attrs = {}
    self.__tb_attrs = {}
  end)

local m = Jsonable

function m:_attr(attr, def_value)
  self[attr] = def_value
  table.insert(self.__attrs, attr) 
end

function m:_ref_attr(attr, cls)
  self[attr] = cls.new()
  table.insert(self.__attrs, attr) 
  self.__ref_attrs[attr] = {attr = attr, cls = cls}
end

function m:_tb_attr(attr, cls)
  self[attr] = {}
  table.insert(self.__attrs, attr) 
  self.__tb_attrs[attr] = {attr = attr, cls = cls}
end

function m:to_json()
  local data = {}
  for i,v in pairs(self.__attrs) do
    if self.__ref_attrs[v] then
      data[v] = self[v]:to_json()
    elseif self.__tb_attrs[v] then
      local tb = self[v]
      data[v] = {}
      for kt,vt in pairs(tb) do 
        data[v][kt] = vt:to_json()
      end
    else
      data[v] = self[v]
    end
  end
  
  return cjson.encode(data)
end

function m:to_data()
  local data = {}
  for i,v in pairs(self.__attrs) do
    if self.__ref_attrs[v] then
      data[v] = self[v]:to_data()
    elseif self.__tb_attrs[v] then
      local tb = self[v]
      data[v] = {}
      for kt,vt in pairs(tb) do 
        data[v][kt] = vt:to_data()
      end
    else
      data[v] = self[v]
    end
  end
  return data
end

function m:from_data(data)
  assert(data)
  for k,v in pairs(data) do
    local ref = self.__ref_attrs[k]
    if ref then
      self[k] = ref.cls.new()
      self[k]:from_data(v)
    else
      local ref = self.__tb_attrs[k]
      if self.__tb_attrs[k] then
        self[k] = {}
        for kt,vt in pairs(v) do 
          self[k][kt] = ref.cls.new()
          self[k][kt]:from_data(vt)
        end
      else
        self[k] = v
      end
    end
  end
end

function m:from_json(json_str)
  assert(json_str)
  local data = cjson.decode(json_str)
  if data then
    for k,v in pairs(data) do
      local ref = self.__ref_attrs[k]
      if ref then
        self[k] = ref.cls.new()
        self[k]:from_json(v)
      else
        local ref = self.__tb_attrs[k]
        if self.__tb_attrs[k] then
           self[k] = {}
          for kt,vt in pairs(v) do 
            self[k][kt] = ref.cls.new()
            self[k][kt]:from_json(vt)
          end
        else
          self[k] = v
        end
      end
    end
  end
end

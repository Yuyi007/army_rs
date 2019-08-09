
-- clones object
function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function declare(name, initval)
  rawset(_G, name, initval or false)
end

function class(classname, ctor, super)
    local cls
    if super then
        cls = clone(super)
    else
        cls = {}
    end

    if super then
        cls.super = super
        for k, v in pairs(super) do cls[k] = v end
    end

    cls.super     = super
    cls.classname = classname
    cls.ctor      = ctor
    cls.__index   = cls

    local function callctor(o, ctor, super, ...)
        if super then callctor(o, super.ctor, super.super, ...) end
        if ctor then ctor(o, ...) end
    end

    function cls.new(...)
        local o = setmetatable({}, cls)
        o.class = cls
        -- 创建对象实例时，要按照正确的顺序调用继承层次上所有的 ctor 函数
        callctor(o, ctor, super, ...)
        return o
    end

    declare(classname, cls)
    return cls
end

-- returns true if a table is a class [not tested yet!]
function isClass(t)
  if type(t) == 'table' then
    local super_type = type(t.super)
    if (super_type == 'nil' or super_type == 'table') and
      type(t.classname) == 'string' and
      type(t.ctor) == 'function' and
      type(t.new) == 'function' and
      rawget(_G, t.classname) == t and
      t.__index == t then
      return true
    end
  end

  return false
end

-- returns true if class is descendent of a base class
function isDescendentClass(clz, baseClass)
  if type(clz) == 'table' and type(clz.super) == 'table' then
    local basename = baseClass.classname
    while clz.super do
      if clz.super.classname == basename then return true end
      clz = clz.super
    end
  end

  return false
end

-- delegate instance methods to the second object
function delegateTo(first, second)
  local function methodForwarder(table, methodName)
    local method = second.class[methodName]
    if type(method) == 'function' then
      return function (self, ...)
        return method(second, ...)
      end
    end
  end

  setmetatable(getmetatable(first), {
    __index = methodForwarder
  })

  return first
end

function setDelegations(clz, funcs, member)
  for i = 1, #funcs do
    local v = funcs[i]

    clz[v] = function(self, ...)
      local ob = self[member]
      if not ob then return nil end

      local f = ob.class[v]
      if f then
        return f(ob, ...)
      else
        return nil
      end
    end
  end
end

function aliasMethod(clz, toMethod, fromMethod)
  if not clz[toMethod] then
    clz[toMethod] = clz[fromMethod]
  else
    loge('method %s has been defined before, cannot be an alias', toMethod)
  end
end

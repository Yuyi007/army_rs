function declare(name, initval)
  rawset(_G, name, initval or false)
end

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

function xor(b1, b2)
  return (b1 and not b2) or (b2 and not b1)
end

--[[
创建一个新类
**Parameters:**

-   classname: 类名称
-   ctor: 构造函数
-   super: 父类（可选）

**Returns:**

-   class: 新类
]]
function class(classname, ctor, super)
  rawset(_G, classname, false)

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

  setmetatable(cls, {__call = function(t, ...) return t.new(...) end})

  cls.new = function(...)
      local o = setmetatable({}, cls)
      -- 创建对象实例时，要按照正确的顺序调用继承层次上所有的 ctor 函数
      callctor(o, ctor, super, ...)
      o.class = cls
      o.classname = classname
      return o
  end

  rawset(_G, classname, cls)
  return cls
end

function redis_tag_key(tag, key)
  return string.format("{%s}:%s", tag, key)
end

function dump(obj)
    local getIndent, quoteStr, wrapKey, wrapVal, dumpObj
    getIndent = function(level)
        return string.rep("\t", level)
    end
    quoteStr = function(str)
        return '"' .. string.gsub(str, '"', '\\"') .. '"'
    end
    wrapKey = function(val)
        if type(val) == "number" then
            return "[" .. val .. "]"
        elseif type(val) == "string" then
            return "[" .. quoteStr(val) .. "]"
        else
            return "[" .. tostring(val) .. "]"
        end
    end
    wrapVal = function(val, level)
        if type(val) == "table" then
            return dumpObj(val, level)
        elseif type(val) == "number" then
            return val
        elseif type(val) == "string" then
            return quoteStr(val)
        else
            return tostring(val)
        end
    end
    dumpObj = function(obj, level)
        if type(obj) ~= "table" then
            return wrapVal(obj)
        end
        level = level + 1
        local tokens = {}
        tokens[#tokens + 1] = "{"
        for k, v in pairs(obj) do
            tokens[#tokens + 1] = getIndent(level) .. wrapKey(k) .. " = " .. wrapVal(v, level) .. ","
        end
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"
        return table.concat(tokens, "\n")
    end
    return dumpObj(obj, 0)
end
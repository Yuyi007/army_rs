
function LightView(classname, bundleFile, ctor, super)
  local cls = ViewBase(classname, bundleFile, ctor, super)

  function cls.bind(self, bundleFile, bindOptions)
    self:__bind(bundleFile, bindOptions)
  end

  function cls.__binded(self)
    if not self.__inited then
      self:init()
      self.__inited = true
    end
  end

  return cls
end

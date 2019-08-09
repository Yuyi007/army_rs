
function ViewUnique(classname, bundleFile, ctor, super)
  local cls = View2D(classname, bundleFile, ctor, super)

  function cls.checkUnique()
    if ui:findViewName(classname) then
      return false
    end
    return true
  end

  return cls
end
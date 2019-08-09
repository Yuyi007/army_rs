
function ModalView(classname, bundleFile, ctor, super)
  local cls = View(classname, bundleFile, ctor, super)

  function cls.initModal(self)
    self:setModal(true)
  end

  return cls
end

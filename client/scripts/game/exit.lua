-- exit.lua

return function (options)
  options = table.merge({
    keepProcess = false,
  }, options)

  OsCommon.exit(options.keepProcess)
end
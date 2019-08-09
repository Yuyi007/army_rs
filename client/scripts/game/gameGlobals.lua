-- gameGlobals.lua

local tracemem = rawget(_G, 'TRACE_MEM')

return function (options)
  options = table.merge({
    loadConfig = true,
    loadConfigOptions = {},
  }, options)

  if game.debug > 0 then
    logd('gameGlobals: options=%s %s', peek(options), debug.traceback())
  end

  if tracemem then traceMemory('gameGlobals 1') end

  declare('ss', SpriteSheetCache.new())
  declare('gp', GameObjectPool.new(rawget(_G, 'gp')))
  declare('ui', UIManager.new(rawget(_G, 'ui')))
  declare('md', Model.new())

  if tracemem then traceMemory('gameGlobals 2') end

  ObjectFactory.clear(true)
  ViewFactory.clear(true)
  TransformCollection.resetAll()

  ObjectFactory.initPools()
  ViewFactory.initPools()

  local newCfg
  if options.loadConfig ~= false or rawget(_G, 'cfg') == nil then
    SqliteConfigFile.closeAll()
    newCfg = Config.new(nil, options.loadConfigOptions)
  else
    logd('skip loading config: loadConfig=%s', tostring(options.loadConfig))
    newCfg = cfg
  end

  declare('cfg', newCfg)

  if tracemem then traceMemory('gameGlobals 3') end

  if rawget(_G, 'mp') then mp:destroy() end

  declare('mp', MsgEndpoint.new())
  declare('um', UpdateManager.new())
  declare('sm', SoundManager.new())
  declare('uoc', UnityObjectCache.new())
  declare('pm', PaymentManager.new())

  if tracemem then traceMemory('gameGlobals 4') end

  local gcr = rawget(_G, 'gcr')

  if gcr and gcr.cleanup then
    gcr:cleanup()
  end

  declare('gcr', GameController.new())

  --CombatController
  declare('cc', nil)

  declare('jbt', JoystickButtonTracker.new(rawget(_G, 'jbt')))
  -- declare('tem', TouchEffectManager.new())

  if tracemem then traceMemory('gameGlobals 5') end

  GameObjectDecorator.setGlobals()
  TransformDecorator.setGlobals()
  TransformCollection.setGlobals()
  FVParticleRootDecorator.setGlobals()

  if QualityUtil.isMemoryTight() then
    SET_RECORD_LOGS_MAX_LEN(500)
  end

  game.globalsDefined = true
end

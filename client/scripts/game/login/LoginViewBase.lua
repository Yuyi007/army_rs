View('LoginViewBase', 'prefab/ui/login/login_ui', function(self)
end)

local m = LoginViewBase

function m.onClassReloaded(_)
  -- do full gc and unload so we can debug memory leak in LoginView
  -- fullGC(true)
  -- printMonoMemory()
  -- peekSchedulerData()
  -- peekFunction(_G.schedulerData.updateClocks[12].func)
  -- peekRegistryItem(116)
  -- peekAllRegistryItems()
  -- LBoot.BundleManager.DumpAll()

  logd('LoginView onClassReloaded')
end

local HIDE_ACCOUNT =
{
  meizu = true,
  oppo = true,
  huawei = true,
  vivo  = true,
  yyb = true,
  baidu = true,
  ['4399'] = true,
  downjoy = true,
  ewan = true,
  douyu = true,
}

function m:init()
  self.backGroundColor = Color.new(0, 0, 0, 1)
  self:setModal(true)
  logd('LoginViewBase.init')
  self.btnReset:setVisible(false)
  ui:setCullingMask('default')
  self.curSceneType = 'login'
  FightRpc.forceExitScene(function() self:tryLogout() end)

  if HIDE_ACCOUNT[game.sdk] then
    self.btnAccount:setVisible(false)
  else
    self.btnAccount:setVisible(true)
  end
  self:sdkInit()
  -- clear quest process actions when login view is shown
  gcr:cleanup()
  qm.clearAction()
  qm.clearAllQuickUseCache()
  QuickUseManager.reset()
  md.__beforeCampInfo = nil

  -- performing full gc when going back to login view (after login view is shown)
  -- self:performWithDelay(0.5, function () fullGC(true) end)

  -- preload the empty scene
  if game.mode == 'development' and game.debug > 0 then
    pcall(function () DebuggerView.new({minimized=true}):show() end)
  end

  if self.serverNumber then
    self.serverNumber:onClick(function()
      self:onClickChangeServer()
    end)
  end

  if self.server then
    self.server:onClick(function()
      self:onClickChangeServer()
    end)
  end

  self:updateServer()

  self:setVersion()
  sm:mute(false)
  self:performWithDelay(0, function()
    sm:playMusicAtLogin("bgm_001")
  end)

  self.btnLogin:setBtnSound('button034')

  self:performWithDelay(1.0, function ()
    if QualityUtil.firstTimeChooseQuality then
      -- FloatingTextFactory.makeNormal {text=loc('first_time_choose_quality', loc(QualityUtil.firstTimeChooseQuality))}  -- 张帆让张胜和我说 这个不弹了
      QualityUtil.firstTimeChooseQuality = nil
    end
  end)

  self:performWithDelay(0.5, function ()
    if not m.noticeShown then
      m.noticeShown = true
      local ret, err = pcall(function()
        ui:push(NoticeView.new())
      end)
      if not ret then
        loge("===show notice error ===%s====",err)
      end
    end
  end)
end

function m:exit()

end

function m:sdkInit()

end

function m:update()
  self:updateServer()
end

function m:updateServer()
  local zone = self:getCurrentZone()
  local zoneData = game.openZones[zone]
  local status = ServerSlotView.getZoneStatus(zoneData)
  -- logd('LoginView: zone=%s status=%s zoneData=%s', tostring(zone), tostring(status), peek(zoneData))

  self.green_icon:setVisible(status == 'green')
  self.yellow_icon:setVisible(status == 'yellow')
  self.red_icon:setVisible(status == 'red')

  local zoneCfg = cfg.zones[zone]
  self.serverNumber:setString(zoneCfg.number)
  self.server:setString(zoneCfg.name)
end

function m:getCurrentZone()
  local zone = md.account.zone
  local numOpenZones = game.numOpenZones or 1
  local lastZones = game.lastZones or {}
  local recommend = self:getRecommendZone()

  if not zone then
    local latestLogin = 0
    for z, data in pairs(lastZones) do
      if z > 0 and z <= numOpenZones then
        if data.last_login and data.last_login > latestLogin then
          zone = z
          latestLogin = data.last_login
        end
      end
    end
  end

  zone = zone or recommend

  logd('LoginView: getCurrentZone zone=%s numOpenZones=%s recommend=%s lastZones=%s',
    tostring(zone), tostring(numOpenZones), tostring(recommend), peek(lastZones))

  if zone and (zone < 1 or zone > numOpenZones) then
    zone = recommend
  else
    zone = zone or recommend
  end

  if not zone or zone < 1 or zone > numOpenZones then
    error(string.format('invalid zone %s', tostring(zone)))
  end

  md.account.zone = zone
  md.account:saveDefaults()
  md.account:dump()

  return zone
end

function m:getRecommendZone()
  local numOpenZones = game.numOpenZones or 1
  local recommend = numOpenZones
  local lastSelected = -1

  if game.openZones then
    for z, data in pairs(game.openZones) do
      if z > 0 and z <= numOpenZones and data.recommend and z > lastSelected then
        recommend = z
        lastSelected = z
      end
    end
  end
  return recommend
end

function m:onBtnReset()
  self:warnReset(function()
    self:doClearAccount(function ()
      -- ui:push(ChooseServerView.new(self))
    end)
  end)
end

function m:warnReset(onComplete)
  ui:push(CommonPopup.new({strDesc = 'str_login_5',rightCallback = function()
    ui:pop()
    onComplete()
  end}))
end

function m:onBtnLogin()
  if self.accountCleared then
    logd('account was cleared')
    self:doReset(function(msg)
      md:rpcGetGameData(function(msg)
        ui:pop()
        m.createRoleAndEnterGame()
      end)
    end)
  else
    self:doLogin(function()
      md:rpcGetGameData(function(msg)
        md.cheatPlayer = false
        m.createRoleAndEnterGame()
      end)
    end)
  end
end

function m:onBtnSetting()
  ui:push(QualityView.new(self))
end

function m:onBtnAccount()
  FloatingTextFactory.makeFramed{text=loc('str_login_2'),color=ColorUtil.white,autoDestroy=true}
end

function m:onBtnNotice()
  -- FloatingTextFactory.makeFramed{text=loc('str_login_3'),color=ColorUtil.white,autoDestroy=true}
  -- local ret, err = pcall(function()
  --   ui:push(NoticeView.new())
  -- end)
  -- if not ret then
  --   loge("onBtnNotice %s",err)
  -- end
  if game.mode == 'development' then
    ui:goto(LoginViewTest.new())
  else
    ui:push(NoticeView.new())
  end
end

function m:onClickChangeServer()
  local pushView = function ()
    ui:push(ChooseServerView.new(self))
  end

  local now = Time:get_realtimeSinceStartup()
  local lastGetOpenZonesTime = md.lastGetOpenZonesTime

  if lastGetOpenZonesTime == nil or now - lastGetOpenZonesTime > 5.0 then
    md:rpcGetOpenZones(md.account.id, function ()
      self:updateServer()
      pushView()
    end)
  else
    pushView()
  end
end

function m:setVersion()
  local versionStr = game.version
  self.txtVersion:setString(versionStr)
end

function m:doClearAccount(onComplete)
  self.accountCleared = true
  md.account:clear()
  md.account:saveDefaults()
  game.lastZones = {}
  if onComplete then onComplete() end
end

function m:doReset(onComplete)
  self:tryLogout(function ()
    self:tryRegister(function(msg)
      md.account:loadDefaults()
      md.account:dump()
      self:tryLoginWithFakeQueue(onComplete, function () ui:pop() end)
    end)
  end)
end

function m:doLogin(onComplete)
  md.account:loadDefaults()
  md.account:dump()

  self:tryLogout(function ()
    self:tryLoginWithFakeQueue(onComplete, nil, function ()
      self:tryRegister(function ()
        self:tryLoginWithFakeQueue(onComplete)
      end)
    end)
  end)
end

function m:tryLoginWithFakeQueue(onSuccess, onFail, tryRegister)
  local zone = md.account.zone
  local queueRank = nil
  if game.openZones then
    local zoneData = game.openZones[zone]
    if zoneData and zoneData.max_online > 0 and
      zoneData.online < zoneData.max_online then
      queueRank = math.floor(zoneData.online - zoneData.max_online / 2)
    end
  end

  -- test fake queue queueRank
  -- queueRank = 10

  -- 封测期间不需要fake queue
  self.fakeQueueApplied = true

  if self.fakeQueueApplied or (not queueRank) or queueRank < 1 then
    self:tryLogin(onSuccess, onFail, tryRegister)
  else
    logd('LoginView: zone=%s fake queue...', tostring(zone))
    ui:push(FakeQueuingPopup.new(self, queueRank))
    self.fakeQueueApplied = true
  end
end

function m:tryLogin(onSuccess, onFail, tryRegister)
  local zone = md.account.zone
  logd('LoginView: zone=%s trying to login...', tostring(zone))
  self:sdkLogin(function(msg)
    if msg.success then
      logd('LoginView: zone=%s login success!', tostring(zone))
      self:performWithDelay(1, function()
        onSuccess()
      end)
    else
      if onFail then onFail() end

      if msg.reason == 'queue_rank' then
        ui:push(QueuingPopup.new(self, msg.queue_rank))
      elseif msg.reason == 'no_such_user' then
        if tryRegister then tryRegister() end
      end
    end
  end)
end

function m:tryRegister(onSuccess, onFail)
  local zone = md.account.zone
  logd('LoginView: zone=%s trying to register account...', tostring(zone))
  self:sdkRegister(function(msg)
    if msg.success then
      logd('LoginView: zone=%s register success!', tostring(zone))
      onSuccess()
    else
      if onFail then onFail() end
    end
  end)
end

function m:sdkLogin(onComplete)
  error('You must override me')
end

function m:sdkRegister(onComplete)
  error('You must override me')
end

function m:tryLogout(onSuccess)
  m.tryLogoutStatic(onSuccess)
end

function m.tryLogoutStatic(onSuccess)
  logd('tryLogoutStatic: ')
  if md.loggedIn then
    logd('tryLogoutStatic: logging out')
    md:rpcLogout(function ()
      if onSuccess then onSuccess() end
    end)
  else
    if onSuccess then onSuccess() end
  end
end

function m.createRoleAndEnterGame(options)
  options = options or {}
  if md:hasInstance() then
    options.mode = 'choose'
    ui:goto(ChooseCharacterScene.new(options), true)
  else
    options.mode = 'create'
    ui:goto(ChooseCharacterScene.new(options), true)
  end
end

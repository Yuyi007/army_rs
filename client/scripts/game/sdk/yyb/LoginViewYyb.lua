View('LoginView', 'prefab/ui/login/login_ui', function(self)
end, LoginViewBase)

local m = LoginView

function m:sdkInit()
  self.login1_left:setVisible(false)

  local accountType = unity.getString('account.defaultLoginType')
  local hasAccountType =  accountType and accountType ~= "" or false

  self.btnLogin:setVisible(hasAccountType)
  self.login1:setVisible(not hasAccountType)
  self.btnAccount:setVisible(hasAccountType)
end

function m:onLogin1_mid_btnWeChat()
  logd('LoginView: zone onLogin1_btnWeChat...')
  self:doLoginType("weChat", function()
    logd('LoginView: zone onLogin1_btnWeChat11...')
    md:rpcGetGameData(function(msg)
      logd('LoginView: zone onLogin1_btnWeChat222...')
      md.cheatPlayer = false
      LoginViewBase.createRoleAndEnterGame()
    end)
  end)
end

function m:onLogin1_right_btnQQ()
  logd('LoginView: zone onLogin1_btnQQ...')
  self:doLoginType("QQ", function()
      logd('LoginView: zone onLogin1_btnQQ111...')
    md:rpcGetGameData(function(msg)
        logd('LoginView: zone onLogin1_btnQQ11222...')
      md.cheatPlayer = false
      LoginViewBase.createRoleAndEnterGame()
    end)
  end)
end


function m:onBtnLogin()
  local accountType = unity.getString('account.defaultLoginType')
  logd('LoginView: zone onLogin1_btnLogin...: %s', tostring(accountType))
  self:doLoginType(tostring(accountType), function()
      logd('LoginView: zone onLogin1_btnLogin111...')
    md:rpcGetGameData(function(msg)
        logd('LoginView: zone onLogin1_btnLogin11222...')
      md.cheatPlayer = false
      LoginViewBase.createRoleAndEnterGame()
    end)
  end)
end

function m:onBtnAccount()
  logd('LoginView (yyb) logout ')
  SDKFirevale.doLogout(function (msg)
    logd('SDKFirevale.doLogout callback %s', peek(msg))
    if msg.success then
      -- save user login type
      unity.setString('account.defaultLoginType', "")
      self.btnLogin:setVisible(false)
      self.login1:setVisible(true)
      self.btnAccount:setVisible(false)
    else
      logd('firevale: logout failed msg=%s', peek(msg))
    end
  end)


end

function m:doLoginType(loginType, onComplete)
  logd('LoginView: zone doLoginType: %s...', tostring(loginType))
  md.account:loadDefaults()
  md.account:dump()

  self:tryLogout(function ()
    logd('LoginView: zone tryLogout: %s...', tostring(loginType))
    self:tryLoginWithFakeQueueType(loginType, onComplete)
  end)
end


function m:tryLoginWithFakeQueueType(loginType, onSuccess)
  logd('LoginView: zone tryLoginWithFakeQueueType: %s...', tostring(loginType))
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
    self:tryLoginType(loginType, onSuccess)
  else
    logd('LoginView: zone=%s fake queue...', tostring(zone))
    ui:push(FakeQueuingPopup.new(self, queueRank))
    self.fakeQueueApplied = true
  end
end


function m:tryLoginType(loginType, onSuccess)
  local zone = md.account.zone
  logd('LoginViewYyb: zone=%s trying to login...', tostring(zone))
  self:sdkLoginType(loginType, function(msg)
    if msg.success then
      logd('LoginViewYyb: zone=%s login success!', tostring(zone))
      self:performWithDelay(1, function()
        onSuccess()
      end)
    else
      if msg.reason == 'queue_rank' then
        ui:push(QueuingPopup.new(self, msg.queue_rank))
      else
        loge("try login fail reason: %s", tostring(msg.reason))
      end
    end
  end)
end

function m:sdkLoginType(loginType, onComplete)
  local zone = md.account.zone
  logd('LoginView (yyb) sdkLogin zone=%s, type=%s', tostring(zone), tostring(loginType))
  SDKFirevale.loginYyb(loginType, function (msg)
    logd('SDKFirevale.loginYyb callback %s', peek(msg))
    if msg.success then
      -- save user login type
      unity.setString('account.defaultLoginType', loginType)
      md:rpcLoginFirevale(msg.user_id, msg.access_token, zone, function(msg)
        self:updateServer()
        onComplete(msg)
      end)
    else
      logd('firevale: login failed msg=%s', peek(msg))
    end
  end)
end


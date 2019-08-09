-- ModelRpcAccount.lua

function Model:rpcUpdate(onComplete)
  return mp:sendMsg(100,
    { platform = game.platform,
      sdk = game.sdk,
      market = game.market,
      location = game.location,
      pkgVersion = game.pkgVersion, -- package version
      clientVersion = game.clientVersion, -- client update version
      displayVersion = game.version, -- version to display to player
      encoding = game.encoding,
      playerId = self.account.id, -- server use player id to distribute data servers
      deviceId = game.systemInfo.deviceId, -- server use device id to distribute data servers
    },
    function (msg)
      hotPatchCode(msg.client_lua_patch_code)

      if msg.num_open_zones then
        game.numOpenZones = msg.num_open_zones
        -- cfg:updateZones(msg.num_open_zones)
      end

      logd("update base url:%s", tostring(msg.url))
      game.updateBaseUrl = msg.url

      self:updateNonce(msg)
      self:processAfterGetOpenZones(msg)

      -- if msg.server_settings then
      --   game.serverSettings = msg.server_settings
      -- end

      onComplete(msg)
    end)
end

function Model:rpcRegister(email, pass, onComplete)
  mp:sendMsg(101, {email=email,pass=pass}, function (msg)
    if msg.success and msg.success ~= cjson.null then
      if email == nil and pass == nil then
        self.account.defaultId = msg.id
        self.account.defaultPass = msg.pass
      else
        self.account.id = msg.id
        self.account.email = email
      end
      self.account:saveDefaults()
    end
    onComplete(msg)
  end)
end


function Model:rpcGetVerificationCode(phoneno, onComplete)
  mp:sendMsg(196, {phoneno=phoneno}, function (msg)
    onComplete(msg)
  end)
end


function Model:rpcMobileRegister(phone, vcode, pass, onComplete)
  mp:sendMsg(197, {phone=phone,vcode=vcode,pass=pass}, function (msg)
    if msg.success and msg.success ~= cjson.null then
      if pass == nil then
        self.account.defaultId = msg.id
        self.account.defaultPass = msg.pass
      else
        self.account.id = msg.id
        self.account.phone = phone
      end
      self.account:saveDefaults()
    end
    onComplete(msg)
  end)
end



-- function Model:rpcLogin(id, email, pass, zone, onComplete)
--   mp:sendMsg("login", {name=id, password=pass}, function(msg)
--       onComplete(msg)
--     end)
-- end

function Model:rpcLogin(id, email, pass, zone, onComplete)
  self.loginFunc = function (self, onComplete, noMask)
    local data = {
      id=id,
      pass=pass,
      email=email,
      zone=zone,
    }
    data = self:commonLoginParams(data)
    mp:sendMsg(102, data, function (msg)
      self:updateLoginCommon(data, msg)
      onComplete(msg)
    end, {noMask=noMask})
  end

  self:loginFunc(onComplete, false)
end


function Model:rpcThirdpartyLogin(id,userid,platform,zone,onComplete)
  self.loginFunc = function (self, onComplete, noMask)
    local data = {
      id=id,
      userid=userid,
      platform=platform,
      zone=zone,
    }
    data = self:commonLoginParams(data)
    mp:sendMsg(112, data, function (msg)
      self:updateLoginCommon(data, msg)
      onComplete(msg)
    end, {noMask=noMask})
  end

  self:loginFunc(onComplete, false)
end


function Model:rpcUpdateUser(id, email, pass, newPass, onComplete)
  mp:sendMsg(103, {id=id,email=email,pass=pass,newPass=newPass}, function (msg)
    if msg.success and msg.success ~= cjson.null then
      if id == self.account.defaultId then
        self.account.defaultEmail = email
        self.account.defaultPass = newPass
      end
      self.account.id = id
      self.account.pass = newPass
      self.account.email = email
      self.account:saveDefaults()
    end
    onComplete(msg)
  end)
end

function Model:rpcRegisterGuest(onComplete)
  mp:sendMsg(104, {}, function (msg)
    if msg.success and msg.success ~= cjson.null then
      self.account.defaultId = msg.id
      self.account.defaultPass = msg.pass
      self.account.id = msg.id
      self.account.email = msg.email
      self.account.guestId = msg.id
      self.account.pass = msg.pass
      self.account:saveDefaults()
    end
    onComplete(msg)
  end)
end

function Model:rpcThirdpartyRegister(userid,platform,onComplete)
  mp:sendMsg(111, {userid=userid,platform=platform}, function (msg)
    if msg.success and msg.success ~= cjson.null then
      self.account.defaultId = msg.id
      self.account.defaultPass = msg.pass
      self.account.id = msg.id
      self.account.email = msg.email
      self.account.guestId = msg.id
      self.account.pass = msg.pass
      self.account.platform = platform
      self.account:saveDefaults()

    end
    onComplete(msg)
  end)
end



function Model:commonLoginParams(params)
  params.debug = (game.mode == 'development' and game.debug > 0) -- session debug flag
  params.platform = game.platform
  params.location = game.location
  params.sdk = game.sdk
  params.timezone = OsCommon.getTimezoneName()
  params.deviceId = game.systemInfo.deviceId
  params.deviceModel = game.systemInfo.deviceModel
  params.deviceMem = QualityUtil.getDeviceMem()
  params.gpuModel = game.systemInfo.graphicsDeviceName
  return params
end


function Model:rpcCancelQueuing(onComplete)
  mp:sendMsg(105, {}, function (msg)
    onComplete(msg)
  end)
end

function Model:rpcLogout(onComplete)
  mp:sendMsg(106, {
    playerId = self.account.id,
    deviceId = game.systemInfo.deviceId,
  }, function (msg)
    if msg.success then
      self:forgetLogin()
      self:processAfterGetOpenZones(msg)
    end
    onComplete(msg)
  end)
end

function Model:forgetLogin()
  logd('md: forgetLogin')
  self.loginFunc = nil
  self.loggedIn = false
end

function Model:rpcGetOpenZones(playerId, onComplete)
  self:rpcGetOpenZonesCustom({playerId = playerId}, onComplete)
end

function Model:rpcGetOpenZonesCustom(data, onComplete)
  data.deviceId = game.systemInfo.deviceId
  self.lastGetOpenZonesTime = Time:get_realtimeSinceStartup()
  mp:sendMsg(107, data, function (msg)
    self:processAfterGetOpenZones(msg)
    onComplete(msg)
  end)
end

function Model:processAfterGetOpenZones(msg)
  if msg.open_zones then
    game.openZones = msg.open_zones
  end

  if msg.last_zones then
    game.lastZones = msg.last_zones
  end
end

function Model:rpcKeepAlive(onComplete)
  mp:sendMsg(109, {
    averageFrameTime = mp.averageFrameTime,
    averageRTT = mp.averageRTT,
    sentRate = mp.sentRate,
    receiveRate = mp.receiveRate,
  }, function (msg)
  end, mp.queueOptsNoMask)
end


function Model:rpcUpdateUserPassword(phone,vcode,newPass,onComplete)
  mp:sendMsg(110, {
    phone=phone,vcode=vcode,new_pass=newPass
  }, function (msg)
    if msg.success then
      
    end
    onComplete(msg)
  end)
end

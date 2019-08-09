ViewScene('LoginViewTest', 'scenes/game/login', function(self)
end)

local ActionRecord = Game.ActionRecord
local m = LoginViewTest
m.__bindNodes = true

function m:init()
  -- sm:playMusic('theme')
  --sm:playMusic('ui_common/sign_in')
  local settings = clone(QualityUtil.cachedQualitySettings())

  if settings.music == nil then
    settings.music = true
  end

  if settings.sound == nil then
    settings.sound = true
  end

  if settings.yellowGuideLine == nil then
    settings.yellowGuideLine = true
  end

  if settings.blueGuideLine == nil then
    settings.blueGuideLine = true
  end

  if settings.shake == nil then
    settings.shake = true
  end

  QualityUtil.applyQualitySettings(settings)
  QualityUtil.saveQualitySettings(settings)

  local account  = unity.getString('account.email')
  local password = unity.getString('account.pass')
  local zone     = unity.getInt('account.zone')
  local host     = unity.getString('app.server.host')
  local port     = unity.getString('app.server.port')

  if account ~= '' then
    self.txtAccount:setString(account)
  end

  if password ~= '' then
    self.txtPassword:setString(password)
  end

  if zone ~= 0 then
    self.txtZone:setString(tostring(zone))
  else
    self.txtZone:setString('1')
  end

  if host ~= '' then
    self.txtHost:setString(host)
  else
    self.txtHost:setString(tostring(game.defaultHost))
  end

  if port ~= '' then
    self.txtPort:setString(port)
  else
    self.txtPort:setString(tostring(game.defaultPort))
  end

  -- preload the empty scene
  if not game.editor() then
    unity.loadBundleAsync('scenes/game/empty', function() end)
  end

  self.txtExt:setString('This is a [link_item=tid001][u]<color=red>hyperText</color>[/u][/link_item]')
  self.txtExt:onLinkClicked('link_item', function(txt)
    loge('%s clicked', txt)
  end)
  self.gameScript:setString(game.script)

  self.btnTestMain:setBtnSound('ui_common/button004')
  self.saveServer:setBtnSound('ui_common/button004')
end

function m:onSaveServer()
  unity.setString('app.server.host', self.txtHost:getString())
  unity.setString('app.server.port', self.txtPort:getString())

  if self.txtHost:getString() ~= '' then
    game.server.host = self.txtHost:getString()
  end

  if self.txtPort:getString() ~= '' then
    game.server.port = tonumber(self.txtPort:getString())
  end

  mp:destroy()
  mp:init(game.server.host, game.server.port)

  MessageHandler.init()
  ReconnectHandler.init()
end

function m:onBtnFight2D()
end

function m:onBtnAIDebug()
  self.enableShowStats = self.enableShowStats or true
  local go = GameObject.Find('/ShowStats')
  if go then
    self.enableShowStats = not self.enableShowStats
    go:SetActive(self.enableShowStats)
  end
end

function m:onBtnLoginView()
  -- md.account.email=""
  -- md.account.pass=""
  -- unity.setString('account.email', "")
  -- unity.setString('account.pass', "")
  -- md.account:loadDefaults()
  -- md.account:saveDefaults()
  ui:push(LoginView.new())
  -- ui:goto(LoginTestScene.new())
end

function m:onBtnCreate()
  md.cheatPlayer = true
  self:doLogin(function ()
    md:rpcGetGameData(function()
        if md:hasInstance() then
          ui:goto(ChooseCharacterScene.new({mode = 'choose'}), true)
        else
          ui:goto(ChooseCharacterScene.new({mode = 'create'}), true)
        end
      end)
    end)
end

function m:onBtnInstance()
  self:doLogin(function ()
    md:rpcGetGameData(function()
      local sid = 'cam101031'
      -- local sid = 'cam800011'
      -- local sid = 'cam101011'
      -- local sid = 'cam800011'
      -- local sid = 'cam101021'
      md:rpcStartSinglePve(sid, function(msg)
        ui:goto(PveFightScene.new({sid = sid}), true)
      end)
    end)
  end)
end

function m:onBtnTestMotion()
  self:doLogin(function ()
    md:rpcGetGameData(function()
    end)
  end)
end

function m:onBtnTestMain()
  local function getGameData()
     md:rpcGetGameData(function(msg)
          if md:hasInstance() then
            self:selectInst()
          else
            local name = self.txtAccount:getString()
            local fields = string.split(name, '@')
            name = fields[1]
            md:rpcCreateInstance(name, function(msg)
            	self:selectInst()
            end)
          end
        end)
  end

  self:doLogin(function ()
      getGameData()
    end)
  
end

function m:selectInst()
	local instId = md.chief.cur_inst_id
  if instId == nil or instId == '' then
    instId = m.instanceId
  end
  logd(">>>>>>instId:%s",tostring(instId))
  md:rpcChooseInstance(instId, function()
    ui:goto(MainSceneView.new())
  end)
end

function m:onBtncit016()
  ui:goto(LocalCombatScene.new())
end

function m:onBtnSceneTest()
  -- local msg= {uid="u100001", token="room_100001_none"}
  -- self.cm:kcpSend(1, msg)
  self.actionID = self.actionID or 0
  self.actionID = self.actionID + 1
  local cmd = 2
  local action = ActionFactory.make(1, cmd, self.actionID)
  action.data = {a = 1, b = "xxx"}
  local tb = action:toTable()
  self.cc.fs.inputLine:pushInput(tb)
  ActionFactory.recycle(action)
  -- self:doLogin(function ()
  --   md:rpcGetGameData(function()
  --     self:enterOrCreate()
  --   end)
  -- end)
end

function m:onBtnDebugger()
  DebuggerView.new():show()
end

function m:onBtnUITest()
  log('on update test')
  ui:goto(UpdatingScene.new({}), true)
end

function m:enterOrCreate(sid)
  sid = sid or 'cit001'
  md.cheatPlayer = true
  if md:hasInstance() then
    local sid = md:posInfo().city or 'cit001'
    local options = SceneOptions.new()
    options.sid = sid
    MainSceneFactory.goToScene(options, false)
  else
    ui:goto(ChooseCharacterScene.new({mode = 'create'}), true)
  end
end

function m:doLogin(onComplete)
  unity.setString('account.email', string.lower(self.txtAccount:getString()))
  unity.setString('account.pass', self.txtPassword:getString())
  unity.setInt('account.zone', tonumber(self.txtZone:getString()))

  md.account:loadDefaults()
  md.account:dump()
  local hashedPass = md.account.hashPass(md.account.pass)
  
  local function tryLogin(onFailed)
    md:rpcLogin(nil, md.account.email, hashedPass, md.account.zone, function(msg)
      if msg.success then
        self:performWithDelay(1, function()
          onComplete()
        end)
      else
        if msg.maintainance then
          FloatingTextFactory.makeNormal{text="Server on Maintainance!"}
        else
          if onFailed then
            onFailed()
          end
        end
      end
    end)
  end

  local function tryRegister()

    md:rpcRegister(md.account.email, hashedPass, function (msg)
      if msg.success then
        tryLogin(nil)
      end
    end)
  end
  
  tryLogin(tryRegister)
end


function m:onTest( )
  ui:goto(animatorView.new())
end
ViewScene('LoginTestScene', 'scenes/game/login_test', function(self)
end)


local m = LoginTestScene
m.__bindNodes = true


function m:init()
	local settings = clone(QualityUtil.cachedQualitySettings())
  self.timer=0
  -- sm:playMusic('theme')
  --sm:playMusic('ui_common/sign_in')
end

function m:onLogin_btnLogin()
	local account=self.login_txtAccount:getString()
	local pass=self.login_txtPassword:getString()
  if account == '' then
    local view = FloatingTextFactory.makeFramed {text = loc("str_account_nil",5)}
    view.txtbg_frame_txtFloating:setColor(ColorUtil.robber_red)
  elseif pass == '' then
    local view = FloatingTextFactory.makeFramed {text = loc("str_password_nil",5)}
    view.txtbg_frame_txtFloating:setColor(ColorUtil.robber_red)
  else  
    local hashedPass = md.account.hashPass(pass)
  	md:rpcLogin(nil, account, hashedPass, 1, function(msg)
      if msg.success then
        self:enterMainSceneView()
      else
        if msg.maintainance then
          FloatingTextFactory.makeNormal{text="Server on Maintainance!"}
        else
            
        end
      end
    end)
  end
end

function m:enterMainSceneView()
	md:rpcGetGameData(function(msg)
    if md:hasInstance() then
      self:selectInst()
    else
      local name = md.account.email
      if name then 
        local fields = string.split(name, '@')
        name = fields[1]
      else 
        name = md.account.phone
      end  
      md:rpcCreateInstance(name, function(msg)
        self:selectInst()
      end)
    end
  end)
end

function m:selectInst()
	local instId = md.chief.cur_inst_id
  if instId == nil or instId == '' then
    instId = m.instanceId
  end
  md:rpcChooseInstance(instId, function()
    ui:goto(MainSceneView.new())
  end)
end

function m:onLogin_btnMobileRegister()
	self.login:setVisible(false)
	self.mobileRegister:setVisible(true)
	self.accountRegister:setVisible(false)
end


function m:onLogin_btnAccountRegister()
	self.login:setVisible(false)
	self.mobileRegister:setVisible(false)
	self.accountRegister:setVisible(true)
end

function m:onLogin_btnGuestLogin()
	md:rpcRegisterGuest(function(msg)
    if msg.success and msg.success ~= cjson.null then
      md:rpcLogin(nil, md.account.email, md.account.pass, 1, function(msg)
        if msg.success then
        	self:enterMainSceneView()
        else
          if msg.maintainance then
            FloatingTextFactory.makeNormal{text="Servr on Maintainance!"}
          else
            FloatingTextFactory.makeNormal{text=msg.reason}  
          end  
        end
      end)
    end
  end)
end

function m:onMobileRegister_btnConfirm()
	local mobile = self.mobileRegister_txtMobile:getString()
	local verification_code = self.mobileRegister_txtVerificationCode:getString()
	local pass=self.mobileRegister_txtPassword:getString()
  if mobile == '' then
    self:showTips("str_mobile_nil",5,ColorUtil.robber_red)
  elseif string.len(mobile) ~= 11 then  
    self:showTips("str_mobile_length_error",5,ColorUtil.robber_red)
  elseif string.match(mobile,"[1][3,4,5,7,8]%d%d%d%d%d%d%d%d%d") ~= mobile then
    self:showTips("str_mobile_invalid",5,ColorUtil.robber_red)
  elseif verification_code == '' then
    self:showTips("str_verification_code_nil",5,ColorUtil.robber_red)
  elseif pass == '' then
    self:showTips("str_password_nil",5,ColorUtil.robber_red)
  elseif string.len(pass) < 6 or string.len(pass) > 24 then
    self:showTips("str_password_length",5,ColorUtil.robber_red) 
  elseif string.match(pass,"%w+") ~= pass then
    self:showTips("str_password_invalid",5,ColorUtil.robber_red) 
  else 
    local hashedPass = md.account.hashPass(pass)
    md:rpcMobileRegister(mobile, verification_code, hashedPass, function (msg)
      if msg.success then
        md:rpcLogin(nil, mobile,hashedPass, 1, function(msg)
          if msg.success then
            self:enterMainSceneView()
          else
            FloatingTextFactory.makeNormal{text=msg.reason}
          end
        end)
      else 
         FloatingTextFactory.makeNormal{text=loc("str_verification_code_invalid",5)}
      end
    end)   
  end
end

function m:msgCountDown()
  self.timer=60
  self.mobileRegister_btnGetCode:setString(self.timer.."秒")
  self.msg_timer = scheduler.schedule(function()
    if self.timer <= 0 then
       self.mobileRegister_btnGetCode:setString(loc("str_verification_code",5))
       scheduler.unschedule(self.msg_timer)
    else
      self.timer=self.timer-1
      self.mobileRegister_btnGetCode:setString(self.timer.."秒")
    end
  end,1) 
end

function m:onMobileRegister_btnGetCode()
  if self.timer <= 0 then
    self.timer =3
  	local mobile = self.mobileRegister_txtMobile:getString()
    if mobile == '' then
      self:showTips("str_mobile_nil",5,ColorUtil.robber_red)
    elseif string.len(mobile) ~= 11 then
      self:showTips("str_mobile_length_error",5,ColorUtil.robber_red)
    else
      md:rpcGetVerificationCode(mobile , function (msg)
        if msg.success then
          self:msgCountDown()
        else 
          FloatingTextFactory.makeNormal{text=loc("str_verification_code_fail",5)}
          self.timer = 0
        end
      end)  
    end 
   end 
end

function m:showTips(msg,num,color)
  local view = FloatingTextFactory.makeFramed {text = loc(msg,num)}
  view.txtbg_frame_txtFloating:setColor(color)
end

function m:onAccountRegister_btnConfirm()
	local email=self.accountRegister_txtEmail:getString()
	local pass=self.accountRegister_txtPassword:getString()
	local surePass=self.accountRegister_txtSurePassword:getString()
  if email == '' then
    self:showTips("str_account_nil",5,ColorUtil.robber_red)
  elseif string.len(email) < 6 or string.len(email) > 24 then
     self:showTips("str_account_length",5,ColorUtil.robber_red)
  elseif pass == '' then
    self:showTips("str_password_nil",5,ColorUtil.robber_red)
  elseif string.len(pass) < 6 or string.len(pass) > 24 then
    self:showTips("str_password_length",5,ColorUtil.robber_red)
  elseif string.match(pass,"%w+") ~= pass then
    self:showTips("str_password_invalid",5,ColorUtil.robber_red)   
  elseif surePass == '' then
    self:showTips("str_sure_password_nil",5,ColorUtil.robber_red)
  elseif pass ~= surePass then
    self:showTips("str_password_different",5,ColorUtil.robber_red)
  else
    local hashedPass = md.account.hashPass(pass)
    md:rpcRegister(email, hashedPass, function (msg)
      if msg.success then
        md:rpcLogin(nil, email,hashedPass, 1, function(msg)
          if msg.success then
            self:enterMainSceneView()
          else
            if msg.maintainance then
              FloatingTextFactory.makeNormal{text="Server on Maintainance!"}
            else
              FloatingTextFactory.makeNormal{text=msg.reason}
            end
          end
        end)
      else 
        FloatingTextFactory.makeNormal{text=loc("str_verification_code_fail",5)}
      end
    end)
  end
end

function m:onMobileRegister_btnCancle()
  self.login:setVisible(true)
  self.mobileRegister:setVisible(false)
  self.accountRegister:setVisible(false)
end

function m:onAccountRegister_btnCancle()
  self.login:setVisible(true)
  self.mobileRegister:setVisible(false)
  self.accountRegister:setVisible(false)
end


function m:exit()
  if self.msg_timer then
    scheduler.unschedule(self.msg_timer)
    self.msg_timer = nil
  end
end






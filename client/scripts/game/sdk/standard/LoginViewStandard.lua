View('LoginView', 'prefab/ui/common/login_ui', function(self)
  self.slots={}
end)


local m = LoginView
m.__bindNodes = true


function m:init()
  local settings = clone(QualityUtil.cachedQualitySettings())
  self.timer=0
  self.authLogin=self.sign.gameObject:getComponent(Game.AuthLogin)
  self.authLogin:registAuthResult(self.getAuthResult)
  self.authLogin:registGetUserInfoResult(self.getUserInfoResult)

  local account  = unity.getString('account.email')
  local password = unity.getString('account.pass')
  local platform = unity.getInt('account.platform')
  self.selected_zone = unity.getInt('account.zone')
  self.selected_zoneName = unity.getString('account.zoneName')

  if platform == 0  then
    if account ~= '' then
      self.sign_txtAccount:setString(account)
    end
    if password ~= '' then
      self.sign_txtPassword:setString(password)
    end
  end

  self.sign:setVisible(true)
  self.mobileRegister:setVisible(false)
  self.accountRegister:setVisible(false)
  self.passwordRetrieve01:setVisible(false)
  self.passwordRetrieve02:setVisible(false)
  self.zoneList:setVisible(false)
  self.start:setVisible(false)
  md:rpcGetOpenZones(md.account.id, function (msg)
    self.open_zones=msg.open_zones
    self.list=self.open_zones
    table.insert(self.list,1,self.open_zones[1])
    table.insert(self.list,1,self.open_zones[1])   
    table.insert(self.list,self.open_zones[1])
    table.insert(self.list,self.open_zones[1])
    self:createItem()
  end)
  if platform == 0 and password ~= '' then 
    self:onSign_btnLogin()
  elseif platform == 22 then
    self.authLogin:getUserInfo(2)
  elseif platform == 24 then
    self.authLogin:getUserInfo(1)
  end
  self.loginFail = unity.getInt('account.loginFail')
  self.timer=unity.getInt('account.timer')
  self.msgNum= unity.getInt('account.msgNum')
  self.day = unity.getInt('account.day')
  self.drop=self.sign_selectAccount.transform:getComponent("Dropdown")  
  local onValueChanged = self.drop:get_onValueChanged()
  self:addListener(onValueChanged, function()
    self:selectAccount()
  end)
  self.bindDropdownData=self.sign_selectAccount.transform:getComponent("BindDropdownData")
  self.bindDropdownData:SetItems(account)
  self.bindDropdownData:RefreshDropdownData()
  self.clickAgreement=1
  self:setVersion()
end


function m:setVersion()
  local versionStr = game.version
  self.txtVersion:setString(loc('str_version').." "..versionStr)
end

function m:onSign_btnLogin()
  local account=string.lower(self.sign_txtAccount:getString())
  local pass=self.sign_txtPassword:getString()
  if account == '' then
    self:showTips("str_account_nil",5,ColorUtil.robber_red)
  elseif pass == '' then
    self:showTips("str_password_nil",5,ColorUtil.robber_red)
  else  
    local hashedPass = md.account.hashPass(pass)
    if md.account.email == account and md.account.pass== pass then 
      hashedPass=self.sign_txtPassword:getString()
    end
   
    if os.time() - self.timer  > 300 then
      self.loginFail = 0
    end
    if self.loginFail > 5 then
       self:showTips("str_login_fail",5,ColorUtil.robber_red)
    else
      md:rpcLogin(nil, account, hashedPass, 1, function(msg)
        self.timer= os.time()
        if msg.success then
          unity.setString('account.email', account)
          unity.setString('account.pass', hashedPass)
          unity.setString('account.platform', 0)
          unity.setInt('account.loginFail', 0)
          unity.setInt('account.timer',self.timer)
          md.account:loadDefaults()
          md.account:saveDefaults()
          self.sign:setVisible(false)
          self:enterStart()
        else
          if msg.reason then
            self:showTips("str_"..msg.reason,3,ColorUtil.robber_red)
          else
            self:showTips("str_account_password_fail",3,ColorUtil.robber_red)
          end
          self.loginFail= self.loginFail+1
          unity.setInt('account.loginFail', self.loginFail)
          unity.setInt('account.timer',self.timer)
          md.account:loadDefaults()
          md.account:saveDefaults()
        end
      end)
    end
  end
end

function m:enterStart()
  self.start:setVisible(true)
  self.start_email:setString(md.account.email)
  if self.open_zones then
    if md.account.zone ~= 0 then
      local zone_name=md.account.zone..'区 '..self.open_zones[md.account.zone]['zone_name']
      self.start_zone_txtZoneName:setString(zone_name)
    else
      local zone_name='1区 '..self.open_zones[1]['zone_name']
      self.start_zone_txtZoneName:setString(zone_name)
    end
  elseif self.selected_zone ~= 0 and self.selected_zoneName ~= '' then
    local zone_name=self.selected_zone..'区 '..self.selected_zoneName
    self.start_zone_txtZoneName:setString(zone_name)
  end
end 

function m:onStart_zone()
  self:createItem()
  self.start:setVisible(false)
  self.zoneList:setVisible(true)
end

function m:onStart_btnStart()
  if self.selected_zone == 0 then
    self.selected_zone = 1
  end
  md:rpcLogin(nil, md.account.email, md.account.pass, self.selected_zone, function(msg)
    if msg.success then
      unity.setInt('account.zone', tonumber(self.selected_zone))
      unity.setString('account.zoneName', self.selected_zoneName)
      md.account:loadDefaults()
      md.account:saveDefaults()
      self:enterMainSceneView()

    else
      self:showTips("str_account_password_fail",3,ColorUtil.robber_red) 
    end
  end)
end



function m:enterMainSceneView()
  md:rpcGetGameData(function(msg)
    if md:hasInstance() then
      self:selectInst()
    else
      ui:push(UserView.new())
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

function m:onSign_btnWechatLogin()
  self:showTips("str_no_function",3,ColorUtil.robber_red)
  -- self.authLogin:authorize(2)
end

function m:onSign_btnQQLogin()
  self:showTips("str_no_function",3,ColorUtil.robber_red)
  -- self.authLogin:authorize(1)
end

-- type  QQ=24  WeChat = 22,
function m:getAuthResult(state,type,result)
  logd(">>>>>>>>>>>>>>>> getAuthResult")
  --//Success
  if state == 1 then
    local userid = 0
    if type == 22 then
      userid = result.openid
    elseif type == 24 then
      userid = result.userID
    end
    if userid ~= 0 then
      md:rpcThirdpartyRegister(userid,type,function(msg)
        if msg.success then
          self.sign:setVisible(false)
          self:enterStart()
        else
          self:thirdpartyLogin(userid,type)
        end
      end)
    end  
  --  //Failure
  elseif state == 2 then
     self:showTips("str_confirm_reconnect_desc",3,ColorUtil.robber_red)
  --//Cancel
  elseif state == 3 then

  end
end 


function m:thirdpartyLogin(userid,type)
  md:rpcThirdpartyLogin(nil, userid, type, 1, function(msg)
    if msg.success then
      self.tourist:setVisible(true)
      self.sign:setVisible(false)
    else
      self:showTips("str_confirm_reconnect_desc",3,ColorUtil.robber_red)
    end
  end)
end
-- type  QQ=24  WeChat = 22,
function m:getUserInfoResult(state,type,result)
  logd(">>>>>>>>>>>>>>>> getUserInfoResult")
   --//Success
  if state == 1 then
    local userid = 0
    if type == 22 then
      userid = result.openid
    elseif type == 24 then
      userid = result.userID
    end
    self:thirdpartyLogin(userid,type)
  --  //Failure
  elseif state == 2 then
    self.sign_txtAccount:setString("")
    self.sign_txtPassword:setString("")
  --//Cancel
  elseif state == 3 then
    self.sign_txtAccount:setString("")
    self.sign_txtPassword:setString("")
  end
end 

function m:onSign_btnMobileRegister()
  self:showTips("str_no_function",3,ColorUtil.robber_red)
  -- self.sign:setVisible(false)
  -- self.mobileRegister:setVisible(true)
  -- self.accountRegister:setVisible(false)
  -- self.selectStatus=true
  -- self.timer=0
  -- self.mobileRegister_btnSelect_selected:setVisible(true)
  -- self.mobileRegister_txtMobile:setString("")
  -- self.mobileRegister_txtVerificationCode:setString("")
  -- self.mobileRegister_txtPassword:setString("")
end


function m:onSign_btnAccountRegister()
  self.sign:setVisible(false)
  self.mobileRegister:setVisible(false)
  self.accountRegister:setVisible(true)
  self.selectStatus=true
  self.accountRegister_btnSelect_selected:setVisible(true)
  self.accountRegister_txtEmail:setString("")
  self.accountRegister_txtPassword:setString("")
  self.accountRegister_txtSurePassword:setString("")
end

function m:onSign_txtPassword_forgetPassword()
  self.sign:setVisible(false)
  self.passwordRetrieve01:setVisible(true)
  self.passwordRetrieve01_txtMobile:setString("")
  self.timer=0
end


function m:onSign_btnGuestLogin()
  self.tourist:setVisible(true)
  -- local no_breaking_space = "\u3000";
  -- local declaratin="  敬爱的玩家，您正在使用游客模式进行游戏。游客模式下的游戏数据（包含付费数据）会在删除游戏，更换设备后，长期未登录时清空。为了保障您的虚拟财产安全，以及让您获得更完善的游戏体验，我们建议您使用手机号/帐号登录进行游戏！或进入游戏后绑定手机号码转换为正式帐号。"
  -- local s=(string.gsub(declaratin," ",no_breaking_space))
  -- self.tourist_declaration:setString(s)
  self.sign:setVisible(false)
  
end


function m:createItem()
 
  local env = {
    view  = self,
    list  = self.list,
    sv    = self.zoneList_zList,
    dir   = 'v',
    slotHeight = 60,
    slotWidth = 505,
    slots = self.slots,
    getSlot = self.getSlot,
    updateSlot = self.getSlot,
    shouldReset = true,
    isAnimate    = false,
    onComplete = function()
    end
  }
  ScrollListUtil.MakeVertListOptimized(env, true)
  local goList = self.zoneList_zList.transform:find("List")
  local ap = goList:getComponent(RectTransform):get_anchoredPosition()
  goList:getComponent(RectTransform):set_anchoredPosition(Vector2(ap[1], ap[2]-env.slotHeight/2))
 

end

function m:getSlot(index, item)
  local slot = nil
  if self.slots[index] == nil then
     -- slot = ZoneItem.new(self,index,item,true)
    if index == 1  or index == 2  or  index == #(self.list)  or index == #(self.list)-1 then
      slot = ZoneItem.new(self,index,item,self.selected_zone,false)
    else
      slot = ZoneItem.new(self,index,item,self.selected_zone,true)
    end
    self.slots[index] = slot
  else
    slot = self.slots[index]
    slot:update(self, index, item,self.selected_zone)
  end

  return slot
end

function m:onTourist_btnTourist()
  md:rpcRegisterGuest(function(msg)
    if msg.success and msg.success ~= cjson.null then
      md.account.pass=msg.pass
      md:rpcLogin(nil, md.account.email, msg.pass, 1, function(msg)
        if msg.success then
          md.account.zone=1
          unity.setInt('account.zone', md.account.zone)
          md.account:loadDefaults()
          md.account:saveDefaults()
          self.start_email:setString(md.account.email)
          self.tourist:setVisible(false)
          self.start:setVisible(true)
          local zone_name=md.account.zone..'区 '..self.open_zones[md.account.zone]['zone_name']
          self.start_zone_txtZoneName:setString(zone_name)
        else
          self:showTips("str_confirm_reconnect_desc",3,ColorUtil.robber_red)
        end
      end)
    end
  end)
end

function m:chooseZone(zone)
  local zone_name=zone.zone..'区 '..zone['zone_name']
  self.start_zone_txtZoneName:setString(zone_name)
  self.start:setVisible(true)
  self.zoneList:setVisible(false)
  self.selected_zone=zone['zone']
  self.selected_zoneName=zone['zone_name']
  unity.setInt('account.zone', self.selected_zone)
  md.account:loadDefaults()
end


function m:onTourist_btnCancle()
  self.tourist:setVisible(false)
  self.sign:setVisible(true)
end

function m:onMobileRegister_btnSelect()
  self.mobileRegister_btnSelect_selected:setVisible(not (self.selectStatus))
  self.selectStatus= not (self.selectStatus)
end

function m:onAccountRegister_btnSelect()
  self.accountRegister_btnSelect_selected:setVisible(not (self.selectStatus))
  self.selectStatus= not (self.selectStatus)
end


function m:onMobileRegister_btnConfirm()
  local mobile = self.mobileRegister_txtMobile:getString()
  local verification_code = self.mobileRegister_txtVerificationCode:getString()
  local pass=self.mobileRegister_txtPassword:getString()
  if mobile == '' then
    self:showTips("str_mobile_nil",3,ColorUtil.robber_red)
  elseif string.len(mobile) ~= 11 then  
    self:showTips("str_mobile_length_error",3,ColorUtil.robber_red)
  elseif string.match(mobile,"[1][3,4,5,7,8]%d%d%d%d%d%d%d%d%d") ~= mobile then
    self:showTips("str_mobile_invalid",5,ColorUtil.robber_red)
  elseif verification_code == '' then
    self:showTips("str_verification_code_nil",3,ColorUtil.robber_red)
  elseif pass == '' then
    self:showTips("str_password_nil",3,ColorUtil.robber_red)
  elseif string.len(pass) < 6 or string.len(pass) > 16 then
    self:showTips("str_password_length",3,ColorUtil.robber_red) 
  elseif string.match(pass,"%w+") ~= pass then
    self:showTips("str_password_invalid",3,ColorUtil.robber_red) 
  elseif self.selectStatus == false then
    self:showTips("str_treaty_disagreement",3,ColorUtil.robber_red) 
  else 
    local hashedPass = md.account.hashPass(pass)
    md:rpcMobileRegister(mobile, verification_code, hashedPass, function (msg)
      if msg.success then
        md.account.email=string.lower(self.mobileRegister_txtMobile:getString())
        md.account.pass=hashedPass
        unity.setString('account.email', string.lower(self.mobileRegister_txtMobile:getString()))
        unity.setString('account.pass', hashedPass)
        md.account:loadDefaults()
        md.account:saveDefaults()
        self.mobileRegister:setVisible(false)
        self:enterStart()
      else
        if msg.reason then
          self:showTips("str_verification_code_error",3,ColorUtil.robber_red)
        else
          self:showTips("str_mobile_exist",3,ColorUtil.robber_red)
        end 
      end
    end)   
  end
end

function m:msgCountDown(obj)
  self.timer=60
  if self.msg_timer then
    scheduler.unschedule(self.msg_timer)
    self.msg_timer=nil
  end  
  obj:setString(self.timer.."秒")
  self.msg_timer = scheduler.schedule(function()
    if self.timer <= 0 then
      obj:setString(loc("str_verification_code",5))
      scheduler.unschedule(self.msg_timer)
      self.msg_timer=nil
    else
      self.timer=self.timer-1
      obj:setString(self.timer.."秒")
    end
  end,1) 
end


function m:checkMsg()
  if tonumber(os.date("%d")) ~= self.day then
    self.msgNum = 0
    self.day=tonumber(os.date("%d"))
    unity.setInt('account.day', self.day)
  end
  if self.msgNum > 100 then
    self:showTips("str_msg_send_fail",3,ColorUtil.robber_red)
    return false
  else
    self.msgNum=self.msgNum+1
    unity.setInt('account.msgNum',self.msgNum)
    return true
  end
end

function m:onMobileRegister_btnGetCode()
  if self.timer <= 0 then
    local mobile = self.mobileRegister_txtMobile:getString()
    if mobile == '' then
      self:showTips("str_mobile_nil",3,ColorUtil.robber_red)
    elseif string.len(mobile) ~= 11 then
      self:showTips("str_mobile_length_error",3,ColorUtil.robber_red)
    elseif string.match(mobile,"[1][3,4,5,7,8]%d%d%d%d%d%d%d%d%d") ~= mobile then
      self:showTips("str_mobile_invalid",3,ColorUtil.robber_red) 
    else
      if self:checkMsg() then
        md:rpcGetVerificationCode(mobile , function (msg)
          if msg.success then
            md.account:loadDefaults()
            md.account:saveDefaults()
            self:msgCountDown(self.mobileRegister_btnGetCode)
          else 
            self:showTips("str_verification_code_fail",3,ColorUtil.robber_red)
            self.timer = 0
          end
        end)
      end
    end 
   end 
end

function m:showTips(msg,num,color)
   FloatingTextFactory.makeFramedTwo {text = loc(msg,num), 
    color = color }
end

function m:onSign_txtAccount_btnMore()
  self.drop:Show(true)
  self.drop:set_value(-1)
end

function m:selectAccount()
  self.sign_txtAccount:setString(md.account.email)
end


function m:onAccountRegister_btnConfirm()
  local email=string.lower(self.accountRegister_txtEmail:getString())
  local pass=self.accountRegister_txtPassword:getString()
  local surePass=self.accountRegister_txtSurePassword:getString()
  if email == '' then
    self:showTips("str_account_nil",3,ColorUtil.robber_red)
  elseif string.len(email) < 8 or string.len(email) > 24 then
     self:showTips("str_account_length",3,ColorUtil.robber_red)
  elseif string.find(email,"@yousi.com") ~= nil then
    self:showTips("str_account_exist",3,ColorUtil.robber_red)
  elseif string.match(email,"[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?") ~= email then
    self:showTips("str_mail_format_fail",3,ColorUtil.robber_red)
  elseif pass == '' then
    self:showTips("str_password_nil",3,ColorUtil.robber_red)
  elseif string.len(pass) < 6 or string.len(pass) > 16 then
    self:showTips("str_password_length",3,ColorUtil.robber_red)
  elseif string.match(pass,"%w+") ~= pass then
    self:showTips("str_password_invalid",3,ColorUtil.robber_red)   
  elseif surePass == '' then
    self:showTips("str_sure_password_nil",3,ColorUtil.robber_red)
  elseif pass ~= surePass then
    self:showTips("str_password_different",3,ColorUtil.robber_red)
  elseif self.selectStatus == false then
    self:showTips("str_treaty_disagreement",3,ColorUtil.robber_red)   
  else
    local hashedPass = md.account.hashPass(pass)
    md:rpcRegister(email, hashedPass, function (msg)
      if msg.success then
        md.account.email=self.accountRegister_txtEmail:getString()
        md.account.pass=hashedPass
        unity.setString('account.email', self.accountRegister_txtEmail:getString())
        unity.setString('account.pass', hashedPass)
        md.account:loadDefaults()
        md.account:saveDefaults()
        self.accountRegister:setVisible(false)
        self:enterStart()
      else 
        self:showTips("str_account_exist",3,ColorUtil.robber_red)
      end
    end)
  end
end

function m:onMobileRegister_btnCancle()
  self.sign:setVisible(true)
  self.mobileRegister:setVisible(false)
  self.accountRegister:setVisible(false)
end

function m:onAccountRegister_btnCancle()
  self.sign:setVisible(true)
  self.mobileRegister:setVisible(false)
  self.accountRegister:setVisible(false)
end

function m:onPasswordRetrieve01_btnCancle()
  self.sign:setVisible(true)
  self.passwordRetrieve01:setVisible(false)
end


function m:onPasswordRetrieve02_btnCancle()
  self.passwordRetrieve01:setVisible(true)
  self.passwordRetrieve02:setVisible(false)
  self.timer=0
end

function m:onServiceAgreement_btnCancle()
  self.serviceAgreement:setVisible(false)
  if self.clickAgreement == 1 then
    self.start:setVisible(true)
  elseif self.clickAgreement == 2 then
     self.mobileRegister:setVisible(true)
  elseif self.clickAgreement == 3 then
    self.accountRegister:setVisible(true)
  end
end

function m:onGuide_btnCancle()
  self.start:setVisible(true)
  self.guide:setVisible(false)
end

function m:onMobileRegister_btnAgreement()
  self.serviceAgreement:setVisible(true)
  self.mobileRegister:setVisible(false)
  self.clickAgreement=2
  local goList=self.serviceAgreement_statement.transform:find("List")
  local ap = goList:getComponent(RectTransform):get_anchoredPosition()
  goList:getComponent(RectTransform):set_anchoredPosition( Vector2(ap[1], 0) )
end

function m:onAccountRegister_btnAgreement()
  self.serviceAgreement:setVisible(true)
  self.accountRegister:setVisible(false)
  self.clickAgreement=3
  local goList=self.serviceAgreement_statement.transform:find("List")
  local ap = goList:getComponent(RectTransform):get_anchoredPosition()
  goList:getComponent(RectTransform):set_anchoredPosition( Vector2(ap[1], 0) )
end

function m:onStart_btnAgreement()
  self.serviceAgreement:setVisible(true)
  self.start:setVisible(false)
  self.clickAgreement=1
  local goList=self.serviceAgreement_statement.transform:find("List")
  local ap = goList:getComponent(RectTransform):get_anchoredPosition()
  goList:getComponent(RectTransform):set_anchoredPosition( Vector2(ap[1], 0) )
end

function m:onStart_btnGuide()
  self.guide:setVisible(true)
  self.start:setVisible(false)
  local goList=self.guide_statement.transform:find("List")
  local ap = goList:getComponent(RectTransform):get_anchoredPosition()
  goList:getComponent(RectTransform):set_anchoredPosition( Vector2(ap[1], 0) )
end

function m:onPasswordRetrieve01_btnNext()
  if self.timer <= 0 then
    local mobile = self.passwordRetrieve01_txtMobile:getString()
    if mobile == '' then
      self:showTips("str_mobile_nil",3,ColorUtil.robber_red)
    elseif string.len(mobile) ~= 11 then
      self:showTips("str_mobile_length_error",3,ColorUtil.robber_red)
    elseif string.match(mobile,"[1][3,4,5,7,8]%d%d%d%d%d%d%d%d%d") ~= mobile then
      self:showTips("str_mobile_invalid",3,ColorUtil.robber_red) 
    else
      if self:checkMsg() then
        md:rpcGetVerificationCode(mobile , function (msg)
          if msg.success then
            md.account:loadDefaults()
            md.account:saveDefaults()
            self:msgCountDown(self.passwordRetrieve02_btnGetCode)
            self.passwordRetrieve01:setVisible(false)
            self.passwordRetrieve02:setVisible(true)
            local m=string.sub(mobile,1,3)..'****'..string.sub(mobile,-4) 
            self.passwordRetrieve02_txtMobile:setString(m)
            self.passwordRetrieve02_txtVerificationCode:setString("")
            self.passwordRetrieve02_txtPassword:setString("")
            self.passwordRetrieve02_txtSurePassword:setString("")
          else 
            self:showTips("str_verification_code_fail",3,ColorUtil.robber_red)
            self.timer = 0
          end
        end)
      end
    end 
   end 
end


function m:onPasswordRetrieve02_btnEditPassword()
  local mobile=self.passwordRetrieve01_txtMobile:getString()
  local verification_code = self.passwordRetrieve02_txtVerificationCode:getString()
  local pass=self.passwordRetrieve02_txtPassword:getString()
  local surePass=self.passwordRetrieve02_txtSurePassword:getString()
  if verification_code == '' then
    self:showTips("str_verification_code_nil",3,ColorUtil.robber_red)
  elseif pass == '' then
    self:showTips("str_password_nil",3,ColorUtil.robber_red)
  elseif string.len(pass) < 6 or string.len(pass) > 16 then
    self:showTips("str_password_length",3,ColorUtil.robber_red)
  elseif string.match(pass,"%w+") ~= pass then
    self:showTips("str_password_invalid",3,ColorUtil.robber_red)   
  elseif surePass == '' then
    self:showTips("str_sure_password_nil",3,ColorUtil.robber_red)
  elseif pass ~= surePass then
    self:showTips("str_password_different",3,ColorUtil.robber_red)
  elseif self.selectStatus == false then
    self:showTips("str_treaty_disagreement",3,ColorUtil.robber_red)   
  else
    local hashedPass = md.account.hashPass(pass)
    md:rpcUpdateUserPassword(mobile,verification_code, hashedPass,function (msg)
      if msg.success then
        unity.setString('account.email', mobile)
        unity.setString('account.pass', hashedPass)
        md.account:loadDefaults()
        md.account:saveDefaults()
        self.sign_txtAccount:setString(mobile)
        self.sign_txtPassword:setString(hashedPass)
        self.passwordRetrieve02:setVisible(false)
        self.sign:setVisible(true)
      else 
        if msg.reason then
          self:showTips("str_verification_code_invalid",3,ColorUtil.robber_red)
        else
          self:showTips("str_mobile_no_exist",3,ColorUtil.robber_red)
        end
      end
    end)  
  end
end

function m:onStart_btnLoginOut()
  md:rpcLogout(function(msg)
    self.start:setVisible(false)
    self.sign:setVisible(true)
    self.sign_txtAccount:setString(md.account.email)
    self.sign_txtPassword:setString('')
    unity.setString('account.pass', '')
    self.bindDropdownData:ClearDropdownData()
    self.bindDropdownData:SetItems(md.account.email)
    self.bindDropdownData:RefreshDropdownData()
    -- unity.setInt('account.zone', tonumber(self.txtZone:getString()))
    md.account:loadDefaults()
    md.account:saveDefaults()
  end)
end


function m:exit()
  if self.msg_timer then
    scheduler.unschedule(self.msg_timer)
    self.msg_timer = nil
  end
end






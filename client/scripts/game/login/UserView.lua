View('UserView', 'prefab/ui/common/user_ui', function(self)
  self.slots={}
end)


local m = UserView
m.__bindNodes = true


function m:init()
	local settings = clone(QualityUtil.cachedQualitySettings())
  self.timer=0
  local account  = unity.getString('account.email')
  local password = unity.getString('account.pass')
  self.userName_btnRoll_def:setVisible(true)
  self.userName_btnRoll_roll:setVisible(false)
  self:onHead01()
  self.name_total=table.getn(cfg.name)
  self.gender=0
  local name=self:getRandomName(self.gender)
  self.userName:setString(name)
  self.icon=1
end

function m:onHead01()
 for i=1,5 do
    self["head0" .. i].transform:getComponent(Image):set_color(ColorUtil.transparent)
  end
  self.head01.transform:getComponent(Image):set_color(ColorUtil.orange_yellow)
  self.icon=1
end

function m:onHead02()
 for i=1,5 do
    self["head0" .. i].transform:getComponent(Image):set_color(ColorUtil.transparent)
  end
  self.head02.transform:getComponent(Image):set_color(ColorUtil.orange_yellow)
  self.icon=2
end

function m:onHead03()
  for i=1,5 do
    self["head0" .. i].transform:getComponent(Image):set_color(ColorUtil.transparent)
  end
  self.head03.transform:getComponent(Image):set_color(ColorUtil.orange_yellow)
  self.icon=3
end

function m:onHead04()
  for i=1,5 do
    self["head0" .. i].transform:getComponent(Image):set_color(ColorUtil.transparent)
  end
  self.head04.transform:getComponent(Image):set_color(ColorUtil.orange_yellow)
  self.icon=4
end

function m:onHead05()
  for i=1,5 do
    self["head0" .. i].transform:getComponent(Image):set_color(ColorUtil.transparent)
  end
  self.head05.transform:getComponent(Image):set_color(ColorUtil.orange_yellow)
  self.icon=5
end

function m:onUserName_btnRoll()
  self.userName_btnRoll_def:setVisible(false)
  self.userName_btnRoll_roll:setVisible(true)
  self:performWithDelay(0.3, function()
    self.userName_btnRoll_def:setVisible(true)
    self.userName_btnRoll_roll:setVisible(false)
  end)
  local name=self:getRandomName(self.gender)
  self.userName:setString(name)
end


function m:getRandomName(gender)
  local index=math.random(1,self.name_total)
  if gender == 0 then
    if index % 2 == 0 then index=index+1  end 
  else
    if index % 2 == 1 then index=index+1  end 
  end
  if index > self.name_total then index=index-2 end
  return cfg.name[index]
end

function m:onBtnConfirm()
  local name = self.userName:getString()
  local icon=self.icon
  if self.gender == 1 then
    icon=icon+5
  end
  local s = cfg:gsubSensitiveWords(name)
  if name == '' then
    FloatingTextFactory.makeFramedTwo {text = loc("str_name_nil",3), 
      color = ColorUtil.red }
  elseif name ~= s then
    FloatingTextFactory.makeFramedTwo {text = loc("str_username_sensitive_word",3), 
      color = ColorUtil.red }
  else
    md:rpcCreateNewInstance(name, self.gender,icon,function(msg)
      if msg.success ~= false then
	      local instId = md.chief.cur_inst_id
        if instId == nil or instId == '' then
			    instId = m.instanceId
			  end
			  md:rpcChooseInstance(instId, function()
			    ui:goto(MainSceneView.new())
			  end)
      else
        if msg.reason then
           FloatingTextFactory.makeFramedTwo {text = loc('str_'..msg.reason,5),  color = ColorUtil.robber_red }
        end
      end
    end)
  end
end

function m:onMan()
  self.man_selected:setVisible(true)
  self.woman_selected:setVisible(false)
  self.gender=0
  self.woman:setGray()
  self.man:setNormal()
  for i=1,5 do
    self["head0" .. i.."_img"].transform:getComponent(Image):setSprite(string.format("head-img-00%s", tostring(i)))
  end
end

function m:onWoman()
  self.man_selected:setVisible(false)
  self.woman_selected:setVisible(true)
  self.gender=1
  self.woman:setNormal()
  self.man:setGray()
  for i=1,5 do
    self["head0" .. i.."_img"].transform:getComponent(Image):setSprite(string.format("head-img-00%s", tostring(i+5)))
  end
end

function m:exit()
  if self.msg_timer then
    scheduler.unschedule(self.msg_timer)
    self.msg_timer = nil
  end
end






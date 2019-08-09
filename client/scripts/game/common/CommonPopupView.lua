--[[
ui:push(CommonPopup.new({
    strDesc = strDesc,
    rightCallback = function()
      leave(2)
    end,
    sound = {left = "button008", right = "button014", close = "button008"}
  }))

]]

View('CommonPopupView', 'prefab/ui/common/pop_ui', function(self, options)
  self.animType     = "level2"
  self.options = options or {}
  self.__vsIndex = self.options.vsIndex or self.__vsIndex
end)

local m = CommonPopupView

function m:init()
  FramedFloatingText.deleteTipView()

  self.strDesc = self.options.strDesc or loc('str_pop_are_you_sure')
  self.strLeftBtn = self.options.strLeftBtn or loc('str_pop_quxiao')
  self.strRightBtn = self.options.strRightBtn or loc('str_pop_queren')

  self.leftCallback = self.options.leftCallback or function()
    ui:pop(nil, self.__vsIndex)
    sm:playSound("ui_common/button001")
  end
  self.rightCallback = self.options.rightCallback or function()
    sm:playSound("ui_common/button002")
    ui:pop(nil, self.__vsIndex)
  end
  self.closeCallback = self.options.closeCallback or function()
    sm:playSound("ui_common/button003")
    ui:pop(nil, self.__vsIndex)
  end

  if self.options.descVisible ~= nil then
    self.txtDesc:setVisible(self.options.descVisible)
  end

  if self.options.closeVisible ~= nil then
    self.btnClose:setVisible(self.options.closeVisible)
  end

  if self.options.leftColor ~= nil then
    self:setBtnColor(self.btnLeft, self.options.leftColor)
  else
    self:setBtnColor(self.btnLeft, 'red')
  end


  if self.options.rightColor ~= nil then
    self:setBtnColor(self.btnRight, self.options.rightColor)
  else
    self:setBtnColor(self.btnRight, 'green')
  end

  if self.options.hideLeft then
    self.btnLeft:setVisible(false)
  end

  if self.options.hiedeRight then
    self.btnRight:setVisible(false)
  end

  self:initUI()
  self:initButtonSound()

  if self.options.sound then
    local leftSound = self.options.sound.left
    local rightSound = self.options.sound.right
    local closeSound = self.options.sound.close
    self.btnLeft:setBtnSound(leftSound)
    self.btnRight:setBtnSound(rightSound)
    self.btnClose:setBtnSound(closeSound)
  end
  if self.options.killPopfun then
    self.popFun = nil
  end
end

function m:initButtonSound()
  logd("init button sound test 111")
  local buttonList = {}
  buttonList["btnClose"] = "ui_common/button001"
  buttonList["btnLeft"] = "ui_common/button003"
  buttonList["btnRight"] = "ui_common/button002"
  UIUtil.resetButtonDefaultSound(self, buttonList)
end


function m:initUI()
  self:setText(self.txtDesc, (self.strDesc))
  self:setText(self.btnLeft_txt, (self.strLeftBtn))
  self:setText(self.btnRight_txt, (self.strRightBtn))
  self.txtDesc:setVisible(self.options.strDesc ~= nil)
end

function m:setText(ctrl, strText)
  if ctrl then
    ctrl:setString(strText)
  end
end

function m:setBtnColor(btn, color)
  if color == 'red' then
    btn:setBtnImage('BtnNormal2')
  elseif color == 'green' then
    btn:setBtnImage('BtnNormal2')
  elseif color == 'yellow' then
    btn:setBtnImage('BtnNormal2')
  end
end

function m:onBtnClose()
  self.closeCallback()
end

function m:onBtnLeft()
  self.leftCallback()
  ui:pop(nil, self.__vsIndex)
end

function m:onBtnRight()
  self.rightCallback()
  ui:pop(nil, self.__vsIndex)
end




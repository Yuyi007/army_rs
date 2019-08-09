ModalView('ConfirmReconnectPopup', 'prefab/ui/common/pop_ui', function(self, options)
  self.options = table.merge({
    onOk = function ()
      mp:tryReconnect()
    end,
    onCancel = function ()
      returnToLogin(function ()
        mp:tryReconnect()
      end)
    end,
  }, options)
end, CommonPopupView)

local m = ConfirmReconnectPopup

local waitStr = {'%s.  ', '%s.. ', '%s...'}
local waitIndex = #waitStr

function m:init()
  CommonPopupView.init(self)

  self.strDesc = loc('str_confirm_reconnect_desc')
  self.strDescUp = nil
  self.strDescDown = nil
  self.strLeftBtn = loc('str_return_to_login')
  self.strRightBtn = loc('str_reconnect')

  self:setText(self.txtDesc, self.strDesc)
  self:setText(self.btnLeft_txt, self.strLeftBtn)
  self:setText(self.btnRight_txt, self.strRightBtn)

  self.txtDesc:setVisible(true)
  self.btnLeft:setEnabled(true)
  self.btnRight:setEnabled(true)

  self:update()
end

function m:exit()
  logd('ConfirmReconnectPopup: exit')
end

function m:update()
end

function m:onBtnClose()
  self:close()

  local onCancel = self.options.onCancel
  if onCancel then onCancel() end
end

function m:onBtnLeft()
  self:close()

  local onCancel = self.options.onCancel
  if onCancel then onCancel() end
end

function m:onBtnRight()
  self:startCheckNetwork()

  self:setText(self.txtDesc, string.format(waitStr[1], loc('str_reconnecting')))

  local onOk = self.options.onOk
  if onOk then onOk() end
end

function m:startCheckNetwork()
  if self.checkNetworkHandle then
    self:unschedule(self.checkNetworkHandle)
    self.checkNetworkHandle = nil
  end

  self.checkNetworkHandle = self:schedule(function ()
    waitIndex = (waitIndex + 1) % #waitStr
    if mp:isConnected() then
      self:close()
    else
      self:setText(self.txtDesc, string.format(waitStr[waitIndex + 1], loc('str_reconnecting')))
    end
  end, 0.3)
end

function m:close()
  ui:remove(self)

  local onClosed = self.options.onClosed
  if onClosed then onClosed() end
end

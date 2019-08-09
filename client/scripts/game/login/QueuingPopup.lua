ModalView('QueuingPopup', 'prefab/ui/server/server_queue_pop', function(self, loginView, queueRank, options)
  self.loginView = loginView
  self:updateQueueRank(queueRank)
  self.options = options or {}
end)

local m = QueuingPopup

function m:init()
  -- CommonPopup.init(self)

  -- self.strTitle = loc('str_queuing')
  -- self.strDesc = loc('str_queuing_rank', tostring(self.queueRank), '10')
  -- self.strDescUp = nil
  -- self.strDescDown = nil
  -- self.strLeftBtn = loc('str_pop_quxiao')
  -- self.strRightBtn = loc('str_enter_game')

  -- self:setText(self.txtTitle, self.strTitle)
  -- self:setText(self.btnRight_txt, self.strRightBtn)
  -- self.txtDesc:setVisible(true)
  -- self.btnRight:setEnabled(false)

  local zone = md.account.zone
  local zoneCfg = cfg.zones[zone]
  self.txt1:setString(loc('queue_waiting', zoneCfg.name))

  self.animControl = self:bindViewNode(self.transform:GetChild(0), 'anim_control')
  if self.animControl then
    self.animControl.animator:set_enabled(false)
    self.animControl.animator:set_enabled(true)
    self.animControl.animator:Play("server_queue_open")
  end

  self:update()

  self:schedule(function ()
    if self.queueTime and self.queueTime > 0 then
      self.queueTime = self.queueTime - 1
    end
    self:update()
  end, 1)

  self:initQueuingUpdate()
end

function m:exit()
  logd('QueuingPopup: exit')
  self:exitQueuingUpdate()
end

function m:initQueuingUpdate()
  self.onQueuingMesssage = function (msg)
    if msg.dequeue then
      self.dequeued = true
      self:onDequeue()
    elseif msg.queue_rank then
      self.dequeued = false
      self:updateQueueRank(msg.queue_rank)
    end
  end
  md:signal('channel_queuing'):add(self.onQueuingMesssage)
end

function m:exitQueuingUpdate()
  if self.onQueuingMesssage then
    md:signal('channel_queuing'):remove(self.onQueuingMesssage)
    self.onQueuingMesssage = nil
  end
end

function m:update()
  -- if self.dequeued then
  --   self.strDesc = loc('str_queuing_finish')
  --   self:setText(self.txtDesc, (self.strDesc))
  --   self.btnRight:setEnabled(true)
  -- else
  --   local mins = math.ceil(self.queueTime / 60)
  --   self.strDesc = loc('str_queuing_rank', tostring(self.queueRank), tostring(mins))
  --   self:setText(self.txtDesc, (self.strDesc))
  --   self.btnRight:setEnabled(false)
  -- end

  if not self.queueTime then return end

  local hours = math.floor(self.queueTime / 3600)
  local mins = math.ceil(self.queueTime % 3600 / 60)
  logd('queueTime=%d hours=%d mins=%d', self.queueTime, hours, mins)

  if hours > 0 then
    self.txt2:setString(loc('str_queue_waiting_more_hour'))
  elseif hours == 0 and mins <= 1 then
    self.txt2:setString(loc('queue_waiting_time_coming'))
  else
    self.txt2:setString(loc('queue_waiting_time', tostring(hours), tostring(mins)))
  end

  local remain = self.queueRank
  self.txt3:setString(loc('queue_waiting_remain', tostring(remain)))
end

-- function m:onBtnClose()
--   self:cancelQueuing()
-- end

-- function m:onBtnLeft()
--   self:cancelQueuing()
-- end

-- function m:onBtnRight()
--   self.loginView:onBtnLogin()
-- end

function m:onBtnClose()
  self:cancelQueuing()
end

function m:onDequeue()
  logd('QueuingPopup: onDequeue')
  self.loginView:onBtnLogin()
  self:update()
end

function m:cancelQueuing()
  logd('QueuingPopup: cancelQueuing...')
  md:rpcCancelQueuing(function ()
    -- self.btnRight:setEnabled(true)
    self:close()
  end)
end

function m:updateQueueRank(queueRank)
  self.queueRank = queueRank + 1
  self.queueTime = math.ceil(self.queueRank * self:getTimeFactor())
  logd('QueuingPopup: updateQueueRank rank=%d time=%d', self.queueRank, self.queueTime)
end

function m:getTimeFactor()
  if not self.timeMultiplier then
    self.timeMultiplier = math.random(11, 12) / math.random(10, 11)
  end

  -- local factor = math.random(59, 67)
  local factor = 61

  return factor * self.timeMultiplier
end

function m:close()
  if self.animControl then
    -- logd('animCallbackBehaviour=%s', tostring(self.animControl.animCallbackBehaviour))
    local onAnimCloseEnd = function ()
      self.animControl.animator:set_enabled(false)
      ui:remove(self)
    end
    self.animControl.onAnimEvent = function (param)
      logd('onAnimEvent param=%s', tostring(param))
      onAnimCloseEnd()
    end
    -- Somehow the anim event is not fired
    self:performWithDelay(0.233, onAnimCloseEnd)
    self.animControl.animator:Play("server_queue_close")
  else
    ui:remove(self)
  end
end

function m:destroy()
  -- Delete gameObject since somehow the open anim doesn't play fully
  self:baseDestroy(true)
end

ModalView('ChooseServerView', 'prefab/ui/server/server_ui', function(self, parent)
  self.parent = parent
  self.animType = 'level2'
end)

local m = ChooseServerView

function m.onClassReloaded(_)
end

function m:init()
  self.mySlots = {}
  self.allSlots = {}
  self.mode = 'mine'

  self.data = {}
  self.data.openZones = clone(game.openZones)
  self.data.lastZones = clone(game.lastZones)

  logd('ChooseServerView: account=%s', peek(md.account))
  logd('ChooseServerView: openZones=%s', peek(self.data.openZones))
  logd('ChooseServerView: lastZones=%s', peek(self.data.lastZones))

  self:update()
end

function m:exit()
  self.parent = nil
end

function m:update()
  if self.mode == 'mine' then
    self.btnTab1.button:setOn(true)
    self.btnTab1_text:setColor(ColorUtil.black)
    self.btnTab1_text2:setColor(ColorUtil.red)
    self.btnTab2_text:setColor(ColorUtil.white)
    self.btnTab2_text2:setColor(ColorUtil.yellow)
  elseif self.mode == 'all' then
    self.btnTab2.button:setOn(true)
    self.btnTab2_text:setColor(ColorUtil.black)
    self.btnTab2_text2:setColor(ColorUtil.red)
    self.btnTab1_text:setColor(ColorUtil.white)
    self.btnTab1_text2:setColor(ColorUtil.yellow)
  end

  self.scrollMyServer:setVisible(self.mode == 'mine')
  self.scrollAllServer:setVisible(self.mode == 'all')

  if self.mode == 'mine' then
    self:updateMyServers()
  elseif self.mode == 'all' then
    self:updateAllServers()
  end
end

function m:updateMyServers()
  local openZones = self.data.openZones
  local lastZones = self.data.lastZones or {}
  local myServerList = {}
  local lastServer = nil
  local latestLogin = 0

  for zone, data in pairs(lastZones) do
    if zone <= game.numOpenZones then
      data.zone = zone
      data.online = openZones[zone].online
      data.max_online = openZones[zone].max_online
      if data.last_login and data.last_login > latestLogin then
        lastServer = data
        latestLogin = data.last_login
      end
      myServerList[#myServerList + 1] = data
    end
  end

  if latestLogin > 0 then
    self.btnTab1.transform:get_parent():setVisible(true)
    local date = os.date('*t', latestLogin)
    self.scrollMyServer_lastLogin_date:setString(loc('last_login_date',
      string.format('%4d', date.year), string.format('%02d', date.month), string.format('%02d', date.day)))
    self.scrollMyServer_lastLogin_time:setString(string.format('%02d:%02d', date.hour, date.min))
    -- self.scrollMyServer_lastLogin_date:setVisible(true)
    -- self.scrollMyServer_lastLogin_time:setVisible(true)
    -- self.scrollMyServer_lastLogin:setVisible(true)
  else
    self.btnTab1.transform:get_parent():setVisible(false)
    -- self.scrollMyServer_lastLogin_date:setString(loc('last_login_date', '--', '-', '-'))
    -- self.scrollMyServer_lastLogin_time:setString('--:--')
    -- self.scrollMyServer_lastLogin_date:setVisible(false)
    -- self.scrollMyServer_lastLogin_time:setVisible(false)
    -- self.scrollMyServer_lastLogin:setVisible(false)
    self.mode = 'all'
    self:update()
    return
  end

  if not self.lastServerSlotView then
    -- logd('ChooseServerView: lastServer=%s', peek(lastServer))
    self.lastServerSlotView = ServerSlotView.new(self, nil, lastServer, self.scrollMyServer_lastServerSlot)
  end

  if lastServer then
    self.lastServerSlotView:setVisible(true)
    self.lastServerSlotView:setData(lastServer)
  else
    self.lastServerSlotView:setVisible(false)
  end

  local goList = self.scrollMyServer_list.transform
  local env = {
    view        = self,
    list        = myServerList,
    sv          = self.scrollMyServer,
    goList      = goList,
    dir         = 'v',
    col         = 2,
    spacing     = 2,
    size        = 84,
    slots       = self.mySlots,
    getSlot     = self.getMyServerSlot,
    shouldReset = true,
  }
  -- goList:GetComponent(UI.GridLayoutGroup):set_constraintCount(1)
  -- ScrollListUtil.MakeGridVOptimized(env)
  ScrollListUtil.MakeList(env)
end

function m:updateAllServers()
  local openZones = self.data.openZones
  local lastZones = self.data.lastZones or {}
  local allServerList = {}

  for zone, data in pairs(openZones) do
    if zone <= game.numOpenZones then
      data.zone = zone
      local lastZone = lastZones[zone]
      if lastZone then
        data.last_login = lastZone.last_login
        data.num_instances = lastZone.num_instances
      end
      allServerList[#allServerList + 1] = data
    end
  end
  allServerList = table.reverse(allServerList)
  -- logd('ChooseServerView: allServerList=%s', peek(allServerList))

  local goList = self.scrollAllServer.transform:find("List")
  local env = {
    view        = self,
    list        = allServerList,
    sv          = self.scrollAllServer,
    goList      = goList,
    dir         = 'v',
    col         = 2,
    spacing     = 2,
    size        = 84,
    slots       = self.allSlots,
    getSlot     = self.getAllServerSlot,
    shouldReset = true,
  }
  goList:GetComponent(UI.GridLayoutGroup):set_constraintCount(1)
  ScrollListUtil.MakeGridVOptimized(env)
end

function m:getMyServerSlot(index, data)
  local update = false
  if self.mySlots[index] then
    update = true
    self.mySlots[index]:update(index, data)
  else
    self.mySlots[index] = ServerSlotView.new(self, index, data)
  end
  return self.mySlots[index], update
end

function m:getAllServerSlot(index, data)
  local update = false
  if self.allSlots[index] then
    update = true
    self.allSlots[index]:update(index, data)
  else
    self.allSlots[index] = ServerSlotView.new(self, index, data)
  end
  return self.allSlots[index], update
end

function m:setServerSelected(slot)
  local data = slot.data
  logd('setServerSelected zone=%d data=%s', data.zone, peek(data))
  md.account.zone = data.zone
  md.account:saveDefaults()
  md.account:dump()
  if self.parent then
    self.parent:updateServer()
  end
  self:close()
end

function m:onBtnTab1()
  self.mode = 'mine'
  self:update()
end

function m:onBtnTab2()
  self.mode = 'all'
  self:update()
end

function m:onBtnClose()
  self:close()
end

function m:close()
  ui:pop()
end

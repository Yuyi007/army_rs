View('ServerSlotView', nil, function(self, parent, index, data, go)
  self.parent = parent
  self.index = index
  self.data = data

  if go then
    self:bind(go)
  else
    self:bind('prefab/ui/server/server_slot')
  end
end)

local m = ServerSlotView

function m.onClassReloaded(_)
end

function m:init()
  self:update()
end

function m:exit()
  self.parent = nil
end

function m.getZoneStatus(data)
  local status = nil
  if data.max_online == 0 then
    status = 'green'
  elseif data.online >= data.max_online * 0.9 then
    status = 'red'
  elseif data.online >= data.max_online * 0.5 then
    status = 'yellow'
  else
    status = 'green'
  end
  return status
end

function m:update()
  local data = self.data
  local status = m.getZoneStatus(data)

  self.icnGreen:setVisible(status == 'green')
  self.icnYellow:setVisible(status == 'yellow')
  self.icnRed:setVisible(status == 'red')

  local isNew = (data.zone >= game.numOpenZones - 1)
  self.icnNew:setVisible(isNew)

  local roleNum = data.num_instances or 0
  self.icnColor:setVisible(true)
  self.roleNumber:setString(string.format('X%d', roleNum))

  if roleNum > 0 then
    self.icnColor:setColor(ColorUtil.yellow)
    self.roleNumber:setOutLineColor(ColorUtil.yellow)
  else
    self.icnColor:setColor(ColorUtil.gray)
    self.roleNumber:setOutLineColor(ColorUtil.gray)
  end

  local zoneCfg = cfg.zones[data.zone]
  self.serverNumber:setString(zoneCfg.number)
  self.serverName:setString(zoneCfg.name)
end

function m:onBtn()
  self.parent:setServerSelected(self)
end

function m:setData(data)
  self.data = data
  self:update()
end

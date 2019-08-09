View('SettingGMSlot', 'prefab/ui/settings/settings_GM_slot', function (self, parent, index, data)
  self.parent = parent
  self.index = index
  self.data  = data
end)

local m = SettingGMSlot

function m:init()
  self:update(self.index, self.data)
end

function m:update(index, data)
  self.index = index
  self.data = self.data
  if data and data.desc then
    self.content:setVisible(true)
    self.empty:setVisible(false)
    self.content_title:setString(loc(data.title))
    self.content_desc:setString(loc(data.desc))
    self.content_button_txt:setString(loc(data.btnTxt))
  else
    self.content:setVisible(false)
    self.empty:setVisible(true)
  end
end

function m:onContent_button()
  logd("GM func %s ", self.data.func)
  if self.data and self[self.data.func] then
    self[self.data.func]()
  end
end

function m:toWalkPlace()
  local moved = false
  local cc = rawget(_G, 'cc')
  if cc and cc.scene and cc.scene.cityId then
    local cityId = cc.scene.cityId
    local my = cc.findMyHero()
    if my then
      local point = my:position()
      local ok, pos = my.navigator:getNearestPt(point, 10000)
      if ok then
        local spawnPos = cfg.getDefaultSpawnPos(cityId)
        local spawnData = cfg.interior_spawn_pos[cityId]
        my:setPosition(pos)
        local opt = { category = "position", sid = cityId , pos = {spawnData.x, 0, spawnData.z} }
        local guider = GuiderFactory.makeManualGuider(opt)
        guider:calcPath()

        if not guider.ready then
          logd("cann't find path set to spawnPos ")
          my:setPosition(spawnPos)
        end
        local action = ActionFactory.makePhone()
        action:setMoveData(my)
        my:sendMessage(my.id, action)
        moved = true
        FloatingTextFactory.makeFramed{text = loc('str_setting_gm_walk_success')}
        ui:pop()
      end
    end
  end

  if not moved then
    FloatingTextFactory.makeFramed{text = loc('str_setting_move_fail')}
  end
end

function m:toFaq()
  logd("toFaq function ")

  SDKFirevale.faq(function(msg)
    logd("SDKFirevale faq resutl:%s", tostring(msg))
  end)
end


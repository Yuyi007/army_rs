-- QualityView used for production

ModalView('QualityView', 'prefab/ui/settings/settings_ui', function (self, parent)
  self.parent = parent
  self.slots = {}
  self._hideScene = true
  self.backGroundColor = Color.new(0, 0, 0, 1)
end)

local m = QualityView

function m:init()
  self.settings = clone(QualityUtil.cachedQualitySettings())
  self.mode = 'service'
  self.level = self:decideLevel()
  self.oldSettings = {
    particleLevel = self.settings.particleLevel,
    enableShadows = self.settings.enableShadows,
    enableMovingCars = self.settings.enableMovingCars,
    maxOnScreenPlayers = self.settings.maxOnScreenPlayers,
  }

  self.quality_frame1_txt:setString(string.format('%dfps', QualityUtil.lowFrameRate))
  self.quality_frame2_txt:setString(string.format('%dfps', QualityUtil.highFrameRate))
  self.quality_maxPlayers_slider.slider.minValue = 1
  self.quality_maxPlayers_slider.slider.maxValue = 100

  self.onValueChanged = self.quality_maxPlayers_slider.slider:get_onValueChanged()
  self:addListener(self.onValueChanged, function(_)
    self:onMaxPlayers_slider_ValueChanged()
  end)

  if self.parent and self.parent.class == LoginView then
    self.bg:setVisible(false)
  end

  self.animControl = self:bindViewNode(self.transform:GetChild(0), 'anim_control')
  if self.animControl then
    self.animControl.animator:set_enabled(true)
    self.animControl.animator:Play("settings_open")
  end

  self:update()
end

function m:exit()
  if self.onValueChanged then
    self:removeAllListeners(self.onValueChanged)
    self.onValueChanged = nil
  end
  self.parent = nil
end

function m:onBtn1()
  self.mode = 'sound'
  self:update()
end

function m:onBtn2()
  self.mode = 'graphics'
  self:update()
end

function m:onBtn3()
  self.mode = 'service'
  self:update()
end

function m:update()
  local showSound = (self.mode == 'sound')
  self.sound:setVisible(showSound)
  if showSound then
    self:updateTogButton()
    self:updateSound()
  end

  local showGraphics = (self.mode == 'graphics')
  self.quality:setVisible(showGraphics)
  if showGraphics then
    self:updateTogButton()
    self:updateGraphics()
  end

  local showService = (self.mode == 'service')
  self.GM:setVisible(showService)
  if showService then
    self:updateTogButton()
    self:updateGM()
  end
end

function m:updateTogButton()
  local tab = {'sound', 'graphics', 'service'}
  local index = table.index(tab, self.mode)
  for i = 1, 3 do
    self['btn'..i].button:setOn(i == index)
    self['btn'..i..'_text1']:setColor(i == index and ColorUtil.black or ColorUtil.white)
    self['btn'..i..'_text2']:setColor(i == index and ColorUtil.red or ColorUtil.yellow)
  end
end

function m:updateGM()
  self.gmList = {
                  {title = "str_setting_gm_title1", desc = "str_setting_gm_desc1", func = "toWalkPlace", btnTxt = "str_setting_gm_btnTxt1"},
                  {},
                }

  -- if game.sdk == 'firevale' and game.mode == 'development' then
    table.insert(self.gmList, 2, {title = "str_setting_gm_title2", desc = "str_setting_gm_desc2", func = "toFaq", btnTxt = "str_setting_gm_btnTxt2"})
  -- end

  local env = {
    view  = self,
    list  = self.gmList,
    sv    = self.GM_scroll,
    dir   = 'v',
    size  = 213,
    slotHeight = 213,
    slots = self.slots,
    getSlot = self.getServiceSlot,
    shouldReset = true,
    onComplete = function()
      clampScroll(self.GM_scroll)
      self.GM_scroll.scrollRect:StopMovement()
      fixScrollMove(self.GM_scroll, true, 0)
      -- self.GM_scroll.scrollRect:set_movementType( UI.ScrollRect.MovementType.Elastic )
    end
  }
  ScrollListUtil.MakeList(env)
end

function m:getServiceSlot(index, data)
  local slot = nil
  if self.slots[index] then
    slot = self.slots[index]
    slot:update(index, data)
  else
    slot = SettingGMSlot.new(self, index, data)
    self.slots[index] = slot
  end
  return slot
end

function m:updateSound()
  self.sound_music_btnSwitch_on:setVisible(self.settings.music)
  self.sound_music_btnSwitch_off:setVisible(not self.settings.music)

  self.sound_sound_btnSwitch_on:setVisible(self.settings.sound)
  self.sound_sound_btnSwitch_off:setVisible(not self.settings.sound)
end

function m:onSound_music_btnSwitch()
  self.settings.music = (not self.settings.music)
  self:updateSound()
end

function m:onSound_sound_btnSwitch()
  self.settings.sound = (not self.settings.sound)
  self:updateSound()
end

function m:updateGraphics()
  self:updateGraphicsLevel()
  self:updateGraphicsSettings()
end

function m:updateGraphicsLevel()
  local level = QualityUtil.getQualityLevel('smart')
  -- logd('updateGraphicsLevel: recommended level=%s self.level=%s', tostring(level), tostring(self.level))
  self.quality_level1_icnTJ:setVisible(level == 'low')
  self.quality_level1_btn.button:setOn(self.level == 'low')
  self.quality_level2_icnTJ:setVisible(level == 'medium')
  self.quality_level2_btn.button:setOn(self.level == 'medium')
  self.quality_level3_icnTJ:setVisible(level == 'high')
  self.quality_level3_btn.button:setOn(self.level == 'high')
  self.quality_level4_icnTJ:setVisible(level == 'ultra')
  self.quality_level4_btn.button:setOn(self.level == 'ultra')
  self.quality_level5_icnTJ:setVisible(level == 'insane')
  self.quality_level5_btn.button:setOn(self.level == 'insane')
end

function m:onQuality_level1_btn()
  if not self:equalSettings('low') then
    ui:push(CommonPopup.new({
      strDesc = loc('str_graphics_quality_goes_shit_confirm'),
      rightCallback = function()
        ui:pop()
        self:setGraphicsLevel('low')
      end,
      leftCallback = function()
        ui:pop()
        self:updateGraphicsLevel()
      end,
      closeCallback = function()
        ui:pop()
        self:updateGraphicsLevel()
      end,
    }))
  else
    self:setGraphicsLevel('low')
  end
end

function m:onQuality_level2_btn()
  self:setGraphicsLevel('medium')
end

function m:onQuality_level3_btn()
  self:setGraphicsLevel('high')
end

function m:onQuality_level4_btn()
  self:setGraphicsLevel('ultra')
end

function m:onQuality_level5_btn()
  self:setGraphicsLevel('insane')
end

function m:setGraphicsLevel(t)
  -- do not auto set music and sound
  logd('setGraphicsLevel: t=%s', tostring(t))
  local music = self.settings.music
  local sound = self.settings.sound
  local resolution = self.settings.resolution

  self.settings = QualityUtil.getQualitySettings(t)

  self.settings.music = music
  self.settings.sound = sound

  if t == 'power_saving' then
    self.settings.resolution = resolution
  end

  self:updateGraphics()
  self.level = self:decideLevel()
  self:updateGraphicsLevel()
end

function m:equalSettings(t)
  local settings = QualityUtil.getQualitySettings(t)
  for k, v in pairs(settings) do
    if k ~= 'music' and k ~= 'sound' and
      k ~= 'cameraStatus' and
      self.settings[k] ~= v then
      -- logd('equalSettings: k=%s %s=%s mine=%s', k, t, tostring(v), tostring(self.settings[k]))
      return false
    end
  end
  return true
end

function m:decideLevel()
  local level = 'custom'
  if self:equalSettings('low') then
    level = 'low'
  elseif self:equalSettings('medium') then
    level = 'medium'
  elseif self:equalSettings('high') then
    level = 'high'
  elseif self:equalSettings('ultra') then
    level = 'ultra'
  elseif self:equalSettings('insane') then
    level = 'insane'
  end
  return level
end

function m:onGraphicsSettingsChanged()
  if self.settings.enableHighQuality or self.settings.enableBloomHdr or self.settings.enableFXAA then
    self.settings.enablePostEffects = true
  elseif not self.settings.enableHighQuality and not self.settings.enableBloomHdr and not self.settings.enableFXAA then
    self.settings.enablePostEffects = false
  end

  self.level = self:decideLevel()
  self:updateGraphics()
end

function m:updateGraphicsSettings()
  if self.settings.resolution == 1 then
    self.quality_res3_btn.button:setOn(true)
  elseif self.settings.resolution == 0.8 then
    self.quality_res2_btn.button:setOn(true)
  elseif self.settings.resolution == 0.6 then
    self.quality_res1_btn.button:setOn(true)
  end

  if self.settings.targetFrameRate <= QualityUtil.lowFrameRate then
    self.quality_frame1_btn.button:setOn(true)
  elseif self.settings.targetFrameRate == QualityUtil.highFrameRate then
    self.quality_frame2_btn.button:setOn(true)
  end

  self.quality_shadows_btn_on:setVisible(self.settings.enableShadows)
  self.quality_shadows_btn_off:setVisible(not self.settings.enableShadows)

  self.quality_cars_btn_on:setVisible(self.settings.enableMovingCars)
  self.quality_cars_btn_off:setVisible(not self.settings.enableMovingCars)

  if self.settings.particleLevel == 2 then
    self.quality_eff1_btn.button:setOn(true)
  elseif self.settings.particleLevel == 1 then
    self.quality_eff2_btn.button:setOn(true)
  elseif self.settings.particleLevel == 0 then
    self.quality_eff3_btn.button:setOn(true)
  end

  self.quality_maxPlayers_slider.slider.value = self.settings.maxOnScreenPlayers
  self.quality_maxPlayers_slider_txt:setString(tostring(self.settings.maxOnScreenPlayers))

  if self.settings.farClipPlane == 1000 then
    self.quality_clip_level4_btn.button:setOn(true)
  elseif self.settings.farClipPlane == 750 then
    self.quality_clip_level3_btn.button:setOn(true)
  elseif self.settings.farClipPlane == 500 then
    self.quality_clip_level2_btn.button:setOn(true)
  elseif self.settings.farClipPlane == 250 then
    self.quality_clip_level1_btn.button:setOn(true)
  end

  if self.settings.npcClipPlane == 100 then
    self.quality_npc_level4_btn.button:setOn(true)
  elseif self.settings.npcClipPlane == 75 then
    self.quality_npc_level3_btn.button:setOn(true)
  elseif self.settings.npcClipPlane == 50 then
    self.quality_npc_level2_btn.button:setOn(true)
  elseif self.settings.npcClipPlane == 25 then
    self.quality_npc_level1_btn.button:setOn(true)
  end

  self.quality_post_btn_on:setVisible(self.settings.enablePostEffects)
  self.quality_post_btn_off:setVisible(not self.settings.enablePostEffects)
  self.quality_post_high_btn_on:setVisible(self.settings.enableHighQuality)
  self.quality_post_high_btn_off:setVisible(not self.settings.enableHighQuality)
  self.quality_post_hdr_btn_on:setVisible(self.settings.enableBloomHdr)
  self.quality_post_hdr_btn_off:setVisible(not self.settings.enableBloomHdr)
  self.quality_post_aa_btn_on:setVisible(self.settings.enableFXAA)
  self.quality_post_aa_btn_off:setVisible(not self.settings.enableFXAA)

  if self.settings.enablePowerSave then
    self.btnElectricity_choose:setVisible(true)
    self.btnElectricity_txtE:setString(loc('enabled'))
  else
    self.btnElectricity_choose:setVisible(false)
    self.btnElectricity_txtE:setString(loc('disabled'))
  end
end

function m:onQuality_post_btn()
  self.settings.enablePostEffects = (not self.settings.enablePostEffects)
  self.settings.enableHighQuality = self.settings.enablePostEffects
  self.settings.enableBloomHdr = self.settings.enablePostEffects
  self.settings.enableFXAA = self.settings.enablePostEffects
  self:onGraphicsSettingsChanged()
end

function m:onQuality_post_high_btn()
  self.settings.enableHighQuality = (not self.settings.enableHighQuality)
  self:onGraphicsSettingsChanged()
end

function m:onQuality_post_hdr_btn()
  self.settings.enableBloomHdr = (not self.settings.enableBloomHdr)
  self:onGraphicsSettingsChanged()
end

function m:onQuality_post_aa_btn()
  self.settings.enableFXAA = (not self.settings.enableFXAA)
  self:onGraphicsSettingsChanged()
end

function m:onQuality_clip_level1_btn()
  self.settings.farClipPlane = 250
  self:onGraphicsSettingsChanged()
end

function m:onQuality_clip_level2_btn()
  self.settings.farClipPlane = 500
  self:onGraphicsSettingsChanged()
end

function m:onQuality_clip_level3_btn()
  self.settings.farClipPlane = 700
  self:onGraphicsSettingsChanged()
end

function m:onQuality_clip_level4_btn()
  self.settings.farClipPlane = 1000
  self:onGraphicsSettingsChanged()
end

function m:onQuality_npc_level1_btn()
  self.settings.npcClipPlane = 25
  self:onGraphicsSettingsChanged()
end

function m:onQuality_npc_level2_btn()
  self.settings.npcClipPlane = 50
  self:onGraphicsSettingsChanged()
end

function m:onQuality_npc_level3_btn()
  self.settings.npcClipPlane = 75
  self:onGraphicsSettingsChanged()
end

function m:onQuality_npc_level4_btn()
  self.settings.npcClipPlane = 100
  self:onGraphicsSettingsChanged()
end

function m:onMaxPlayers_slider_ValueChanged()
  self.settings.maxOnScreenPlayers = math.floor(self.quality_maxPlayers_slider.slider.value)
  self:onGraphicsSettingsChanged()
end

function m:onQuality_res1_btn()
  self.settings.resolution = 0.6
  self:onGraphicsSettingsChanged()
end

function m:onQuality_res2_btn()
  self.settings.resolution = 0.8
  self:onGraphicsSettingsChanged()
end

function m:onQuality_res3_btn()
  self.settings.resolution = 1
  self:onGraphicsSettingsChanged()
end

function m:onQuality_frame1_btn()
  self.settings.targetFrameRate = QualityUtil.lowFrameRate
  self:onGraphicsSettingsChanged()
end

function m:onQuality_frame2_btn()
  self.settings.targetFrameRate = QualityUtil.highFrameRate
  self:onGraphicsSettingsChanged()
end

function m:onQuality_shadows_btn()
  self.settings.enableShadows = (not self.settings.enableShadows)
  if not self.settings.enableShadows then
    FloatingTextFactory.makeFramed {text = loc('str_will_lower_graphic_quality')}
  end
  self:onGraphicsSettingsChanged()
end

function m:onQuality_eff1_btn()
  self.settings.particleLevel = 2

  if self.settings.particleLevel ~= 0 then
    FloatingTextFactory.makeFramed {text = loc('str_will_lower_graphic_quality3')}
  end
  self:onGraphicsSettingsChanged()
end

function m:onQuality_eff2_btn()
  self.settings.particleLevel = 1

  if self.settings.particleLevel ~= 0 then
    FloatingTextFactory.makeFramed {text = loc('str_will_lower_graphic_quality3')}
  end
  self:onGraphicsSettingsChanged()
end

function m:onQuality_eff3_btn()
  self.settings.particleLevel = 0

  if self.settings.particleLevel ~= 0 then
    FloatingTextFactory.makeFramed {text = loc('str_will_lower_graphic_quality3')}
  end
  self:onGraphicsSettingsChanged()
end

function m:onQuality_cars_btn()
  self.settings.enableMovingCars = (not self.settings.enableMovingCars)
  if not self.settings.enableMovingCars then
    FloatingTextFactory.makeFramed {text = loc('str_will_lower_graphic_quality2')}
  end
  self:onGraphicsSettingsChanged()
end

function m:onBtnElectricity()
  local enablePowerSave = (not self.settings.enablePowerSave)
  if 'zhangfan' then
    if enablePowerSave then
      self:setGraphicsLevel('power_saving')
    else
      self:setGraphicsLevel('smart')
    end
  end
  self.settings.enablePowerSave = enablePowerSave
  self:onGraphicsSettingsChanged()
end

function m:onBtnCancel()
  self:close()
end

function m:onBtnClose()
  self:close()
end

function m:onBtnOK()
  local curViewName = ui:curViewName()
  if curViewName == 'LoginView' then
    self:saveAndClose(true)
  elseif (self.settings.enableShadows ~= self.oldSettings.enableShadows) or
    (self.settings.enableMovingCars ~= self.oldSettings.enableMovingCars) or
    (self.settings.particleLevel ~= self.oldSettings.particleLevel) then
    ui:push(CommonPopup.new({
      strDesc = loc('need_reenter_scene'),
      rightCallback = function()
        ui:pop()
        local scene = cc.scene
        if scene and scene.rid and not scene.campaignType then
          self:saveAndClose(false)
          local options = SceneOptions.new()
          options.sid = scene.rid
          MainSceneFactory.goToScene(options)
        else
          self:saveAndClose(true)
        end
      end,
    }))
  else
    self:saveAndClose(true)
  end
end

function m:saveAndClose(showTip)
  QualityUtil.saveQualitySettings(self.settings)
  QualityUtil.applyQualitySettings(self.settings)

  if self.settings.npcClipPlane ~= self.oldSettings.npcClipPlane then
    if cc.scene and cc.scene.updateLoaderByQuality then
      cc.scene:updateLoaderByQuality()
    end
  end

  if self.settings.maxOnScreenPlayers ~= self.oldSettings.maxOnScreenPlayers then
    if cc.scene and cc.scene.rpc and cc.scene.rpc.setMaxInterests then
      logd('QualityView: set server max interests to %d', self.settings.maxOnScreenPlayers)
      cc.scene.rpc:setMaxInterests(self.settings.maxOnScreenPlayers)
    end
  end

  self:close()

  if showTip then
    FloatingTextFactory.makeFramed {text = loc('saved')}
  end
end

function m:close()
  if self.animControl then
    self.animControl.onAnimEvent = function (param)
      ui:remove(self)
    end
    self.animControl.animator:Play("settings_close")
  else
    ui:remove(self)
  end
end

function m:onBtnExit()
  local curViewName = ui:curViewName()
  if curViewName ~= 'LoginView' then
    cc.savePosWhenLeaveScene = true
    Util.tryExitGame()
  else
    ui:remove(self)
  end
end

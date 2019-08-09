-- LoadingView.lua

View('LoadingView', nil, function(self, options)
  self.options = table.merge({
    visible = true,
    startWhen = 'goto_done',
    bg = 'loading', -- 'loading' or 'update'
    tipFunc = nil, -- tip = tipFunc()
    bundleUI = 'prefab/ui/common/combat_loading',
    mute = true,
  }, options)
  self:constructWithOptions(options)

end)

local AsyncLoadingType = LBoot.AsyncLoadingType
local Mathf = UnityEngine.Mathf
local Time = UnityEngine.Time
local unity = unity
local m = LoadingView

function m:constructWithOptions(options)
  unity.recordTime('LoadingView.constructWithOptions')
  unity.beginSample('LoadingView.constructWithOptions')
  if options.cullingMask then
    self.uiMask = options.cullingMask
    -- loge('setCullingMask %s', self.uiMask)
  else
    self.uiMask = ui:cullingMask('default', 'loading')
  end

  self.noForceUnload = self.options.noForceUnload
  self.nextView = options.nextView

  if self.nextView then
    self.options.assetsPerFrame = self.nextView.assetsPerFrame
  end

  self.__vsIndex = 10
  self:bind(self.options.bundleUI)

  unity.endSample()
end

function m:base_init()
  unity.beginSample('LoadingView.base_init')
  if mp.setRetryFailOp then
    mp:setRetryFailOp("2login")
  end
  if not self.options.visible then
    self:setVisible(false)
  else
    self.scmCount = ui:setCullingMask('loading')
  end

  if self.loading_all_txtLoading then
    self.loading_all_txtLoading:setString("Loading...")
  end

  self.startTime = engine.realtime()
  self:setupLoadingManager()

  local startLoading = function()
    -- leave some room for subsequent loadings
    fullGC(not self.noForceUnload, {
      keepBundlesList = self.loadingManager.bundles,
      onComplete = function()
        self:loadAssets()
      end,
    })
  end

  local startWhen = self.options.startWhen or 'goto_done'
  if startWhen == 'goto_done' then
    self:onGotoDone(startLoading)
  elseif startWhen == 'immediately' then
    startLoading()
  else
    error(string.format('invalid startWhen value: %s', tostring(startWhen)))
  end

  self:update()
  self:schedule(function()
    -- self:updateTips()
  end, 4)
  
  self:scheduleWithLateUpdate(function()
      self:onFrame()
    end)

  unity.endSample()
end

function m:onFrame() 
  if self.nextPercent and self.loading_all_progress and self.loading_all_txtLoading then
    local cur = self.loading_all_progress:getProgress() 
    -- logd("[percent] nextPercent:%s > cur:%s", tostring(self.nextPercent), tostring(cur))
    if self.nextPercent > cur then
      local p = math.lerpf(cur, self.nextPercent, Time.deltaTime)
      self.loading_all_progress:setProgress(p)
      local str = loc('str_loading_combat', loc('%s%%', math.floor(p * 1000) / 10))
      self.loading_all_txtLoading:setString(str)
      -- local sp = self.loading_all_progress_progressCar.transform:get_localPosition()
      -- logd(">>>>>>>>>>>>>>>>sp111:%s",inspect(sp))
      -- if p >= 0.15 then
      --   local carWidth = (p - 0.15) * 592 / 0.85
      --   local x = carWidth - 308
      --   -- logd("[percent] x:%s", tostring(x))
      --   self.loading_all_progress_progressCar.transform:set_localPosition(Vector3(x,27.3,0))
      -- end
    end  
  end
end

function m:onComplete()
  unity.recordTime('LoadingView.onComplete')
  logd('LoadingView.onComplete')
  if self.options.onComplete then
    self.options.onComplete()
  end
  
  if not self.nextView then return end
  self.nextView:signal('sceneReady'):fire()
end

function m:isBroadcastProgress()
  return false
end

function m:getFakeMinPercent()
  if not self.fakeMinPercent then
    self.fakeMinPercent = math.random(20, 40) / 100
  end
  return self.fakeMinPercent
end

function m:setupLoadingManager()
  local function onProgress(info)
    self.info = info
    if not_null(self.loading_all_progress) then
      local percent = info.percent
      -- fake a percent
      -- percent = math.max(percent, self:getFakeMinPercent())
      local cur = info.cur or 0
      local total = info.total or 0
      local nex = cur + 1
      if nex > total then nex = total end
      if total > 0 then
        self.nextPercent = nex / total
      else
        self.nextPercent = 0
      end

      self.curPercent = percent
      logd("[percent]: cur:%s nex:%s", tostring(self.curPercent), tostring(self.nextPercent))

      local str = loc('str_loading_combat', loc('%s%%', math.floor(percent * 1000) / 10))
      if info.tips then
        str = info.tips .. loc('%s%%', math.floor(percent * 1000) / 10)
      end
      
      self.loading_all_txtLoading:setString(str)
      self.loading_all_txtTip:setString(loc('str_loadingTip'..self.num))
      self.loading_all_progress:setProgress(percent)
      
      -- if percent >= 0.15 then
      --   local carWidth = (percent - 0.15) * 592 / 0.85
      --   local x = carWidth - 308
      --   self.x = x
      --   self.loading_all_progress_progressCar.transform:set_localPosition(Vector3(x,27.3,0))
      -- end
      
    end
  end
    
  local function onComplete()
    self:onComplete()
  end
  
  local broadcast = self:isBroadcastProgress()
  local options = {
    broadcast = broadcast,
    tree = self.options.tree,
    onProgress = onProgress,
    onComplete = onComplete,
    mute = self.options.mute,
  }
  self.loadingManager = LoadingManager.new(options)

  onProgress({percent = 0})

  logd('setupLoadingManager done')
end

function m:init()
  unity.recordTime('LoadingView.init')
  unity.beginSample('LoadingView.init')

  self.num = math.random(1,24)
  if self.options.bg == 'loading' then
    self.updateBg:setVisible(false)
    self.loadingBg:setVisible(true)
    self:rangeShowLodingImg()
  else
    self.updateBg:setVisible(true)
    self.loadingBg:setVisible(false)
    self:rangeShowUpdateBgImg()
  end
  -- self.loading_all_progress_progressCar:setVisible(true)
  self.backGroundColor = Color.new(0, 0, 0, 1)
  self:setModal(true)
  self:base_init()
  
  unity.endSample()
end

function m:rangeShowLodingImg()
  local num = math.random(3)
  -- self["loadingBg_img0"..num]:setVisible(true)
end

function m:rangeShowUpdateBgImg()
  local num = math.random(3)
  -- self["updateBg_img0"..num]:setVisible(true)
end

function m:exit()
  unity.recordTime('LoadingView.exit')
  unity.beginSample('LoadingView.exit')

  if mp.setRetryFailOp then
    mp:setRetryFailOp(nil)
  end
  if self.loadingBg then
    for i=1,3 do 
      -- self["loadingBg_img0"..i]:setVisible(false)
    end
  end
  if self.updateBg then   
    for i=1,3 do 
      -- self["updateBg_img0"..i]:setVisible(false)
    end
  end
  -- if self.loading_all_progressCar then 
  --   self.loading_all_progressCar:setVisible(false)
  -- end     
  if self.options.visible then
    ui:resetCullingMask(self.scmCount)
  end
  
  if self.nextView then
    self.nextView:signal('scene_loading'):clear()
  end
  
  if self.nextView and self.startTime then
    logd('LoadingView.exit nextView=%s', self.nextView.classname)
    unity.recordTime('LoadingView.exit', engine.realtime() - self.startTime)
  end

  m.onAssetLoadingProgress = nil
  
  unity.endSample()
end

function m:update()
  unity.beginSample('LoadingView.update')
  -- self:updateTips()
  if self.loading_all_progress then
    self.loading_all_progress:setProgress(0)
    self.loading_all:setVisible(true)
  end
  
  unity.endSample()
end

function m:updateTips()
  unity.beginSample('LoadingView.updateTips')

  local tip = nil
  if self.options.tipFunc then
    tip = self.options.tipFunc()
  else
    local loadingtips = cfg.loadingtips
    tip = loadingtips[math.random(table.getn(loadingtips))]
  end

  if self.loading_all_txtTip then
    self.loading_all_txtTip:setString(tip)
  end

  unity.endSample()
end

function m:loadAssets()
  logd('loadAssets')
  self.loadingManager:start()
end

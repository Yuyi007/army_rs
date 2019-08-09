class("LoadAssetNode", function(self, options)
end, LoadTaskNode)

local m = LoadAssetNode
local unity = unity

m.categories = {
  "scene",
  "bundle",
  "go",
  "ui",
  "view",
  "prefab",
  "sound",
  "character",
  "sheet",
  "cutscene",
  "efx",
  "shader",
  "copyBundle",
  "enterRoom",
  "setTTL",
  "setPatternTTL",
  "func",
  'setPoolMax',
}

function m:construct()
  LoadTaskNode.construct(self)

  self.asset = self.options.asset

  self.category = m.getCategory(self.asset)

  if self.category then
    local uri = self.asset[self.category]
    if type(uri) == 'string' then
      self.name = string.format('[asset:%s] %s', self.category, uri)
    end
  end

  self.name = self.name or tostring(self.asset[self.category])

  self:registerOnFinish(self.asset.onFinished)
end

function m.getCategory(asset)
  for _, v in pairs(m.categories) do
    if asset[v] ~= nil then
      return v
    end
  end
  loge("Asset category is not supported! asset:", inspect(asset))
  return nil
end

function m:startLoad()
  unity.beginSample('LoadAssetNode.startLoad %s', tostring(self.name))
  LoadTaskNode.startLoad(self)
  -- logd(">>>>>>>self.category"..inspect(self.category))
  self["load_"..self.category](self)

  unity.endSample()
end

function m:load_scene()
  -- logd(">>>>>>>self.asset"..inspect(self.asset))
  unity.loadLevelAsync(self.asset.scene, function()
      self:finish()
    end)
end

function m:load_func()
  -- logd(">>>>>>>self.asset"..peek(self.asset))
  self.asset.func()
  self:finish()
end

function m:load_setPoolMax()
  gp:setMax(self.asset.setPoolMax, self.asset.max)
  self:finish()
end

function m:load_bundle()
  if not game.shouldLoadAssetInEditor() then
    logd("load bundle :%s", peek(self.asset.bundle))
    unity.loadBundleAsync(self.asset.bundle, function()
        logd("load bundle success")
        self:finish()
      end, self.asset.ttl)
  else
    scheduler.performWithDelay(0, function()
        self:finish()
      end)
  end
end

function m:load_go()
  gp:poolAsync(self.asset.go, self.asset.total, self.asset.global, self.asset.max, function()
      self:finish()
    end)
end

function m:load_ui()
  gp:poolAsync(self.asset.ui, self.asset.total, self.asset.global, self.asset.max, function(list)
      if list then
        for i = 1, #list do
          local go = list[i]
          if ui.cacheVarnames then
            ui:cacheVarnames(self.asset.ui, go)
          end
        end
      end
      self:finish()
    end)
end

function m:load_prefab()
  gp:getPrefabAsync(self.asset.prefab, function()
      self:finish()
    end)
end

function m:load_sound()
  sm:getClipAsync(self.asset.sound, function()
      self:finish()
    end)
end

function m:load_character()
  gp:poolAsync(self.asset.character, self.asset.total, self.asset.global, self.asset.max, function(list)
      if list then
        for i = 1, #list do
          local go = list[i]
          ClipUtil.initAnimEventsByGameObject(go)
        end
      end
      self:finish()
    end)
end

function m:load_sheet()
  ss:getSheetAsync(self.asset.sheet, function()
      self:finish()
    end)
end

function m:load_cutscene()
  gp:poolAsync(self.asset.cutscene, self.asset.total, self.asset.global, self.asset.max, function(list)
      each(function(go) go:setLayer('UI', true) end, list)
      self:finish()
    end)
end

function m:load_view()
  local viewName = self.asset.view

  local bundleFile = self.asset.view.class.__bundleFile
  ViewFactory.makeAsync(viewName, viewName, bundleFile, function(view)
    self:finish()
    view:destroy()
  end, unpack(self.asset.params))
end

function m:load_efx()
  local count = self.asset.count or 1
  local maxCount = ViewFactory.poolMaxSize('particles')
  if count > maxCount then count = maxCount end
  if count == 0 then self:finish() end

  local remain = count
  local views = {}
  local onLoadOne = function (view)
    if view then
      -- logd('load_efx: onLoadOne view=%s remain=%d', tostring(view.gameObject), remain)
      view:setVisible(false)
      views[#views + 1] = view
    else
      -- logd('load_efx: onLoadOne view=nil remain=%d', remain)
    end
    remain = remain - 1
    if remain == 0 then
      for i = 1, #views do views[i]:destroy() end
      self:finish()
    end
  end

  for i = 1, count do
    local res = self:do_load_efx(self.asset.efx, onLoadOne)
    -- logd('load_efx: i=%d efx=%s res=%s', i, self.asset.efx, tostring(res))
    if res == ParticleFactory.RES_THROTTLED then
      onLoadOne(nil)
    end
  end
end

function m:do_load_efx(efx, onComplete)
  local t = self.asset.type
  if t == 'common' then
    return ParticleFactory.makeWithEfxName(efx, onComplete)
  else
    error(string.format('invalid efx type %s', tostring(t)))
  end
end

function m:load_shader()
  local shaders = ShaderVariantCollection()
  local variant = ShaderVariant(self.asset.shader, self.asset.passType, self.asset.keywords)
  shaders:Add(variant)
  shaders:WarmUp()
  ShaderVariantCollection.Destroy(shaders)
  self:finish()
end

function m:load_copyBundle()
  local srcfile = 'bundles/' .. self.asset.copyBundle
  local dstfile = UpdateManager.rootpath() .. '/bundles/' .. self.asset.copyBundle
  logd('copyBundle: src=%s dst=%s', srcfile, dstfile)
  local path, _exist = prepareFile(dstfile)
  if path then
    FileUtils.CopyFile(srcfile, dstfile, true)
    scheduler.performWithDelay(0, function()
        self:finish()
      end)
  else
    loge('copyBundle: make path failed!')
  end
end


function m:load_setTTL()
  LBoot.BundleManager.SetTTLSettings(self.asset.setTTL, self.asset.ttl or -1)
  self:finish()
end

function m:load_setPatternTTL()
  LBoot.BundleManager.SetPatternTTLSettings(self.asset.setPatternTTL, self.asset.ttl or -1)
  self:finish()
end

function m:getTaskInfo()
  return {tips = self.asset.tips}
end





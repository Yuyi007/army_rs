class('UIManager', function(self, old)
  self:init(old)
end)

local m = UIManager

local LayerMask = UnityEngine.LayerMask
local CameraClearFlags = UnityEngine.CameraClearFlags
local Screen = UnityEngine.Screen
local unity = unity
local bit = bit

local layers = {
  default  = 0,
  cutscene = 1,
  loading  = 2,
  gym      = 3,
  extDialog = 4,
  qucikUse = 5,
}

function m.onClassReloaded(_)
  local ui = rawget(_G, 'ui')
  if ui then
    logd('UIManager reloaded views=%d', #ui:getViews())
    ui:printViewStack()
  end
end

function m:getViews(index)
  index = index or 1
  self.views[index] = self.views[index] or {}
  return self.views[index]
end

function m:iterViews(func)
  local views = {}
  for i,s in pairs(self.views) do
    for j,v in pairs(s) do
      func(v)
    end
  end
end

function m:goto(view)
  unity.recordTime('UIManager.goto')
  unity.beginSample('UIManager.goto')

  logd('UIManager goto %s', view.classname)

  hideKeyboard()

  local loadTree = nil
  if view.getLoadTree then
    loadTree = view:getLoadTree()
  end

  if loadTree then
    if self.loading then
      loge('ui.goto is already in progress:%s', debug.traceback())
      unity.endSample()
      return
    end
  else
    if self.loading then
      if self.loading.loadingManager then
        logd('ui.goto: stop loading')
        self.loading.loadingManager:stop()
      end
      self:removeLoading()
    end
  end

  table.clear(self.actions)
  self.curAction = nil

  if self.curView then
    if self.curView.beforeLeave then
      self.curView:beforeLeave()
    end
  end

  HeavyTaskQueue.flushAll()

  ObjectFactory.clear()
  ViewFactory.clear()
  -- tem:clear()
  self.baseView = nil

  if self.curView then
    -- logd('ui: destroy cur view=%s %s %s', tostring(self.curView),
    --   self.curView.class.classname, debug.traceback())
    -- curView is already destroyed when ViewFactory.clear if it's pooled
    self.curView:destroy(true)
    self.curView = nil
  end

  if loadTree then
    loadTree:iterateBranches(function(taskNode)
      if taskNode.optimizeSceneLoading then
        logd('UIManager: execute optimizeSceneLoading on %s', tostring(taskNode.name))
        taskNode.optimizeSceneLoading()
      end
    end)
  end

  if unity.bindingStats then
    table.clear(unity.bindingStats)
  end

  LBoot.FVParticleScaling.Clear()

  ClipUtil.clear() -- clear the ClipUtil

  self:clearUIRoot({view.gameObject})

  Go.destroyAll()  -- clear go tween static vars
  gp:clear()       -- clear the game object pool
  uoc:clear()      -- clear the unity object cache
  sm:clear()       -- clear the sound manager
  ss:clear()       -- clear the sprite sheet cache
  UIMapper.clear()

  if self.materials then
    for _, v in pairs(self.materials) do
      GameObject.Destroy(v)
    end
    table.clear(self.materials)
  end

  if self.splitAlphaGrayMaterials then
    for _, v in pairs(self.splitAlphaGrayMaterials) do
      GameObject.Destroy(v)
    end
    table.clear(self.splitAlphaGrayMaterials)
  end

  -- DummyNpcMaterialUtil.reset()

  unity.clearAssetLoaders()

  if rawget(_G, 'ParticleScaler') then
    ParticleScaler.Clear()
  end

  self.mask = self:cullingMask('default')

  if not loadTree then
    view:__goto()
  else
    local specialLoading = view.options and view.options.specialLoading
    local options = {tree = loadTree, nextView = view}
    -- if view.options and specialLoading == 'combat' then
    --   self.loading = RoomLoadingView.new(options)
    -- elseif view.options and specialLoading == 'heroSelect' then
    --   self.loading = HeroLoadingView.new(options)
    -- else
      self.loading = LoadingView.new(options)
    -- end
    self.loading:__goto()
  end

  self.curView = view
  -- logd('ui: set curView to %s', peek(view))

  unity.endSample()
end

function m:setCurView(view)
  if self.curView then
    -- logd('ui: destroy cur view=%s %s %s', tostring(self.curView),
    --   self.curView.class.classname, debug.traceback())
    if self.curView.beforeLeave then
      self.curView:beforeLeave()
    end

    self.curView:destroy(true)
    self.curView = nil
  end

  self.curView = view
  -- logd('ui: setCurView view=%s %s %s', tostring(view), view.class.classname, debug.traceback())
end

function m:signal(...)
  self.signals = self.signals or {}
  local t = table.concat({...}, '_')
  if not self.signals[t] then
    self.signals[t] = Signal.new()
  end
  return self.signals[t]
end

function m:removeLoading()
  -- logd("removeLoading:"..debug.traceback())
  if not self.loading then return end
  -- logd('removeLoading: %s', peek(self.loading.classname))
  self.loading:destroy()
  self.loading = nil

  -- This fixes android scratched screen when scene switch
  if game.platform == 'android' then
    UnityEngine.GL.Clear(true, true, Color.black)
  end

  self:signal('loading_removed'):fire()
end

function m:onLoadingRemoved(func, timeout)
  if self.loading == nil then
    func()
  else
    local funcDone = false
    local func2 = function () funcDone = true; func() end
    self:signal('loading_removed'):addOnce(func2)

    if timeout then
      scheduler.performWithDelay(timeout, function ()
        if not funcDone then
          logd('onLoadingRemoved: timeout=%f force do callback', timeout)
          self:signal('loading_removed'):remove(func2)
          func2()
        end
      end)
    end
  end
end

function m:material(shaderName, matName)
  self.materials = self.materials or {}

  local mat = self.materials[shaderName]

  if is_null(mat) then
    mat = Material(Shader.Find(shaderName))
    if matName then
      mat:set_name(matName)
    end
  end

  self.materials[shaderName] = mat

  return mat
end

function m:splitAlphaGrayMaterial(splitAlphaMaterial)
  if splitAlphaMaterial == nil then
    return nil
  end

  self.splitAlphaGrayMaterials = self.splitAlphaGrayMaterials or {}
  local materialName = splitAlphaMaterial:get_name()

  if materialName:match('_gray') and not_null(splitAlphaMaterial) then
    return splitAlphaMaterial
  end

  local mat = self.splitAlphaGrayMaterials[materialName]

  if is_null(mat) then
    mat = Material(splitAlphaMaterial)
    mat:set_name(materialName .. '_gray')
    mat:SetInt ("_gs", 1)
    mat:EnableKeyword ("FV_GRAY_SCALE")
  end

  self.splitAlphaGrayMaterials[materialName] = mat

  return mat
end

function m:grayMat()
  return self:material('Sprites/GrayScale', 'sprite_gray')
end

function m:clearUIRoot(exclude)
  self.baseView = nil
  table.clear(self.views)
  if self.UIRoot then
    -- now we can remove all children without the worrying
    -- of removing any cutscene ui
    unity.removeAllChildren(self.UIRoot, exclude)
  end
end

function m:mainCam()
  return UIUtil.camera()
end

function m:root()
  return self.UIRoot
end

function m:doActionPush(args)
  local view = args.view
  --logd(">>>>>>>do action push: ".. view.classname)
  local hideBase = args.hideBase

  local ok, err = pcall(function()
      view:onLoadComplete(function()
          --logd(">>>>>>>onLoadComplete")
          self:realPush(view, hideBase)
        end)
    end)

  if not ok then
    loge('doActionPush error! view=%s err=%s', view.class.classname, tostring(err))
    self:resetCurAction()
    self:procNextAction()
  end
end

function m:doActionPop(view)
  -- logd(">>>>>>>doActionPop view=%s", view.class.classname)
  view.popFun(function()
    local ok, err = pcall(function()
      self:_processAfterViewPopFun(view)
      end)
    -- logd(">>>>>>>ok=%s view=%s", tostring(ok), view.class.classname)
    -- logd(">>>>>>>err=%s view=%s", tostring(err), view.class.classname)
    if not ok then
      loge('doActionPop error! view=%s err=%s', view.class.classname, tostring(err))
      self:resetCurAction()
      self:procNextAction()
    end
  end)

end

function m:addAction(action)
  self.actions = self.actions or {}
  table.insert(self.actions, action)
  -- for i,v in pairs(self.actions) do
  --   logd(">>>>>>>v.name:"..inspect(v.name))
  -- end
  self:procNextAction()
end

function m:resetCurAction()
  self.curAction = nil
end

function m:procNextAction()
  if self.curAction then return end
  if not self.actions then return end
  if #self.actions == 0 then return end

  local action = self.actions[1]
  table.remove(self.actions, 1)
  self.curAction = action
  self["doAction"..action.name](self, action.args)
end

function m:init(old)
  self.actions = {} -- 带有动画的异步操作，需要通过action来逐个操作

  self.UIRoot = TransformCollection.create('UIRoot')
  self:initUICamera()
  self:init3DUILight()
  self:initScaleMode()

  self.views = {}

  self.baseView = nil
  self.uniqueNames = {}
  self.mask = self:cullingMask('default')

  if old then
    if old.curView then
      logd('ui: old instance curView=%s %s', tostring(old.curView), old.curView.classname)
      --  this would overwrite curView from UpdatingScene to an old LoginView
      -- self.curView = old.curView
      if self.curView == nil or self.curView.classname == old.curView.classname then
        logd('ui: set curView=%s to old instance', tostring(self.curView))
        self.curView = old.curView
      end
      old.curView = nil
    end
  end
end

function m:getCullingMaskCallCount()
  return self.__scmCount
end

function m:incrCullingMaskCallCount()
  self.__scmCount = self.__scmCount or 0
  self.__scmCount = self.__scmCount + 1
  if self.__scmCount > 65535 then
    self.__scmCount = 0
  end
end

function m:resetCullingMask(scmCount, cmValue)
  cmValue = cmValue or 'default'
  -- logd('UIManager resetCullingMask %s, %s, %s, %s', peek(scmCount) ,peek(self.__scmCount), peek(cmValue), debug.traceback())
  if scmCount == self.__scmCount then
    self:setCullingMask(cmValue)
  end
end

-- set the uimanager to a particular culling mask
-- where only the specicified view with valid uiMask can be visible
function m:setCullingMask(...)
  -- logd(">>>>>>>debug.traceback:"..debug.traceback())
  -- local inputVal = {...}
  -- logd('UIManager setCullingMask %s, %s, %s', peek(inputVal), peek(self.__scmCount), debug.traceback())

  self:incrCullingMaskCallCount()
  local mask = self:cullingMask(...)
  if self.mask == mask then
    return self.__scmCount
  end

  self.mask = mask
  for go in self:root():iter() do
    local view = go:findLua()
    if view and (not view.destroyed) and view.updateCanvasVisibility then
      view:updateCanvasVisibility(mask)
    end
  end

  return self.__scmCount
end

function m:initUICamera()
  self.UICamera = GameObject.Find('/UICamera') or GameObject('UICamera')
  GameObject.DontDestroyOnLoad(self.UICamera)

  -- if game.android() then
  -- -- if true then
    self:setToCameraSpace()
  -- else
    -- self:setToScreenSpace()
  -- end

  -- fix the init screen flickering
  if self.camera then self.camera.enabled = false; self.camera.enabled = true end
end

function m:init3DUILight()
  self.UI3DLight = GameObject.Find('/UI3DLight')
  if not self.UI3DLight then
    local lightGo = GameObject()
    local lightCo = lightGo:AddComponent(UnityEngine.Light)
    lightGo.transform:set_eulerAngles(Vector3(60, 337, 207))
    lightGo.name = "UI3DLight"
    lightCo.color = Color(1,1,1,1)
    lightCo.type = UnityEngine.LightType.Directional
    lightCo.cullingMask = unity.getCullingMask("3DUI")
    self.UI3DLight = lightGo
  end

  GameObject.DontDestroyOnLoad(self.UI3DLight)
end

function m:layerBit(name)
  if not layers[name] then return 0 end
  return bit.lshift(1, layers[name])
end

function m:cullingMask(...)
  local arg = {...}
  local b = 0
  for i = 1, #arg do local v = arg[i]
    if v == 'none' then
      return self:cullingNone()
    end

    if v == 'all' then
      return self:cullingAll()
    end

    b = bit.bor(b, self:layerBit(v))
  end

  return b
end

function m:cullingNone()
  return 0
end

function m:cullingAll()
  return reduce(function(b, k, v) return bit.bor(b, self:layerBit(k)) end, 0, layers)
end

function m:baseViewVisible()
  return self.baseView and not self.baseView.destroyed and self.baseView.visible
end

function m:setBaseView(view)
  --self:adjustRenderMode(view)
  self.baseView = view
  self.baseView:setParent(self.UIRoot)
  self.baseView:updateCanvasVisibility()
end

function m:shouldCheckBaseView(vsIndex)
  return vsIndex == 1
end

function m:adjustRenderMode(view)
  if self.renderMode == RenderMode.ScreenSpaceCamera then
    view:setToScrenceSpaceCamera()
  else
    view:setToScrenctSpaceOverlay()
  end
end

function m:realPush(view, hideBase)
  --self:adjustRenderMode(view)
  local vsIndex = view:getViewStackIndex()
  local stack = self:getViews(vsIndex)
  local vsSize = #stack
  local viewBelow = stack[vsSize] or self.baseView

  if hideBase == nil then
    hideBase = true
  end

  if self.baseView and
     hideBase and
     self:shouldCheckBaseView(vsIndex) then
     self.baseView:setVisible(false)
  end

  stack[vsSize + 1] = view

  if viewBelow and
    viewBelow.onPushFront and
    type(view.onPushFront) == "function" then
    viewBelow:onPushFront()
    if view:fullscreen() then
      viewBelow:setVisible(true)
    end
  end

  self:hideSceneEnter(view)

  --bring to front
  -- adjust depths of all the views when add new ui
  -- this can ensure all the views have a ascending depth or order values.
  -- otherwise, when you pop a view in the middle of self.views, the next pushed
  -- view will have the save depth value with the one on the top previously
  --view:setDepth(#self.views * 20)
  self:adjustAllDepths()

  -- self:printViewStack('after adjustAllDepths')

  local playAnim = function()
    local hasAnim = self:addPushAnimByType(view)
    view:bringToFront()
    -- view:setVisible(true)
    view:updateCanvasVisibility()
    view:signal('pushed'):fire(view)
    if not hasAnim then
      self:signal('pushed'):fire(view)
    end
  end
  if view.sigInited then
    view.sigInited:addOnce(playAnim)
  else
    playAnim()
  end
end

function m:pushNoAnim(view)
  self:push(view, nil, nil, nil, true)
end

function m:push(view, zoffset, hideBase, dontHideIndicator)
  if view == nil then
    return
  end
  logd("UIManager:push: %s", view.classname)
  -- logd("UIManager:push: %s, %s", view.classname, debug.traceback())
  local qs = QualityUtil.cachedQualitySettings()
  view.animType = view.animType or view.oldAnimType
  if not qs.uianimation then
    view.oldAnimType = view.animType
    view.animType = nil
    view.popFun = nil
    view.pushFun = nil
  end

  --self:printViewStack('before push')
  if not dontHideIndicator then
     self:signal('hideIndicator'):fire()
  end
  
  --logd(">>>>>>>view.animType"..inspect(view.animType))
  if view.animType then
    --logd(">>>>>push async")
    view:onLoadComplete(function()
      view:setVisible(false)
    end)
    self:addAction({name = "Push", args = {view = view, hideBase = hideBase}})
  else
    --logd(">>>>>>>push sync")
    view:onLoadComplete(function(view)
      self:realPush(view, hideBase)
      -- self:printViewStack('after real push')
    end)
  end
  
  return view
end


function m:adjustAllDepths()
  for si, stack in pairs(self.views) do
    if type(si) == "number" then

      local depthBase = si * 100
      for i = 1, #stack do local v = stack[i]
        v:setDepth(depthBase + i)
        if v.onDepthChange then
          v:onDepthChange(depthBase + i)
        end
        
      end
    end
  end
end

function m:setAnimType()

end

function m:addPushAnimByType(view)
  local onPushComplete = function ()
    self:resetCurAction()
    self:procNextAction()
    self:signal('pushed'):fire(view)
  end
  local onPopComplete = function ()
    self:resetCurAction()
    self:procNextAction()
    self:signal('removed'):fire(view)
  end

  --logd('addPushAnimByType viewname: %s, %s', view.classname, peek(view.animType))

  if view.animType == "level1" then
    UIUtil.addMainHollowAnim(view, onPushComplete, onPopComplete)
  elseif view.animType == "level2" then
    UIUtil.addSubScreenUIAnim(view, onPushComplete, onPopComplete)
  elseif view.animaType == "rotate1" then 
    UIUtil.addSubScreenRotateUIAnim(view, onPushComplete, onPopComplete)
  elseif view.animType == "black" then
    UIUtil.addBlackSwitchAnim(view, onPushComplete, onPopComplete)
  elseif view.animType == "level2_fullscreen" then
    UIUtil.addSubFullScreenUIAnim(view, onPushComplete, onPopComplete)
  elseif view.animType == "camera" then
    UIUtil.addCameraUIAnim(view, onPushComplete, onPopComplete)
  else
    return false
  end

  return true
end

-- TO join root is for ScreenSpace UIs to be properly sorted
-- by parenting to the same gameObject
local WorldSpace = RenderMode.WorldSpace


function m:joinRoot(view)
  local canvas = view.canvas
  local scaler = view.canvasScaler

  if canvas == nil then return end

  if canvas:get_renderMode() == WorldSpace then
    if scaler then
      scaler:set_physicalUnit(5)
      scaler:set_dynamicPixelsPerUnit(5)
    end
    return
  end

  view:setParent(self.UIRoot)

  --View visibility setting was moved to view2d:on_post_init
  --to prevent view show before view initilized
end

function m:setToCameraSpace()
  self.renderMode = RenderMode.ScreenSpaceCamera
  self.camera = self.UICamera:GetComponent(Camera)
  if not self.camera then
    self.camera = self.UICamera:AddComponent(Camera)
  end
  self.camera:set_enabled(true)
  self.camera:get_transform():set_position(Vector3(1000, 0, -200))
  self.camera:set_orthographic(true)
  self.camera:set_clearFlags(CameraClearFlags.Depth)
  self.camera:set_depth(9999999)
  self.camera:set_useOcclusionCulling(false) -- UI can be blocked by scene models
  self.camera:set_cullingMask(unity.getCullingMask('UI'))
end

function m:enableUICamera()
  if self.camera then
    self.camera.enabled = true
  end
end

function m:setToScreenSpace()
  self.renderMode = RenderMode.ScreenSpaceOverlay
  local camera = self.UICamera:GetComponent(Camera)
  if camera then camera:set_enabled(false) end
  self.camera = nil
end


function m:initScaleMode()
  local size = game.fullSize
  local sw, sh = size.width, size.height
  logd("[scale] sw:%s sh:%s", tostring(sw), tostring(sh))
  self.scaleFactor = size.height / 640
  self.baseScalerFactor = self.scaleFactor
  logd('ui scale factor is %s', self.scaleFactor)
end

function m:height()
  return game.fullSize.height / self.baseScalerFactor
end

-- add abitrary gameObject to the UIRoot
function m:addChild(go)
  self.UIRoot:addChild(go:get_transform(), false)
end

function m:popAll(vsIndex)
  logd("UIManager:popAll vsIndex=%s trace=%s", peek(vsIndex), debug.traceback())
  local num = #self:getViews(vsIndex)
  self:pop(num)
end

function m:pop(num, vsIndex)
  -- logd("UIManager:pop num=%s vsIndex=%s trace=%s", peek(num), peek(vsIndex), debug.traceback())
  num = num or 1
  for i = 1, num do
    -- logd('_pop i=%s', i)
    self:_pop(vsIndex)
  end
end


function m:_pop(vsIndex)
  local stack = self:getViews(vsIndex)
  -- logd('_pop vsIndex=%s stack=%s', tostring(vsIndex), peek(stack))
  local length = #stack
  if length == 0 then return end
  local oldView = stack[length]
  table.remove(stack, length)

  --self:hideSceneExit(oldView, stack)
  -- logd('_pop vsIndex=%s popFun=%s', tostring(vsIndex), tostring(oldView.popFun))
  if oldView.popFun then
    self:addAction({name = "Pop", args = oldView})
  else
    self:_processAfterViewPopFun(oldView)
  end
end

function m:_processAfterViewPopFun(oldView)
  -- logd(">>>>>>>oldView.classname:"..inspect(oldView.classname))
  local vsIndex = oldView:getViewStackIndex()
  oldView:_popAnimation(function(oldView)
    oldView:destroy()

    -- Use table.remove seems to be 'more' correct
    -- under some circumstances
    -- but still buggy when you push and pop several times
    -- in one frame.
    -- MAYBE a push pop queue could solve this.
    --self.views[length] = nil

    -- logd('_processAfterViewPopFun %s %s', #self:getViews(vsIndex), self:shouldCheckBaseView(vsIndex))

    if #self:getViews(vsIndex) > 0 then
      local view = self:top(vsIndex)
      logd("_processAfterViewPopFun 1 top name=%s", view.classname)
      view:setVisible(true)
      if view.onPopFront and type(view.onPopFront) == "function" then
        view:onPopFront()
      end
    elseif self:shouldCheckBaseView(vsIndex) then
      logd('_processAfterViewPopFun 2')
      self:showBaseView()

      local view = self.baseView
      if view and view.onPopFront and
        type(view.onPopFront) == "function" then
        view:onPopFront()
      end
    end

    self:signal('removed'):fire(oldView)
  end)
end


function m:popView(view)
  local vsIndex = view:getViewStackIndex()
  local realIndex = 0
  local stack = self:getViews(vsIndex)
  for i, v in ipairs(stack) do
    if v == view then
      realIndex = i
      break
    end
  end
  if realIndex > 0 then
    table.remove(stack, realIndex)
  end
  self:destroyView(view, stack)
end

function m:printViewStack(prefix)
  prefix = prefix or ''
  -- logd('%s printViewStack stack: %s', prefix, debug.traceback())
  local strRes = string.format("printViewStack size: %s\n", peek(self:getViews() and #self:getViews()))
  for k, v in pairs(self:getViews()) do
    strRes = strRes .. string.format("  %s,  %s\n", peek(k), peek(v and v.classname))
  end
  logd(strRes)
end

function m:remove(view)
  -- self:printViewStack('before remove')
  if view == nil then return end
  local key, vsIndex = self:findViewIndex(view)
  local stack = self:getViews(vsIndex)
  if key then
    view = stack[key]
    if key > 1 then
      local viewBelow = stack[key - 1]
      local top = self:top()
      if viewBelow.onPopFront and type(viewBelow.onPopFront) == "function" then
        viewBelow:onPopFront()
        if viewBelow == top then
          viewBelow:setVisible(true)
        end
      end
    end
    table.remove(stack, key)
  end

  if type(view) == 'table' and view ~= self.baseView then
    self:destroyView(view, stack)
  end

  -- self:printViewStack('after remove')

  -- local top = self:top()
  -- if top then top:setVisible(true) end
  if #stack == 0 and
     self:shouldCheckBaseView(vsIndex) then
    self:showBaseView()
  end

  self:signal('removed'):fire(view)
end

function m:forceRemoveNumofView(num, vsIndex)
  local viewStack = self:getViews(vsIndex)
  local minNum = #viewStack - num
  if minNum < 1 then
    minNum = 1
  end
  for i = #viewStack, minNum, -1 do
    local view = viewStack[i]
    table.remove(viewStack, i)
    self:destroyView(view, viewStack)
    self:signal('removed'):fire(view)
  end
end

function m:showBaseView()
  if self.baseView and not self.baseView.destroyed then
    self.baseView:setVisible(true)
    self:signal('base_show'):fire()
  end
end


function m:hideBaseView()
  if self.baseView and not self.baseView.destroyed then
    self.baseView:setVisible(false)
  end
end

function m:findViewIndex(view)
  if type(view) == 'table' then
    for si, stack in pairs(self.views) do
      for k, v in pairs(stack) do
        if v == view then
          return k, si
        end
      end
    end
  elseif type(view) == 'string' then
    local name = view
    for si, stack in pairs(self.views) do
      for k, v in pairs(stack) do
        if v.classname == name then
          return k, si
        end
      end
    end
  end

  return nil
end

function m:removeWithName(name)
  if name == nil then return end
  self:remove(name)
end

function m:top(vsIndex)
  local stack = self:getViews(vsIndex)
  local length = table.getn(stack)
  return stack[length]
end

function m:topModal(vsIndex)
  local top = self:top(vsIndex)
  if not top then return false end
  return top.isModal
end

function m:topStackTopView()
  local max = -9999999
  local tstop = nil
  for k, v in pairs(self.views) do
    local ctop = self:top(k)
    if ctop then
      max = math.max(max, k)
      tstop = ctop
    end
  end
  return max, tstop
end

-- FIXME topViewName semantics seems changed from former projects
function m:topViewName(vsIndex)
  local view = self:top(vsIndex)
  if view and view.class then
    return view.class.classname
  else
    return ''
  end
end

-- add curViewName to work like former projects topViewName()
function m:curViewName()
  local view = self.curView
  -- logd('ui: curViewName self.curView=%s', peek(view))
  -- logd('ui: curViewName self.views=%s', peek(self.views))
  if view and view.class then
    return view.class.classname
  else
    return ''
  end
end

function m:findViewName(name, vsIndex)
  for k, v in pairs(self:getViews(vsIndex)) do
    if v.class.classname == name then
      return true
    end
  end
  return false
end

function m:findViewAndIndexByName(name)
  local index, vsIndex = self:findViewIndex(name)
  return self:findViewByName(name, vsIndex)
end

function m:findViewByName(name, vsIndex)
  for k, v in pairs(self:getViews(vsIndex)) do
    if v.class.classname == name then
      return v, vsIndex
    end
  end
  return false, vsIndex
end

function m:destroyView(view, stack)
  view:destroy()
  self:hideSceneExit(view, stack)
end

function m:hideSceneEnter(view)
  if view:hideScene() then
    self:signal('pushed'):addOnce(function ()
      if cc.camera then
        logd('[hideScene] %s disable scene camera', view.class.classname)
        cc.camera:setVisible(false)
      end
    end)
  end
end

function m:hideSceneExit(view, stack)
  if view:hideScene() then
    local showScene = true
    for i = 1, #stack do
      local view2 = stack[i]
      if view2:hideScene() then
        logd('[hideScene] %s cannot enable because %s still showing',
          view.class.classname, view2.class.classname)
        showScene = false
        break
      end
    end
    if showScene and cc.camera then
      logd('[hideScene] %s enable scene camera', view.class.classname)
      cc.camera:setVisible(true)
    end
  end
end

local match = string.match

local CanvasScaler = UnityEngine.UI.CanvasScaler
local Canvas = UnityEngine.Canvas

local PREUNLOADS = {
  food      = true,
  npc       = true,
  wushuhall = true,
}

function m:cacheVarnames(bundleFile, gameObject)
  local transform = gameObject:get_transform()
  -- local canvas = gameObject:getComponent(Canvas)

  -- if canvas then
  --   local canvasScaler = gameObject:getComponent(CanvasScaler)
  --   ui:setupCanvasScale(canvas, canvasScaler)
  -- end

  -- pre-cache the components used in ViewNode
  local bindableNodes, paths = BundlePathCacher.get(bundleFile, transform)
  for i = 1, #bindableNodes do
    local nodeTransform = bindableNodes[i]
    local path = paths[i]
    local comps = gp:getComponents(nodeTransform:get_gameObject(), bundleFile)
  end

  gp:getComponents(gameObject, bundleFile)
end






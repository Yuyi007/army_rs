class('UIUtil')

local Texture2D            = UnityEngine.Texture2D
local RectTransformUtility = UnityEngine.RectTransformUtility
local RectTransform        = UnityEngine.RectTransform
local Rect                 = UnityEngine.Rect
local GameObject           = UnityEngine.GameObject
local Color                = UnityEngine.Color
local Gizmos               = UnityEngine.Gizmos
local CanvasGroup          = UnityEngine.CanvasGroup
local CanvasRenderer       = UnityEngine.CanvasRenderer
local floor                = math.floor

local m = UIUtil
m.dirNum = 360

function m.pointInCtrl(ctrl, pos, cam, excludes)
  cam = cam or ui.camera
  local ctrlGo = ctrl.gameObject
  if is_null(ctrlGo) then return false end
  if not ctrlGo:isVisibleInScene() then return false end


  if excludes then
    local exclude = excludes[ctrlGo]
    if exclude then
      return false
    end
  end

  local rectTransform = ctrlGo:GetComponent(RectTransform)
  if rectTransform then
    local cr = ctrlGo:GetComponent(CanvasRenderer)
    return cr ~= nil and RectTransformUtility.RectangleContainsScreenPoint(rectTransform, pos, cam)
    -- return cr ~= nil and rectTransform.rect:Contains(pos)
  else
    return false
  end
end

function m.initMainCameraCtrlRects(self)
  local scene = cc.scene
  scene:onSceneReady(function ()
    cc.onMainUIShown(function ()
      m.doInitMainCameraCtrlRects(self)
    end)
  end)
end

function m.doInitMainCameraCtrlRects(self)
  local excludeCtrls = setmetatable({}, {__mode='k'})
  if ui.loading then
    excludeCtrls[ui.loading.gameObject] = true
  end

  self.refreshCtrlRects = function ()
    self:forceTouchEnd()

    if not self.fullScreenCtrlRects then
      m.initFullScreenCtrlRects(self)
    end

    if cc.mainUI and (cc.mainUI.visible or cc.mainUI.canvas:get_enabled()) then
      if not self.mainUICtrlRects then
        self.mainUICtrlRects = UIUtil.buildCtrlRects(cc.mainUI.gameObject, nil, excludeCtrls, true)
      end
      -- block all clicks to main scene outside the mainUI area
      self.ctrlRects = self.mainUICtrlRects
    else
      -- block all clicks to main scene
      self.ctrlRects = self.fullScreenCtrlRects
    end
  end

  ui:signal('pushed'):add(self.refreshCtrlRects)
  ui:signal('removed'):add(self.refreshCtrlRects)

  self.refreshCtrlRects()
end

function m.initFullScreenCtrlRects(self)
  self.fullScreenCtrlRects = { Rect(0, 0, game.size.width, game.size.height) }
end

function m.buildCtrlRects(ctrl, cam, excludes, skipExcludesChildren, skipRoot)
  -- NOTE camera is not used for now
  cam = cam or ui.UICamera:GetComponent(Camera)

  -- logd('buildCtrlRects: ctrl=%s trace=%s', tostring(ctrl), debug.traceback())
  local rects = {}
  m.addCtrlRectsRecursive(rects, ctrl, ctrl, cam, excludes, skipExcludesChildren, skipRoot)
  -- logd('buildCtrlRects: ctrl=%s rects=%d', tostring(ctrl), #rects)

  table.sort(rects, function (a, b)
    return a:get_width() * a:get_height() > b:get_width() * b:get_height()
  end)
  -- logd('buildCtrlRects: sorted=%d', #rects)

  local leftBottom, rightTop = Vector2(0, 0), Vector2(0, 0)
  for i = #rects, 1, -1 do
    for j = 1, #rects do
      -- remove rects[i] if rects[j] contains rects[i]
      if j ~= i then
        local r1, r2 = rects[j], rects[i]
        leftBottom[1] = r2:get_xMin()
        leftBottom[2] = r2:get_yMin()
        rightTop[1] = r2:get_xMax()
        rightTop[2] = r2:get_yMax()
        if r1:Contains(leftBottom) and r1:Contains(rightTop) then
          -- logd('buildCtrlRects: removing rect %d %s %s', i, tostring(r2), tostring(r1))
          table.remove(rects, i)
          break
        else
          -- logd('buildCtrlRects: i=%d rect=%s', i, tostring(r2))
        end
      end
    end
  end
  -- logd('buildCtrlRects: optimized=%d %s', #rects, table.listToString(rects))
  -- logd('buildCtrlRects: optimized=%d trace=%s', #rects, debug.traceback())
  -- logd('buildCtrlRects: optimized=%d', #rects)

  return rects
end

local fullScreenLeftBottom, fullScreenRightTop

function m.addCtrlRectsRecursive(rects, root, ctrl, cam, excludes, skipExcludesChildren, skipRoot)
  local ctrlGo = ctrl.gameObject
  -- logd('addCtrlRectsRecursive: ctrl=%s', tostring(ctrl))

  -- fix for TransformCollection
  if not ctrlGo then
    for go in ctrl:iter() do
      m.addCtrlRectsRecursive(rects, root, go, cam, excludes, skipExcludesChildren, skipRoot)
    end
    return
  end

  local cg = ctrlGo:GetComponent(CanvasGroup)
  if cg and not cg:get_blocksRaycasts() then
    -- logd('addCtrlRectsRecursive: ctrl %s no blocking canvas group', tostring(ctrl))
    return
  end

  local exclude = false
  if excludes then
    exclude = excludes[ctrlGo]
  end

  local canvas = ctrlGo:getComponent(Canvas)
  if canvas and not canvas:get_enabled() then
    return
  end

  if not exclude then
    if skipRoot and root == ctrl then
      -- skip root rect
      -- logd("addCtrlRectsRecursive: ctrl %s skipped becaused it's root", tostring(ctrl))
    else
      -- add this rect
      local rectTransform = ctrlGo:GetComponent(RectTransform)
      if rectTransform then
        local cr = ctrlGo:GetComponent(CanvasRenderer)
        if cr ~= nil and ctrlGo:isVisibleInScene() then
          local screenRect = m.getScreenRect(rectTransform)
          if screenRect then
            local size = screenRect:get_size()
            -- logd('addCtrlRectsRecursive: go=%s height=%d screen=%s',
            --   tostring(ctrlGo), Screen.height, tostring(screenRect))
            if size[1] < 90 and size[2] < 90 then
              -- logd('addCtrlRectsRecursive: ignore small rect')
            else
              rects[#rects + 1] = screenRect
            end

            if not fullScreenLeftBottom then
              fullScreenLeftBottom = Vector2.new(20, 20)
              fullScreenRightTop = Vector2.new(game.size.width - 20, game.size.height - 20)
            end

            if screenRect:Contains(fullScreenLeftBottom) and screenRect:Contains(fullScreenRightTop) then
              -- logd('addCtrlRectsRecursive: got full screen rect %s, ignore all others', tostring(ctrlGo))
              return
            end
          end
        else
          -- logd("addCtrlRectsRecursive: ctrl %s skipped becaused it's invisible", tostring(ctrl))
        end
      else
        -- logd('addCtrlRectsRecursive: ctrl %s skipped becaused it has no rect transform', tostring(ctrl))
      end
    end
  elseif skipExcludesChildren then
    -- skip all excluded children rects
    -- logd("addCtrlRectsRecursive: ctrl %s skipped becaused it's excluded", tostring(ctrl))
    return
  end

  -- continue to add children rects
  for go in ctrlGo:iter() do
    m.addCtrlRectsRecursive(rects, root, go, cam, excludes, skipExcludesChildren, skipRoot)
  end
end

function m.getScreenRect(rectTransform)
  local rect = rectTransform:get_rect()
  local rectSize = rect:get_size()
  if rectSize[1] > 0 and rectSize[2] > 0 then
    local uiCamera = ui.camera
    if uiCamera then
      local size = rectSize
      local pos0 = rectTransform:get_position()
      local pos = uiCamera:WorldToScreenPoint(pos0)
      if game.platform ~= 'editor' then
        size[1] = size[1] * unity.resolution
        size[2] = size[2] * unity.resolution
      end

      local pivot = rectTransform:get_pivot()
      local screenPos = Vector2(pos[1] - size[1] * pivot[1], pos[2] - size[2] * pivot[2])
      -- logd('scale=%s scaleFactor=%s size=%s pos0=%s pos=%s pivot=%s screenPos=%s uiCamera=%s',
      --   tostring(scale), tostring(ui.scaleFactor), tostring(size), tostring(pos0), tostring(pos),
      --   tostring(pivot), tostring(screenPos), tostring(uiCamera))
      local screenRect = Rect(screenPos, size)
      return screenRect
    else
      local scale = rectTransform:get_lossyScale()
      local size = Vector2.Scale(rectSize, scale)
      local pos = rectTransform:get_position()
      local pivot = rectTransform:get_pivot()
      local screenPos = Vector2(pos[1] - size[1] * pivot[1], pos[2] - size[2] * pivot[2])
      local screenRect = Rect(screenPos, size)
      -- logd('no cam scale=%s size=%s pos=%s pivot=%s screenPos=%s', tostring(scale),
      --   tostring(size), tostring(pos), tostring(pivot), tostring(screenPos))
      return screenRect
    end
  else
    return nil
  end
end

function m.initCtrlRectPointCache()
  m.ctrlRectPointCache = setmetatable({}, {__mode='k'})
end

m.initCtrlRectPointCache()

-- use this as an optimized version of pointInCtrlRecursive etc.
function m.pointInCtrlRects(rects, pos)
  -- logd('[touchbtn] pos=%s rects=%d trace=%s', tostring(pos), #rects, debug.traceback())
  local cache = m.ctrlRectPointCache[rects]
  local code = floor(pos[1]) * 10000 + floor(pos[2])
  if cache then
    local res = cache[code]
    if res ~= nil then
      -- logd('[touchbtn] fast return pos=%s code=%d res=%s', tostring(pos), code, tostring(res))
      return res
    end
  else
    cache = {}
    m.ctrlRectPointCache[rects] = cache
  end

  for i = 1, #rects do
    local rect = rects[i]
    -- logd("[touchbtn] rect:%s %s %s %s", tostring(rect.x), tostring(rect.y), tostring(rect.width), tostring(rect.height))
    if rect:Contains(pos, true) then
      cache[code] = true
      return true
    end
  end

  cache[code] = false
  return false
end

function m.pointInTipDisplayRect(node, pos, cam, excludes)
  if not node.ctrlRects then
    node.ctrlRects = m.buildCtrlRects(node, cam, excludes, false, true)
  end

  local res = m.pointInCtrlRects(node.ctrlRects, pos)
  return res
end

local twoPi = 2 * math.pi
local xAxisUI = Vector2.new(1, 0)

function m.getDirAngle(dir)
  local radv = dir:radTo(xAxisUI)
  return radv / twoPi * 360
end

-- dir is a Vector2
function m.getDirIndexUI(dir, dirNum)
  dirNum = dirNum or m.dirNum

  -- calculate angle
  local radv = dir:radTo(xAxisUI)
  if radv < 0 then
    radv = radv + twoPi
  end

  -- decide direction
  local radInc = twoPi / dirNum
  local roundup = radv + radInc * 0.5
  if roundup > twoPi then
    roundup = roundup - twoPi
  end

  return floor(roundup / radInc)
end

local xAxis = Vector2.new(0, 1)

function m.getDirIndex(dir, dirNum)
  dirNum = dirNum or m.dirNum

  -- calculate angle
  local radv = xAxis:radTo(dir)
  if radv < 0 then
   radv = radv + twoPi
  end

  -- decide direction
  local radInc = twoPi / dirNum
  local roundup = radv + radInc * 0.5
  if roundup > twoPi then
   roundup = roundup - twoPi
  end

  return floor(roundup / radInc)
end

function m.getForwardFromDirIndex(dirIndex)
  local dir = Vector3.static_forward:rotateAroundY(dirIndex)
  return Vector3(dir[1], 0, dir[3])
end

function m.drawGizmos(gizmos)
  if not game.enableGizmos then return end

  for _, v in ipairs(gizmos or {}) do
    if not v.color then v.color = v.c end
    Gizmos.color = v.color and Color(unpack(v.color)) or Color(0, 0, 0, 1)
    if v.t == 'line' then
      Gizmos.DrawLine(v.src or v.s, v.dst or v.d)
    elseif v.t == 'dot' then
      Gizmos.DrawSphere(v.point or v.p, v.radius or v.r or 0.04)
    end
  end
end

function m.addPointNormalGizmos(options)
  local point = options.point
  local normal = options.normal
  local gizmos = options.gizmos
  local line_color = options.line_color or {255, 255, 255}
  local ball_color = options.line_color or {255, 0, 0}

  table.insert(gizmos, {
    t = 'line',
    s = point,
    d = point + normal,
    color = line_color,
  })

  table.insert(gizmos, {
    t = 'dot',
    p = point,
    r = 0.25,
    color = ball_color,
  })
end

function m.camera()
  local cc = rawget(_G, 'cc')
  if cc and cc.camera then
    return cc.camera.camera
  else
    return SceneUtil.getMainCam()
  end
end

function m.worldToViewport(pos)
  return m.camera():WorldToViewportPoint(pos)
end

function m.screenToViewport(pos)
  pos = Vector3(pos[1], pos[2], 0)
  if m.camera() then
    return m.camera():ScreenToViewportPoint(pos)
  end

  if ui.camera then
    return ui.camera:ScreenToViewportPoint(pos)
  end
end

function m.screenToWorld(pos)
  pos = Vector3(pos[1], pos[2], 0)
  return m.camera():ScreenToWorldPoint(pos)
end

function m.worldToPostProjection(pos)
  local pos4 = Vector4(pos[1], pos[2], pos[3], 1)
  local vpMat = m.camera().projectionMatrix * m.camera().worldToCameraMatrix
  return vpMat * pos4
end

function m.worldToScreen(pos)
  return m.camera():WorldToScreenPoint(pos)
end

function m.screenToRay(pos)
  pos = Vector3(pos[1], pos[2], 0)
  return m.camera():ScreenPointToRay(pos)
end

local defaultConstraint = {min = 0.01, max = 0.99}

function m.worldToViewportConstraint(pos, constraint)
  constraint = constraint or defaultConstraint
  local pos = m.worldToViewport(pos)
  pos[1] = math.clamp(pos[1], constraint.min, constraint.max)
  pos[2] = math.clamp(pos[2], constraint.min, constraint.max)
  return pos
end

local colorDisabled = Color.new(1, 1, 1, 1)

function m.setImageEnabled(obj, enabled)
  if enabled then
    obj:setNormal()
  else
    obj:setGray()
  end
end

function m.uiScaleAnimation(node, scale, duration, callback)
  unity.setScale(node, scale)
  scheduler.performWithDelay(duration, function()
    unity.setScale(node, 1)
  end)

  if callback then
    scheduler.performWithDelay(duration + 0.1, function()
      callback()
    end)
  end
end

function m.uiCallback(node, duration, callback)
  if callback then
    scheduler.performWithDelay(duration + 0.1, function()
      callback()
    end)
  end
end


-- 给按钮设置反馈的声音
function m.resetButtonDefaultSound(view, buttonList)
  for k,v in pairs(buttonList) do
    if view[k] then
      if (v == -1) then
        v = nil 
      end
      view[k]:setBtnSound(v)
    else
      logd('%s not found on %s', k, view.classname)
    end
  end
end

function m.resetToggleDefaultSound(view, toggleList)
  for k,v in pairs(toggleList) do
    if view[k] then
      view[k]:setToggleSound(v)
    end
  end
end

function m.resetTextLabels(view, labelList)
  for k,v in pairs(labelList) do
    logd('resetTextLabels k:%s, v:%s', k, v)
    if view[k] then
      view[k]:setString(v)
    end
  end
end


function m.addCameraUIAnim(view, onPushComplete, onPopComplete)
  view.pushFun = function()
    view:setVisible(false)
    local uiAnim = ViewFactory.make('camera_anim')
    uiAnim:show('camera_anim_open', false, function()
      view:setVisible(true)
      if view.onAnimComplete then
        view:onAnimComplete()
      end
      if onPushComplete then
        onPushComplete()
      end
    end)
  end

  view.popFun = function(onComplete)
    local uiAnim = ViewFactory.make('camera_anim')
    uiAnim:show('camera_anim_close', false, function()
      if onPopComplete then
        onPopComplete()
      end
    end)
    view:destroy()
    onComplete()
  end
end


function m.addMainHollowAnim(view, onPushComplete, onPopComplete)
  view.pushFun = function()
    view:setVisible(false)
    local uiAnim = ViewFactory.make('hollow_anim')
    uiAnim:showAnim('show', function()
      view:setVisible(true)
      if view.onAnimComplete then
        view:onAnimComplete()
      end
      if onPushComplete then
        onPushComplete()
      end
    end)
  end

  view.popFun = function(onComplete)
    local uiAnim = ViewFactory.make('hollow_anim')
    uiAnim:showAnim('hide', function()
      if onPopComplete then
        onPopComplete()
      end
    end)
    view:destroy()
    onComplete()
  end
end

function m.addMainUIAnim(view, onPushComplete, onPopComplete)
  view.pushFun = function()
    view:setVisible(false)
    local uiAnim = ViewFactory.make('circle_anim')
    uiAnim:show('circle_open', false, function()
      view:setVisible(true)
      if view.onAnimComplete then
        view:onAnimComplete()
      end
      if onPushComplete then
        onPushComplete()
      end
    end)
  end

  view.popFun = function(onComplete)
    local uiAnim = ViewFactory.make('circle_anim')
    uiAnim:show('circle_close', true, function()
      if onPopComplete then
        onPopComplete()
      end
    end)
    view:destroy()
    onComplete()
  end
end

function m.addBlackSwitchAnim(view, onPushComplete, onPopComplete)
  view.pushFun = function()
    view:setVisible(false)
    local uiAnim = ViewFactory.make('ui1_transitions')
    uiAnim:showWithEvent('ui1_transitions_anim', false, function()
      view:setVisible(true)
      if view.onAnimComplete then
        view:onAnimComplete()
      end
      if onPushComplete then
        onPushComplete()
      end
    end)
  end

  view.popFun = function(onComplete)
    local uiAnim = ViewFactory.make('ui1_transitions')
    -- logd('popFun 111')
    uiAnim:showWithEvent('ui1_transitions_anim', true, function()
      -- logd('popFun 222')
      view:destroy()
      onComplete()
      if onPopComplete then
        onPopComplete()
      end
    end)

  end
end

function m.addSubScreenUIAnim(view, onPushComplete, onPopComplete)
  local transform = view.transform:find("anim_control")
  if transform == nil then
    if type(view.getAnimCtrlTrans) == 'function' then
      transform = view:getAnimCtrlTrans()
    else
      loge("Error SubScreen without anim_control")
      return
    end
  end

  view.pushFun = function()
    -- view:performWithDelay(0.1, function()
      view:setVisible(true)
      local big = GoTween(transform, 0.15, GoTweenConfig():scale(Vector3.static_one*1.1, false))
      local normal = GoTween(transform, 0.15, GoTweenConfig():scale(Vector3.static_one, false):onComplete(function()
        if view.onAnimComplete then
          view:onAnimComplete()
        end
        if onPushComplete then
          onPushComplete()
        end
      end))
      local chain = unity.createTweenChain()
      chain:append(big)
      chain:append(normal)
      chain:play()
    -- end)
  end
  view.popFun = function (onComplete)
    -- logd("pop fun as false")
    -- m.fixAutoPositionObject(view, false)
    local big = GoTween(transform, 0.1, GoTweenConfig():scale(Vector3.static_one*1.1, false))
    local small = GoTween(transform, 0.1, GoTweenConfig():scale(Vector3.static_one*0.9, false):onComplete(function()
      -- logd("pop fun as true")
      -- m.fixAutoPositionObject(view, true)
      unity.setScale(transform, 1)
      view:destroy()
      if onPopComplete then
        onPopComplete()
      end
      onComplete()
    end))
    local chain = unity.createTweenChain()
    chain:append(big):append(small):play()
  end
end



function m.addSubScreenRotateUIAnim(view,onPushComplete,onPopComplete)
  local transform = view.transform:find("anim_control")
  if transform == nil then
    logd("Error SubScreen without anim_control")
    return
  end
  --logd(">>>>>>>>>>addSubScreenRotateUIAnim")
  view.pushFun = function ()
     view:setVisible(true)
     transform:set_localEulerAngles(Vector3(0,270,0))
     local normal = GoTween(transform,0.3, GoTweenConfig() --0.15
      :localEulerAngles(Vector3(0,360,0), false)
      :onComplete(function()
        if onPushComplete then 
          onPushComplete()
        end 
      end))
      local chain = unity.createTweenChain()
      chain:append(normal):play()
  end

  view.popFun = function (onComplete)
    local refresh = GoTween(transform, 0.05, GoTweenConfig()
      :localEulerAngles(Vector3(0,270,0), false)
      :onComplete(function()
      if onPopComplete then
        onPopComplete()
      end
    end))
    local chain = unity.createTweenChain()
    chain:append(refresh):play()
  end
end

function m.addSubFullScreenUIAnim(view, onPushComplete, onPopComplete)
  local transform = view.transform:find("anim_control")
  if transform == nil then
    logd("Error SubScreen without anim_control")
    return
  end
  view.pushFun = function()
    -- view:setVisible(false)
    -- view:performWithDelay(0.1, function()
      -- view:setVisible(true)
      unity.setScale(transform, Vector3(1,0.1,1))-- = 0
      -- m.fixAutoPositionObject(view, false)
      local normal = GoTween(transform, 0.15, GoTweenConfig()
        :scale(Vector3.static_one, false)
        :onComplete(function()
        -- m.fixAutoPositionObject(view, true)
        if onPushComplete then
          onPushComplete()
        end
      end))
      local chain = unity.createTweenChain()
      chain:append(normal):play()
    -- end)
  end
  view.popFun = function (onComplete)
    -- m.fixAutoPositionObject(view, false)
    local small = GoTween(transform, 0.05, GoTweenConfig():scale(Vector3(1,0.1,1), false):onComplete(function()
      -- m.fixAutoPositionObject(view, true)
      unity.setScale(transform, 1)-- = 0
      view:destroy()
      if onPopComplete then
        onPopComplete()
      end
      onComplete()
    end))
    local chain = unity.createTweenChain()
    chain:append(small):play()
  end
end

function m.fixAutoPositionObject(view, shown)
  -- logd("show auto position object:"..tostring(shown))
  if view.btnClose then
    view.btnClose:setVisible(shown)
  end
  if view.btnBack then
    view.btnBack:setVisible(shown)
  end
end

function m.removeRaycastTargets(gameObject, txts)
  local images = gameObject:GetComponentsInChildren(UI.Image)
  for k = 1, #images do local image = images[k]
    image:set_raycastTarget(false)
  end
  for k, txt in pairs(txts) do
    txt:setRaycastEnabled(false)
  end
end

function m.__setCtrlVisible(ctrl, val)
  if ctrl then
    ctrl:setVisible(val)
  end
end

function m.updateMapButtons(view)
  local dsid = QuestUtil.calcMainQuestDestWorldSceneId()
  for k, v in pairs(cfg.city_area) do
    if view[k.."_name"] then
      view[k.."_name"]:setString(v.name)
    end
    local cityType = cfg.city[v.tid]
    local unLock = UnlockUtil.isUnlockedFromType(cityType)
    local isDest = (dsid == v.tid)
    m.__setCtrlVisible(view[v.tid..'_icnLock'], not unLock)
    m.__setCtrlVisible(view[v.tid..'_icnTask'], isDest)

    if view[v.tid] then
      local bg = view[v.tid].transform:find('bg')

      if bg then
        local bgImg = bg.gameObject:getComponent(UI.Image)
        if bgImg then
          if unLock then
            -- view[v.tid..'_name']:setColor(ColorUtil.white)
            bgImg:setNormal()
          else
            -- view[v.tid..'_name']:setColor(ColorUtil.shallow_gray)
            bgImg:setGray()
          end
        end
      end
    end
  end
end

function m.startProgressAnim(opt)
  -- logd('startProgressAnim %s, %s', peek(opt), debug.traceback())

  local progress = opt.progress
  local progressBg = opt.progressBg
  local oldPercent = opt.oldPercent
  local newPercent = opt.newPercent
  local hasLevelup = opt.hasLevelup
  local direction = opt.direction
  local animTime = opt.animTime or 0.5
  local onLevelup = opt.onLevelup

  if hasLevelup then
    progressBg:setProgress(1, direction)
    local options = {
      animTime = animTime * 0.5,
      toPercent = 1,
      fromPercent = oldPercent,
      direction = direction,
      onComplete = function()
        progressBg:setProgress(newPercent, direction)
        progress:setProgress(0, direction)
        local options2 = {
          animTime = animTime * 0.5,
          fromPercent = 0,
          toPercent = newPercent,
          direction = direction,
        }
        progress:runProgressAnim(options2)
        if onLevelup then
          onLevelup()
        end
      end
    }
    progress:runProgressAnim(options)

  else
    progressBg:setProgress(newPercent, direction)
    local options = {
      animTime = animTime,
      fromPercent = oldPercent,
      toPercent = newPercent,
      direction = direction,
    }
    progress:runProgressAnim(options)
  end

end

function m.getMapName(maptype)
  local str = nil
  if maptype == 1 then 
    str = "competitive" 
  elseif maptype == 2 then
    str = "practice"
  elseif maptype == -1 then
    str = "football"
  end  
  local profile = cfg.mapes[str]
  if profile then
    return profile["map_name"]
  else
    return "unknown"
  end
end


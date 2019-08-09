declare_module('ScrollListUtil')

local LayoutElement = UI.LayoutElement
local VerticalLayoutGroup = UI.VerticalLayoutGroup
local HorizontalLayoutGroup = UI.HorizontalLayoutGroup
local GridLayoutGroup = UI.GridLayoutGroup
local ContentSizeFitter = UI.ContentSizeFitter
local Yield = UnityEngine.Yield
local updateHandle = {}

function MakeList(env)
  local view          = env.view
  local list          = env.list
  local nList         = table.getn(list)
  local size          = env.size or 1
  local sv            = env.sv
  local dir           = env.dir
  local slots         = env.slots
  local getSlot       = env.getSlot
  local onComplete    = env.onComplete
  local shouldReset   = env.shouldReset -- should reset content to top
  local slotHeight    = env.slotHeight or 1
  local defaultSelect = env.defaultSelect
  local yield         = env.yield == nil and true or env.yield
  local goList        = env.goList or sv.transform:find("List")


  local instanceId = sv.gameObject:GetInstanceID()
  if updateHandle[instanceId] then
    scheduler.unschedule(updateHandle[instanceId])
    updateHandle[instanceId] = nil
  end

  local rt = goList:getComponent(RectTransform)
  local sv_rect = sv.scrollRect
  local pageCount = rt.rect.height/size
  local bElastic = nil

  if pageCount == 0 then
    local scrollRect = sv.rectTransform
    pageCount = math.ceil(scrollRect.rect.height/slotHeight)
  end
  if sv_rect then
    bElastic = (sv_rect:get_movementType() ==  UI.ScrollRect.MovementType.Elastic)
    if bElastic then
      sv_rect:set_movementType( UI.ScrollRect.MovementType.Clamped )
    end

    local sr_bar = sv_rect:get_verticalScrollbar()
    if dir == 'h' then sr_bar = sv_rect:get_horizontalScrollbar() end
  end

  if nList < #slots then
    for i = (nList + 1), #slots do
      if slots[i] then
        slots[i]:setVisible(false)
      end
    end
  end

  if nList > 30 then
    -- 打工比较特殊，虽然它有很多slot,但是每一个slot的高度是变化的，用这个比较合适,用那个会出错
    -- loge('MakeList: you should use optimized list! size=%d trace=%s', nList, debug.traceback())
  end

  local s = os.clock()
  assert(goList)

  updateHandle[instanceId] = view:coroutineStart(function()
    for i = 1, nList do local v = list[i]
      local slot, update = getSlot(view, i, v)
      slot:setParent(goList, false) -- goList)
      slot:setVisible(true)
      if defaultSelect and i == defaultSelect then
        slot:setSelect(true)
      end
      if i > pageCount and yield then
        coroutine.yield()
      end
    end
  end, nil, function()
    local e = os.clock()
    if sv_rect then
      if bElastic then
        sv_rect:set_movementType( UI.ScrollRect.MovementType.Elastic )
      end

      if shouldReset then
        if dir == "v" then
          sv_rect:set_verticalNormalizedPosition( 1 )
        else
          sv_rect:set_horizontalNormalizedPosition( 0 )
        end
      end
    end

    if onComplete then
      onComplete(view)
    end
  end)

  -- rt.rect.y = 0
  local scrollHash = {svRect = sv_rect, pageCount = pageCount}
  return scrollHash
end

--[[
function UpdateList(env)
end
]]

function MakeGridVOptimized(env)
  local view        = env.view
  local list        = env.list
  local nList       = table.getn(list)
  local sv          = env.sv
  local dir         = env.dir
  local sizeW       = env.sizeW
  local sizeH       = env.sizeH
  local paddingLeft = env.paddingLeft
  local paddingTop  = env.paddingTop
  local col         = env.col
  local spacing     = env.spacing
  local alignment   = env.alignment
  local slots       = env.slots
  local getSlot     = env.getSlot
  local onComplete  = env.onComplete
  local shouldReset = env.shouldReset
  local goList      = env.goList or sv.transform:find("List")
  local __topRow__    = nil
  local __bottomRow__ = nil

  local rt = goList:getComponent(RectTransform)
  local svRect = sv.scrollRect
  if svRect:get_inertia() then
    svRect:set_inertia(false)
    svRect:set_inertia(true)
  end
  
  local normalSVWidth = sizeW*col + spacing*(col-1)
  local slotScale = sv.transform:get_rect():get_width()/normalSVWidth
  

  local rc = sv.gameObject:getComponent(RectTransform).rect
  local viewHeight = rc.height
  local viewWidth  = rc.width

  local rowCount = math.ceil(nList/col)
  local bElastic = (svRect:get_movementType() ==  UI.ScrollRect.MovementType.Elastic)
  if bElastic then
    svRect:set_movementType( UI.ScrollRect.MovementType.Clamped )
  end

  local vlg = goList:getComponent(VerticalLayoutGroup)
  if vlg then vlg.enabled = false end

  local csf = goList:getComponent(ContentSizeFitter)
  if csf then csf.enabled = false end

  local glg = goList:getComponent(GridLayoutGroup)
  if glg then glg.enabled = false end

  local function getCreateContainter(row, topRow, curHeight)
    local goContainer = nil
    local index = row - topRow
    local childCount = goList.childCount
    local rcTran = nil

    if index < childCount then
      goContainer = goList:GetChild(index):get_gameObject()
      rcTran = goContainer:getComponent(RectTransform)
      goContainer:setVisible(true)
    else
      goContainer = GameObject()
      rcTran = goContainer:addComponent(RectTransform)
      local layout = goContainer:addComponent(UI.HorizontalLayoutGroup)
      layout:set_spacing(spacing ) 
      if alignment then layout:set_childAlignment(alignment) end

      if paddingLeft then
        layout.padding.left = paddingLeft 
      end
      if paddingTop then 
        layout.padding.top = index ~= 0 and paddingTop  or 0  
      end  
      --layout:set_childControlsSizeHeight(false)
      --layout:set_childControlsSizeWidth(false)
      layout:set_childForceExpandHeight(false)
      layout:set_childForceExpandWidth(false)

      goContainer:setParent(goList, false)
    end
    rcTran:set_sizeDelta(Vector2(viewWidth, sizeH))   --*slotScale
    rcTran:set_anchorMin(Vector2(0.5, 0))
    rcTran:set_anchorMax(Vector2(0.5, 0))
    rcTran:set_pivot(Vector2(0.5, 1))
    goContainer.transform:set_anchoredPosition( Vector2(0, curHeight)) 
    return goContainer
  end

  local function refreshGrid(first)
    view._makeScrollListTimes = view._makeScrollListTimes or {}
    local id = goList.gameObject:GetInstanceID()
    view._makeScrollListTimes[id] = view._makeScrollListTimes[id] or 0
    local times = view._makeScrollListTimes[id]
    if first then
      if shouldReset or times <= 0 then
        svRect:set_verticalNormalizedPosition( 1 )
      end
    end

    local rcSv = sv.rectTransform
    local totalHeight = rowCount * sizeH  --*slotScale
    goList:set_sizeDelta(Vector2(rcSv:get_rect():get_width(), totalHeight)) 

    local offset = goList:getComponent(RectTransform):get_anchoredPosition()[2]
    local topRow = math.max(math.ceil(offset/sizeH) - 1, 1)
    local bottomRow = math.min(math.ceil((offset + viewHeight)/sizeH) + 1, nList)
    if __topRow__ == topRow and
       __bottomRow__ == bottomRow then
      return
    end

    for r = 1, topRow - 1 do
      for c = 1, col do
        local i = (r-1) * col + c
        if slots[i] then
          slots[i]:destroy()
          slots[i] = nil
        end
      end
    end

    if sv.nList then
      local iStart = nList + 1
      if iStart > (bottomRow * col + 1) then
        iStart = bottomRow * col + 1
      end

      for i=iStart, sv.nList do
        if slots[i] then
          slots[i]:destroy()
          slots[i] = nil
        end
      end
    end
    sv.nList = nList

    local curHeight = totalHeight
    curHeight = curHeight - (topRow-1) * sizeH --*slotScale
    for r = topRow, bottomRow do
      for c = 1, col do
        local i = (r - 1) * col + c
        local v = list[i]
        if v then
          local goContainer = getCreateContainter(r, topRow, curHeight)
          local slot = slots[i]
          if not slot then
            

            slot = getSlot(view, i, v)
            slots[i] = slot

            slot:setParent(goContainer, false)
            local le = slot.gameObject:getComponent(LayoutElement)
            if le then 
              le.enabled = true
              le.minHeight = sizeH  --*slotScale
              le.minWidth = sizeW   --*slotScale
            end  
          else
            slot:setParent(goContainer, false)
            slot:update(i, v)
          end
          slot:setVisible(true)
        end
      end
      curHeight = curHeight - sizeH  --*slotScale 
    end

    if first then
      if shouldReset or times <= 0 then
        svRect:set_verticalNormalizedPosition( 1 )
        view:performWithDelay(0, function()
          goList:getComponent(RectTransform):set_anchoredPosition( Vector2(0, 0) )
        end)
      end
    end

    __topRow__ = topRow
    __bottomRow__ = bottomRow
  end

  refreshGrid(true)
  if onComplete then
    scheduler.performWithDelay(0, function()
      onComplete(view)
    end)
  end

  view._makeScrollListTimes = view._makeScrollListTimes or {}
  local id = goList.gameObject:GetInstanceID()
  view._makeScrollListTimes[id] = view._makeScrollListTimes[id] or 0
  view._makeScrollListTimes[id] = view._makeScrollListTimes[id] + 1

  if svRect:get_movementType() ==  UI.ScrollRect.MovementType.Elastic then
    svRect:set_movementType( UI.ScrollRect.MovementType.Clamped )
    view:performWithDelay(0.1, function()
      svRect:set_movementType( UI.ScrollRect.MovementType.Elastic )
    end)
  end

  local onValueChanged = svRect:get_onValueChanged()
  view:removeAllListeners(onValueChanged)
  view:addListener(onValueChanged, function()
    refreshGrid()
  end)
  --通过set_anchoredPosition设置grid的位置的时候，onValueChanged并不是每次被触发，导致grid未刷新，
  --使用signal手动刷新
  if view.refreshGridHandler then
    md:signal('refresh_grid'):remove(view.refreshGridHandler)
    view.refreshGridHandler = nil
  end
  view.refreshGridHandler = function()
    refreshGrid()
  end
  md:signal('refresh_grid'):add(view.refreshGridHandler)
end

function MakeVertListOptimized(env)
  local view        = env.view
  local list        = env.list
  local nList       = table.getn(list)
  local sv          = env.sv
  local dir         = env.dir
  local slots       = env.slots
  local getSlot     = env.getSlot
  local defaultSelect = env.defaultSelect
  local onComplete  = env.onComplete
  local shouldReset = env.shouldReset -- should reset content to top
  view.sv = sv


  local goList = sv.transform:find("List")
  local rt = goList:getComponent(RectTransform)
  local sv_rect = sv.scrollRect
  if sv_rect:get_inertia() then
    sv_rect:set_inertia(false)
    sv_rect:set_inertia(true)
  end
  local sr_bar = sv_rect:get_verticalScrollbar()

  local vlg = goList:getComponent(VerticalLayoutGroup)
  if vlg then vlg.enabled = false end

  -- sv.gameObject:addComponent(UnityEngine.Canvas)
  -- local comp = sv.gameObject:addComponent(UnityEngine.UI.GraphicRaycaster)
  -- comp.blockingObjects = false

  local csf = goList:getComponent(ContentSizeFitter)
  if csf then csf.enabled = false end

  -- if nList < #slots then
  --   for i = (nList + 1), #slots do
  --     if slots[i] then
  --       slots[i]:setVisible(false)
  --     end
  --   end
  -- end


  local id = goList.gameObject:GetInstanceID()
  view._scrollSelectedIndices = view._scrollSelectedIndices or {}
  if defaultSelect then view._scrollSelectedIndices[id] = defaultSelect end
  view:signal('_scroll_selected_changed'):clear()
  view:signal('_scroll_selected_changed'):add(function(idx)
    view._scrollSelectedIndices[id] = idx
  end)

  assert(goList)
  env.__topRow__    = nil
  env.__bottomRow__ = nil

  MakeVertListWrapped(env, true)
  if onComplete then
    scheduler.performWithDelay(0, function()
      onComplete(view)
    end)
  end
  view._makeScrollListTimes = view._makeScrollListTimes or {}
  view._makeScrollListTimes[id] = view._makeScrollListTimes[id] or 0
  view._makeScrollListTimes[id] = view._makeScrollListTimes[id] + 1


  if sv_rect:get_movementType() ==  UI.ScrollRect.MovementType.Elastic then
    sv_rect:set_movementType( UI.ScrollRect.MovementType.Clamped )
    view:performWithDelay(0.1, function()
      sv_rect:set_movementType( UI.ScrollRect.MovementType.Elastic )
    end)
  end

  sv_rect.enabled = false

  local onValueChanged = sv_rect:get_onValueChanged()
  view:removeAllListeners(onValueChanged)
  view:addListener(onValueChanged, function()
    ScrollListUtil.MakeVertListWrapped(env)
  end)


  sv_rect.enabled = true

  local scrollHash = {svRect = sv_rect}
  return scrollHash
end

function MakeHorizontalListOptimized(env)
  local view        = env.view
  local list        = env.list
  local nList       = table.getn(list)
  local sv          = env.sv
  local dir         = env.dir
  local slots       = env.slots
  local getSlot     = env.getSlot
  local defaultSelect = env.defaultSelect
  local onComplete  = env.onComplete
  local shouldReset = env.shouldReset -- should reset content to top

  local goList = sv.transform:find("List")
  local rt = goList:getComponent(RectTransform)
  local sv_rect = sv.scrollRect
  local sr_bar = sv_rect:get_verticalScrollbar()


  local vlg = goList:getComponent(HorizontalLayoutGroup)
  if vlg then vlg.enabled = false end

  local csf = goList:getComponent(ContentSizeFitter)
  if csf then csf.enabled = false end

  if nList < #slots then
    for i = (nList + 1), #slots do
      if slots[i] then
        slots[i]:setVisible(false)
      end
    end
  end


  local id = goList.gameObject:GetInstanceID()

  view._scrollSelectedIndices = view._scrollSelectedIndices or {}
  if defaultSelect then view._scrollSelectedIndices[id] = defaultSelect end
  view:signal('_scroll_selected_changed'):clear()
  view:signal('_scroll_selected_changed'):add(function(idx)
    view._scrollSelectedIndices[id] = idx
  end)

  assert(goList)
  MakeHorizontalListWrapped(env, true)
  if onComplete then
    onComplete(view)
  end
  view._makeScrollListTimes = view._makeScrollListTimes or {}
  view._makeScrollListTimes[id] = view._makeScrollListTimes[id] or 0
  view._makeScrollListTimes[id] = view._makeScrollListTimes[id] + 1



  if sv_rect:get_movementType() ==  UI.ScrollRect.MovementType.Elastic then
    sv_rect:set_movementType( UI.ScrollRect.MovementType.Clamped )
    view:performWithDelay(0.1, function()
      sv_rect:set_movementType( UI.ScrollRect.MovementType.Elastic )
    end)
  end

  sv_rect.enabled = false

  local onValueChanged = sv_rect:get_onValueChanged()
  view:removeAllListeners(onValueChanged)
  view:addListener(onValueChanged, function()
    ScrollListUtil.MakeHorizontalListWrapped(env)
  end)

  sv_rect.enabled = true

  local scrollHash = {svRect = sv_rect}
  return scrollHash
end



function MakeVertScrollListOptimized(env)
  local view        = env.view
  local dv          = env.dragView
  local list        = env.list
  local nList       = table.getn(list)
  local sv          = env.sv
  local dir         = env.dir
  local slots       = env.slots
  local getSlot     = env.getSlot
  local defaultSelect = env.defaultSelect
  local onComplete  = env.onComplete
  local shouldReset = env.shouldReset -- should reset content to top
  local updateSlot  = env.updateSlot
  local showSlot    = env.showSlot
  view.sv = sv

  local slotHeight  = env.slotHeight
  local slotWidth   = env.slotWidth
  local goList = sv.transform:find("List")
  local rt = goList:getComponent(RectTransform)
  local sv_rect = sv.scrollRect
  if sv_rect:get_inertia() then
    sv_rect:set_inertia(false)
    sv_rect:set_inertia(true)
  end
  local sr_bar = sv_rect:get_verticalScrollbar()

  local vlg = goList:getComponent(VerticalLayoutGroup)
  if vlg then vlg.enabled = false end
  local csf = goList:getComponent(ContentSizeFitter)
  if csf then csf.enabled = false end

  -- if nList < #slots then
  --   for i = (nList + 1), #slots do
  --     if slots[i] then
  --       slots[i]:setVisible(false)
  --     end
  --   end
  -- end

  local id = goList.gameObject:GetInstanceID()
  view._scrollSelectedIndices = view._scrollSelectedIndices or {}
  if defaultSelect then view._scrollSelectedIndices[id] = defaultSelect end
  view:signal('_scroll_selected_changed'):clear()
  view:signal('_scroll_selected_changed'):add(function(idx)
    view._scrollSelectedIndices[id] = idx
  end)

  assert(goList)
  env.__topRow__    = nil
  env.__bottomRow__ = nil
  env.__offset__ = 0
  env.__reset__ = nil
  env.__center__ = nil
  env.indexList={}
  env.length =0

  MakeVertSrollListWrapped(env, true)
  if onComplete then
    scheduler.performWithDelay(0, function()
      onComplete(view)
    end)
  end

  view._makeScrollListTimes = view._makeScrollListTimes or {}
  view._makeScrollListTimes[id] = view._makeScrollListTimes[id] or 0
  view._makeScrollListTimes[id] = view._makeScrollListTimes[id] + 1


  if sv_rect:get_movementType() ==  UI.ScrollRect.MovementType.Elastic then
    sv_rect:set_movementType( UI.ScrollRect.MovementType.Clamped )
    view:performWithDelay(0.1, function()
      sv_rect:set_movementType( UI.ScrollRect.MovementType.Unrestricted )
    end)
  end

  sv_rect.enabled = false

  if nList > env.length then
    for i = 1,nList do
      env.indexList[i]=i
    end
  else
     local num= math.floor(env.length/nList)+1
     for i = 1,nList * num do
      local v= i % nList
      if v == 0 then v = nList end
      env.indexList[i]=v
    end
  end
  -- local onValueChanged = sv_rect:get_onValueChanged()
  -- view:removeAllListeners(onValueChanged)
  -- view:addListener(onValueChanged, function()
  --   ScrollListUtil.MakeVertSrollListWrapped(env)
  -- end)
  env.dragging      = nil 
  env.delay         = 0.1
  env.startTouchPos = nil 
  env.startClickPos = nil
  env.moveTouchTm   = nil 
  env.startTouchTm  = nil
  env.onEndTm       = nil
  env.mid = math.floor(env.length/2)+1
  env._index = env.mid
  env.scroll = false
  env.errorNum = 0
  if ui.camera and game.platform ~= 'editor' then
    env.centerTopMargin = unity.Screen.height/2 + slotHeight* unity.resolution/2
    env.centerBottomMargin = unity.Screen.height/2 - slotHeight* unity.resolution/2
  else
    env.centerTopMargin =  unity.Screen.height/2  + slotHeight/2
    env.centerBottomMargin =  unity.Screen.height/2 - slotHeight/2
  end


  local onMove = function(pos, delta)
    if env.dragging then
      moveTouchTm = Time.time
      local offset = pos[2]-env.startTouchPos[2]
      moveScroll(env,offset)
      env.startTouchPos = Vector2.new(pos)
    end
  end

  local onBegin = function(pos)
    env.dragging = true
    env.startTouchTm = Time.time
    env.startTouchPos = Vector2.new(pos)
    env.startClickPos  = Vector2.new(pos)
    if env.__reset__ then
      scheduler.unschedule(env.__reset__)
      env.__reset__ = nil
    end
    if env.__center__ then
       scheduler.unschedule(env.__center__)
       env.__center__ = nil
    end
    local _value=env.indexList[env.mid]
    local value=env.list[_value]
    if env._index ~=0 then
      showSlot(view,env._index ,value)
    end
    env.scroll =false
  end

  local onEnd = function(pos)
    if not env.dragging then return end
    env.startTouchTm = nil
    env.dragging = false
    env.moveTouchTm = nil
    local s= pos[2]-env.startTouchPos[2]
    if math.abs(s) > 5 then
      env.speed= (pos[2]-env.startTouchPos[2])*0.52
      env.f=0.72
      env.stopSpeed = 5 
      if ui.camera and game.platform ~= 'editor' then
        env.f=env.f / unity.resolution
        env.stopSpeed= env.stopSpeed / unity.resolution
      end
      env.maxSpeed = env.f * 21
      if env.speed >  env.maxSpeed then
        env.f = env.f * (env.speed / env.maxSpeed )
      elseif env.speed < - env.maxSpeed then
        env.f =  -env.f * (env.speed / env.maxSpeed )
      end
      env.moveTouchTm = nil
      env.scroll =true
      local function move(dt)
        if env.speed > 0 then
          env.speed =env.speed -env.f
        elseif env.speed < 0 then
          env.speed =env.speed + env.f
        end  
        moveScroll(env,env.speed)
      
        if math.abs(env.speed)< env.stopSpeed then
          env.speed = 0
          scheduler.unschedule(env.__reset__)
          env.__reset__ = nil
          MakeVertSrollListResetPosition(env)
        end
      end
      env.__reset__=scheduler.scheduleWithUpdate(move) 
    else
      MakeVertSrollListResetPosition(env)
    end  
    env.startTouchPos = nil
  end

  local onClick = function (pos,delay)
    -- if ui.camera and game.platform ~= 'editor' then
    --   pos[1] = pos[1] / unity.resolution
    --   pos[2] = pos[2] / unity.resolution
    --   env.startClickPos[1] =env.startClickPos[1] / unity.resolution
    --   env.startClickPos[2] =env.startClickPos[2] / unity.resolution
    -- end
    local x = env.startClickPos[1]  - pos[1]
    local y = env.startClickPos[2]  - pos[2]
    if math.abs(x)+math.abs(y) < 4 then
      for i = 1, env.length do
        local ap=env.slots[i].transform:get_anchoredPosition()
        if ap[2]+env.centerTopMargin > pos[2] and  ap[2]+ env.centerBottomMargin <= pos[2] then
            if math.abs(ap[2]) < 1 then          
              MakeVertSrollListResetPosition(env)
            else
              MakeVertSrollListResetPosition(env,-ap[2])
            end  
            break
        end
      end
    end
  end
  env._init =function(tid)
    for i = 1, nList do
      if list[i] == tid then
        local ap=env.slots[i].transform:get_anchoredPosition()
        if math.abs(ap[2]) < 1 then          
          MakeVertSrollListResetPosition(env)
        else
          MakeVertSrollListResetPosition(env,-ap[2])
        end
        break
      end
    end
  end
  local onTouch = TouchUtil.click(onClick, onBegin, onEnd, onMove)
  --cache 后， reopen时，需要移除旧的
  local list= dv
  if list.touchRegistered then
    list:unregisterTouch()
  end

  list:registerTouch(onTouch)
  sv_rect.enabled = true
  return env
end



function MakeVertSrollListResetPosition(env,distance)
  local view        = env.view
  local list        = env.list
  local nList       = table.getn(list)
  local sv          = env.sv
  local dir         = env.dir
  local slots       = env.slots
  local getSlot     = env.getSlot

  local slotHeight  = env.slotHeight
  local slotFixedHeight = env.slotFixedHeight
  local viewPortSize = sv.gameObject:getComponent(RectTransform).rect.height

  if env.__center__ then
     scheduler.unschedule(env.__center__)
     env.__center__ = nil
  end
  if distance then
    env.__moveDistance__= distance
  else  
    local ap=env.slots[1].transform:get_anchoredPosition()
    local height=math.abs(ap[2]%slotHeight)
    if height > env.slotHeight/2 then
      local h=env.slotHeight-height
      env.__moveDistance__= h
    else 
      env.__moveDistance__= -height
    end
  end 
  env.__moveS__=0
  local function center(dt)
    local s= env.__moveDistance__ / 6
    env.__moveS__=env.__moveS__+s
   
    moveScroll(env,s)
    if math.abs(env.__moveDistance__-env.__moveS__) < 0.1  then
      scheduler.unschedule(env.__center__)
      env.__center__ = nil
      env._index =0
      for i = 1, env.length do
        if env.slots[i] and env.slots[i].transform then
          local ap=env.slots[i].transform:get_anchoredPosition()
          if  math.abs(ap[2])< 1 then
            env._index  = i
            break
          end
        else
          break  
        end
      end
      if env._index ~= 0 then
        local _value=env.indexList[env.mid]
        local value=env.list[_value]
        env.selectedSlot(view,env._index ,value)
        env.errorNum = 0
      else 
        if env.errorNum  < 2 then 
          MakeVertSrollListResetPosition(env)
          env.errorNum =env.errorNum +1
        end
      end
    end
  end
  env.__center__=scheduler.scheduleWithUpdate(center) 
end 

function moveScroll(env,s)
  local view        = env.view
  local list        = env.list
  local nList       = table.getn(list)
  local sv          = env.sv
  local dir         = env.dir
  local slots       = env.slots
  local slotHeight  = env.slotHeight
  local viewPortSize = sv.gameObject:getComponent(RectTransform).rect.height
  local resetList={}
  local jishu=env.length/2
  for i = 1, env.length do
    if env.slots[i] and env.slots[i].transform then
      local ap=env.slots[i].transform:get_anchoredPosition()
      local offsetY=ap[2]+ s
      env.slots[i].transform:set_anchoredPosition(Vector2(ap[1],offsetY))
      if offsetY > env.slotHeight * jishu  then
        local reset ={}
        reset["index"]=i
        reset["offset"]=offsetY
        table.insert(resetList,reset)
      end
      if offsetY < jishu * -env.slotHeight then
        local reset ={}
        reset["index"]=i
        reset["offset"]=offsetY
        table.insert(resetList,reset)
      end
    end  
  end
  if resetList then
    table.sort(resetList,function(a,b) return math.abs(a.offset) > math.abs(b.offset) end)
    for s in pairs(resetList) do
      local ap=env.slots[resetList[s].index].transform:get_anchoredPosition()
      if resetList[s].offset > env.slotHeight * jishu  then
        local index=env.indexList[env.length+1]
        local v=env.list[index]
        local value=env.indexList[1]
        local y= resetList[s].offset-(env.length *  env.slotHeight)
        env.slots[resetList[s].index].transform:set_anchoredPosition( Vector2(ap[1],y))
        env.updateSlot(view,resetList[s].index, v)
        table.remove(env.indexList,1)
        table.insert(env.indexList,value)
      end
      if resetList[s].offset < jishu * -env.slotHeight then
        local len=table.getn(env.indexList)
        local index=env.indexList[len]
        local v=env.list[index]
        local value=env.indexList[len]
        local y= resetList[s].offset+(env.length *  env.slotHeight)
        env.slots[resetList[s].index].transform:set_anchoredPosition( Vector2(ap[1],y))
        env.updateSlot(view,resetList[s].index,v)
        table.remove(env.indexList,len)
        table.insert(env.indexList,1,value)
      end
    end
   end 
end


function MakeVertSrollListWrapped(env, firstMake)
  local view        = env.view
  local list        = env.list
  local nList       = table.getn(list)
  local sv          = env.sv
  local dir         = env.dir
  local slots       = env.slots
  local getSlot     = env.getSlot
  local defaultSelect = env.defaultSelect
  local updateSlot  = env.updateSlot
  local onComplete  = env.onComplete
  local shouldReset = env.shouldReset -- should reset content to top

  local slotHeight  = env.slotHeight
  local slotWidth   = env.slotWidth

  local goList = sv.transform:find("List")
  local sv_rect = sv.scrollRect
  local sr_bar = sv_rect:get_verticalScrollbar()
  local slotSize = slotHeight
  local viewPortSize = sv.gameObject:getComponent(RectTransform).rect.height

  --如果reset或者第一次初始化，设置scroll rect到初始位置
  view._makeScrollListTimes = view._makeScrollListTimes or {}
  local id = goList.gameObject:GetInstanceID()
  view._makeScrollListTimes[id] = view._makeScrollListTimes[id] or 0
  local times = view._makeScrollListTimes[id]

  local selected_idx = view._scrollSelectedIndices[id]

  if firstMake then
    if shouldReset or times <= 0 then
      sv_rect:set_verticalNormalizedPosition( 1 )
    end
  end

  local totalHeight = nList * slotSize
  if viewPortSize > totalHeight then
    totalHeight= viewPortSize
  end
  goList:set_sizeDelta(Vector2(slotWidth, totalHeight))
  local ap = goList:getComponent(RectTransform):get_anchoredPosition()
  if firstMake and selected_idx then
    ap[2] = slotSize * (selected_idx - 1)
    if ap[2] > totalHeight - viewPortSize then ap[2] = totalHeight - viewPortSize end
    goList:getComponent(RectTransform):set_anchoredPosition( Vector2(ap[1], ap[2]) )
  end

  -- if firstMake then goList:getComponent(RectTransform):set_anchoredPosition(Vector2(0, 0)) end
  local offset = ap[2]
  local topIndex = math.max(math.ceil(offset/slotSize) - 1, 1)
  local bottomIndex = math.ceil((offset + viewPortSize)/slotSize) + 1
  if env.__topRow__  == topIndex and
     env.__bottomRow__ == bottomIndex then
    return
  end

  for i = 1, topIndex - 1 do
    if slots[i] then
      slots[i]:destroy()
      slots[i] = nil
    end
  end

  if sv.nList then
    local iStart = nList + 1
    if iStart > (bottomIndex + 1) then
      iStart = bottomIndex + 1
    end

    for i=iStart, sv.nList do
      if slots[i] then
        slots[i]:destroy()
        slots[i] = nil
      end
    end
  end
  sv.nList = nList

  if bottomIndex%2== 0 then
    bottomIndex=bottomIndex+1
  end
  local curHeight = slotSize/2   --原来的   totalHeight - slotSize/2
  env.length=bottomIndex
  env._index=0
  curHeight = math.ceil(bottomIndex/2)* slotSize
  for i = topIndex, bottomIndex do
    env._index=i % nList
    if env._index ==0 then env._index=nList end
    v = list[env._index]
    if not slots[i] then
      local slot = getSlot(view, i, v)
      local le = slot.gameObject:getComponent(LayoutElement)
      if le then le:set_ignoreLayout( true) end
      slot:setParent(goList, false)
      slot.transform:set_anchoredPosition( Vector2(slotWidth/2, curHeight) )
      -----------------
      slot.transform:set_sizeDelta(Vector2(slotWidth,slotHeight))
      --------------------
      slots[i] = slot
    else
      slots[i].transform:set_anchoredPosition( Vector2(slotWidth/2, curHeight) )
      if updateSlot then updateSlot(view, i, v) end
    end

    if type(slots[i].setSelect) == 'function' then
      -- loge(">>>>> i:%s", tostring(i))
      -- loge(">>>>> selected_idx:%s", tostring(selected_idx))
      if selected_idx and i == selected_idx then
        slots[i]:setSelect(true)
      else
        slots[i]:setSelect(false)
      end
    end
    curHeight = curHeight - slotSize
  end

  if firstMake then
    if shouldReset or times <= 0 then
      sv_rect:set_verticalNormalizedPosition( 1 )
      view:performWithDelay(0, function()
        goList:getComponent(RectTransform):set_anchoredPosition( Vector2(ap[1], ap[2]) )
      end)
    end
  end

  env.__topRow__    = topIndex
  env.__bottomRow__ = bottomIndex
end



function MakeVertListWrapped(env, firstMake)
  local view        = env.view
  local list        = env.list
  local nList       = table.getn(list)
  local sv          = env.sv
  local dir         = env.dir
  local slots       = env.slots
  local getSlot     = env.getSlot
  local defaultSelect = env.defaultSelect
  local updateSlot  = env.updateSlot
  local onComplete  = env.onComplete
  local shouldReset = env.shouldReset -- should reset content to top

  local slotHeight  = env.slotHeight
  local slotWidth   = env.slotWidth
  
  local goList = sv.transform:find("List")
  local sv_rect = sv.scrollRect
  local sr_bar = sv_rect:get_verticalScrollbar()
  
  local scale = sv.transform:get_rect():get_width()/slotWidth
  slotHeight  = slotHeight * scale
  slotWidth   = slotWidth * scale


  local slotSize = slotHeight
  local viewPortSize = sv.gameObject:getComponent(RectTransform).rect.height

  --如果reset或者第一次初始化，设置scroll rect到初始位置
  view._makeScrollListTimes = view._makeScrollListTimes or {}
  local id = goList.gameObject:GetInstanceID()
  view._makeScrollListTimes[id] = view._makeScrollListTimes[id] or 0
  local times = view._makeScrollListTimes[id]

  local selected_idx = view._scrollSelectedIndices[id]

  if firstMake then
    if shouldReset or times <= 0 then
      sv_rect:set_verticalNormalizedPosition( 1 )
    end
  end

  local totalHeight = nList * slotSize
  goList:set_sizeDelta(Vector2(slotWidth, totalHeight))

  local ap = goList:getComponent(RectTransform):get_anchoredPosition()
  if firstMake and selected_idx then
    ap[2] = slotSize * (selected_idx - 1)
    if ap[2] > totalHeight - viewPortSize then ap[2] = totalHeight - viewPortSize end
    goList:getComponent(RectTransform):set_anchoredPosition( Vector2(0, ap[2]) )
  end

  -- if firstMake then goList:getComponent(RectTransform):set_anchoredPosition(Vector2(0, 0)) end
  local offset = ap[2]
  local topIndex = math.max(math.ceil(offset/slotSize) - 1, 1)
  local bottomIndex = math.min(math.ceil((offset + viewPortSize)/slotSize) + 1, nList)
  if env.__topRow__  == topIndex and
     env.__bottomRow__ == bottomIndex then
    return
  end

  for i = 1, topIndex - 1 do
    if slots[i] then
      slots[i]:destroy()
      slots[i] = nil
    end
  end

  if sv.nList then
    local iStart = nList + 1
    if iStart > (bottomIndex + 1) then
      iStart = bottomIndex + 1
    end

    for i=iStart, sv.nList do
      if slots[i] then
        slots[i]:destroy()
        slots[i] = nil
      end
    end
  end
  sv.nList = nList

  local curHeight = -slotSize/2   --原来的   totalHeight - slotSize/2
  curHeight = curHeight - (topIndex-1) * slotSize
  for i = topIndex, bottomIndex do
    v = list[i]
    if not slots[i] then
      local slot = getSlot(view, i, v)
      local le = slot.gameObject:getComponent(LayoutElement)
      if le then le:set_ignoreLayout( true) end
      slot:setParent(goList, false)
      slot.transform:set_anchoredPosition( Vector2(slotWidth/2, curHeight) )
      -----------------
      slot.transform:set_sizeDelta(Vector2(slotWidth,slotHeight))
      --------------------
      slots[i] = slot
    else
      slots[i].transform:set_anchoredPosition( Vector2(slotWidth/2, curHeight) )
      if updateSlot then updateSlot(view, i, v) end
    end

    if type(slots[i].setSelect) == 'function' then
      -- loge(">>>>> i:%s", tostring(i))
      -- loge(">>>>> selected_idx:%s", tostring(selected_idx))
      if selected_idx and i == selected_idx then
        slots[i]:setSelect(true)
      else
        slots[i]:setSelect(false)
      end
    end

    curHeight = curHeight - slotSize
  end

  if firstMake then
    if shouldReset or times <= 0 then
      sv_rect:set_verticalNormalizedPosition( 1 )
      view:performWithDelay(0, function()
        goList:getComponent(RectTransform):set_anchoredPosition( Vector2(0, ap[2]) )
      end)
    end
  end

  env.__topRow__    = topIndex
  env.__bottomRow__ = bottomIndex
end


function MakeHorizontalListWrapped(env, firstMake)
  local view        = env.view
  local list        = env.list
  local nList       = table.getn(list)
  local sv          = env.sv
  local dir         = env.dir
  local slots       = env.slots
  local getSlot     = env.getSlot
  local defaultSelect = env.defaultSelect
  local updateSlot  = env.updateSlot
  local onComplete  = env.onComplete
  local shouldReset = env.shouldReset -- should reset content to top

  local slotHeight  = env.slotHeight
  local slotWidth   = env.slotWidth

  local goList = sv.transform:find("List")
  local sv_rect = sv.scrollRect
  local sr_bar = sv_rect:get_horizontalScrollbar()
  local slotSize = slotWidth
  local viewPortSize = sv.gameObject:getComponent(RectTransform):get_rect():get_width()

  --如果reset或者第一次初始化，设置scroll rect到初试位置
  view._makeScrollListTimes = view._makeScrollListTimes or {}
  local id = goList.gameObject:GetInstanceID()
  view._makeScrollListTimes[id] = view._makeScrollListTimes[id] or 0
  local times = view._makeScrollListTimes[id]


  view._scrollSelectedIndices = view._scrollSelectedIndices or {}
  if defaultSelect then view._scrollSelectedIndices[id] = defaultSelect end
  local selected_idx = view._scrollSelectedIndices[id]

  if firstMake then
    if shouldReset or times <= 0 then
      -- sv_rect:set_horizontalNormalizedPosition( 1 )
      sv_rect:set_horizontalNormalizedPosition( 0 )
    end
  end

  local totalWidth = nList * slotSize
  goList:set_sizeDelta(Vector2(totalWidth, slotHeight))
  local ap = goList:getComponent(RectTransform):get_anchoredPosition()
  if firstMake and selected_idx then
    ap[1] = slotSize * (selected_idx - 1)
    if ap[1] > totalWidth - viewPortSize then ap[1] = totalWidth - viewPortSize end
    goList:getComponent(RectTransform):set_anchoredPosition( Vector2(ap[1], 0) )
  end

  -- local offset = goList:getComponent(RectTransform):get_anchoredPosition()[1]
  local offset = ap[1]
  local leftIndex = math.max(math.ceil(-offset/slotSize), 1)     --原来 ： math.max(math.ceil(offset/slotSize) - 1, 1)
  local rightIndex = math.min(math.ceil((-offset + viewPortSize)/slotSize), nList)    --原来 ： math.min(math.ceil((offset + viewPortSize)/slotSize) + 1, nList)

  for i = 1, leftIndex - 1 do
    if slots[i] then
      slots[i]:destroy()
      slots[i] = nil
    end
  end

  for i = rightIndex + 1, nList do
    if slots[i] then
      slots[i]:destroy()
      slots[i] = nil
    end
  end

  local curOffset = slotWidth/2    --原来 ： totalWidth - slotHeight/2
  curOffset = curOffset + (leftIndex-1) * slotSize    --原来 ： curOffset - (leftIndex-1) * slotSize

  for i = leftIndex, rightIndex do
    v = list[i]
    if not slots[i] then
      local slot = getSlot(view, i, v)
      local le = slot.gameObject:getComponent(LayoutElement)
      if le then le.ignoreLayout = true end
      slot:setParent(goList, false)
      slot.transform:set_anchoredPosition( Vector2(curOffset, 0) )     --原来 ： Vector2(curOffset, slotHeight/2)
      slots[i] = slot
    else
      slots[i].transform:set_anchoredPosition( Vector2(curOffset, 0) )    --原来 ： Vector2(curOffset, slotHeight/2)
      if updateSlot then updateSlot(view, i, v) end
    end

    if firstMake and type(slots[i].setSelect) == 'function' then
      if selected_idx and i == selected_idx then
        slots[i]:setSelect(true)
      else
        slots[i]:setSelect(false)
      end
    end

    curOffset = curOffset + slotSize     --原来 ： curOffset - slotSize
  end

  if firstMake then
    if shouldReset or times <= 0 then
      sv_rect:set_horizontalNormalizedPosition( 1 )
      view:performWithDelay(0, function()
        goList:getComponent(RectTransform):set_anchoredPosition(Vector2(ap[1], 0))
      end)
    end
  end
end

function MakeHorizontalListPaged(env)
  local slotWidth       = env.slotWidth
  local view            = env.view
  local list            = env.list
  local nList           = table.getn(list)
  local sv              = env.sv
  local dir             = env.dir
  local slots           = env.slots
  local getSlot         = env.getSlot
  local onComplete      = env.onComplete
  local updateSlot      = env.updateSlot
  local shouldReset     = env.shouldReset -- should reset content to top
  local noDisableLayout = env.noDisableLayout
  local goList          = sv.transform:find("List")
  local rtTrans         = sv.rectTransform
  local rtRect          = rtTrans:get_rect()
  local worldPoint      = rtTrans:TransformPoint(Vector3(rtRect:get_x(), rtRect:get_y(), 0))
  local worldRect       = Rect(worldPoint[1], worldPoint[2], rtRect:get_width(), rtRect:get_height())
  local sv_rect         = sv.scrollRect
  local maxPage         = math.ceil(nList / env.pageSlots)
  if slotWidth then sv:setItemSize(slotWidth) end

  for i = 1, nList do
    v = list[i]
    if not slots[i] then
      local slot = getSlot(view, i, v)
      slot:setParent(goList, false)
      slots[i] = slot
    else
      if updateSlot then updateSlot(view, i, v) end
    end
    -- curOffset = curOffset - slotSize
  end
  -- assert(goList)


  local layout = goList:getComponent(UnityEngine.UI.LayoutGroup)

  if layout then
    if not noDisableLayout then layout.enabled = false end
    scheduler.performWithDelay(0.1, function()
      layout.enabled = true
      layout:SetLayoutHorizontal()
      if onComplete then
        onComplete(view)
      end
    end)
  end

  view.sv = sv
end

function turnHorizontalPage(env, addPage, animate)
  local sv = env.sv
  sv:set_page( sv.page + addPage)
  local page = sv.page
  local goList = sv.transform:find("List")
  if animate then
     sv.tw = GoTween(goList, 0.4, GoTweenConfig()
        :localPosition(Vector3((1-page) * env.slotWidth, 0, 0), false)
        :onComplete(function()
          Go.RemoveTween(sv.tw)
        end)
        )
    Go.AddTween(sv.tw)
  else
    goList:set_localPosition(Vector3((1 - page) * env.slotWidth, 0, 0))
  end
  if sv.__changePage then sv.__changePage(page) end
end

-- 让scroll view 显示到最下方，
--然后从最底部开始数，往下移动slot,保证选择的slot在可视的区域内
--适用于 vertical list, 以及 使用MakeList生成的scroll view
function moveScrollView(choosedIndex, visiableNum, list, svHash)
  local visiableNum = visiableNum
  local index = choosedIndex
  local nList = table.getn(list)
  local slotsNum = nList
  if index <= visiableNum then
    ScrollListUtil.moveDown(svHash, 1)
    return
  end

  if index <= slotsNum then
    local delta = 1 / (slotsNum - visiableNum)
    local num = delta * (slotsNum - index)
    ScrollListUtil.moveDown(svHash, num)
    return
  end
end

function moveDown(scrollHash, num)
  local svRect = scrollHash.svRect

  scheduler.performWithDelay(0, function()
    svRect.verticalNormalizedPosition = num
  end)

end




class('TouchUtil')

local m = TouchUtil


local TouchPhase_Began = UnityEngine.TouchPhase.Began
local TouchPhase_Moved = UnityEngine.TouchPhase.Moved
local TouchPhase_Canceled = UnityEngine.TouchPhase.Canceled
local TouchPhase_Ended = UnityEngine.TouchPhase.Ended
local Input = UnityEngine.Input
local InputSource = InputSource
local Vector2 = UnityEngine.Vector2
local EventSystem = UnityEngine.EventSystems.EventSystem
local PointerEventData = UnityEngine.EventSystems.PointerEventData

function m.findTouch(fingerId)
  local res = nil
  for i = 0, InputSource.getTouchCount() - 1 do
    local touch = InputSource.getTouch(i)
    if touch:get_fingerId() == fingerId then
      res = touch
      break
    end
  end
  return res
end

function m.detectTipTouch(node, onClickOutTipsRect, isView)
  if InputSource.getTouchCount() > 0 then
    local pos = nil
    local touch = nil
    if node.touchInfo then
      touch = m.findTouch(node.touchInfo.fingerId)
    else
      touch = InputSource.getTouch(0)
    end
    local pos = touch:get_position()
    local phase = touch:get_phase()

    local hit = false
    if isView then
      hit = UIUtil.pointInTipDisplayRect(node, pos)
    else
      hit = UIUtil.pointInCtrl(node, pos)
    end
    if phase == TouchPhase_Began then
      node.touchInfo = {}
      node.touchInfo.fingerId = touch:get_fingerId()
      node.touchInfo.inTipRect = hit
    elseif phase == TouchPhase_Canceled then
      if node.touchInfo then
        if not node.touchInfo.inTipRect and onClickOutTipsRect then
          onClickOutTipsRect()
        end
        node.touchInfo = nil
      end
    elseif phase == TouchPhase_Ended then
      if node.touchInfo then
        if not node.touchInfo.inTipRect and onClickOutTipsRect then
          onClickOutTipsRect()
        end
        node.touchInfo = nil
      end
    end
  end

  if game.editor() then
    local pos = nil
    local down = false
    local move = false
    local up = false
    if Input.GetMouseButtonDown (0) then
      pos = Input:get_mousePosition()
      down = true
    end

    if Input.GetMouseButton (0) then
      pos = Input:get_mousePosition()
      move = true
    end

    if Input.GetMouseButtonUp (0) then
      pos = Input:get_mousePosition()
      up = true
    end

    if pos then
      --local hit = UIUtil.pointInCtrl(node, pos)
      local hit = false
      if isView then
        hit = UIUtil.pointInTipDisplayRect(node, pos)
      else
        hit = UIUtil.pointInCtrl(node, pos)
      end
      if down then
        if not node.touchInfo then
          node.touchInfo = {}
          node.touchInfo.inTipRect = hit
        end
      elseif up then
        if node.touchInfo then
          if not node.touchInfo.inTipRect and onClickOutTipsRect then
            onClickOutTipsRect()
          end
          node.touchInfo = nil
        end
      end
    end
  end
end

function m.click(onClick, onBegin, onEnd, onMove)
  local pointerId = nil
  -- local tm = nil
  return function(eventType, event, param)
    local eventPos = event:get_position()
    local pressPos = event.pressPosition
    local eventPointerId = event:get_pointerId()
    if eventType == 'begin' then
      if pointerId then return end
      pointerId = eventPointerId
      -- tm = Time.time
      if onBegin then onBegin(eventPos, param) end
    elseif eventType == 'move' then
      if eventPointerId ~= pointerId then return end
      if onMove then
        local newpos = eventPos
        local delta = Vector2(newpos[1] - pressPos[1], newpos[2] - pressPos[2])
        onMove(eventPos, delta, param)
      end
    elseif eventType == 'end' then
      if eventPointerId ~= pointerId then return end
      pointerId = nil
      if onEnd then onEnd(eventPos, param) end
    elseif eventType == 'click' then
      local newpos = eventPos
      -- local newTm = Time.time
      if newpos[1] - pressPos[1] >= 10 or newpos[2] - pressPos[2] >= 10 then return end
      -- if newTm - tm >= 1 then return end
      if onClick then onClick(eventPos, param) end
    end
  end
end

function m.getRect(rects, rctrans)
  TouchUtil.getCtrlRectsRecursive(rects, rctrans)
  table.sort(rects, function (a, b) return a.width * a.height > b.width * b.height end)
  for i = #rects, 1, -1 do
    for j = 1, #rects do
      if j ~= i then
        local r1, r2 = rects[j], rects[i]
        if r1:Contains(Vector2(r2.xMin, r2.yMin)) and
          r1:Contains(Vector2(r2.xMax, r2.yMax)) then
          table.remove(rects, i)
          break
        end
      end
    end
  end
end

function m.getCtrlRectsRecursive(rects, root)
  local ctrlGo = root.gameObject
  local cg = ctrlGo:getComponent(CanvasGroup)
  if cg and not cg.blocksRaycasts then
    return
  end

  local rcTrans = ctrlGo:getComponent(RectTransform)
  if rcTrans then
    local cr = ctrlGo:getComponent(CanvasRenderer)
    if cr ~= nil and ctrlGo:isVisibleInScene() then
      local rect = rcTrans.rect
      if rect.width > 0 and rect.height > 0 then
        local scale = rcTrans:get_localScale()
        local size = Vector2.Scale(rect.size, scale * ui.scaleFactor)
        local pos = rcTrans:get_position()
        -- logd("[rect] pos:%s", inspect(pos))
        local uiCamera = ui.camera
        if uiCamera then
          pos = uiCamera:WorldToScreenPoint(pos)
        end

        local pivot = rcTrans.pivot
        local screenPos = Vector2(pos[1] - size[1] * pivot[1], pos[2] - size[2] * pivot[2])
        local screenRect = Rect(screenPos, size)
        table.insert(rects, screenRect)
      end
    end
  end

  for go in ctrlGo:iter() do
    m.getCtrlRectsRecursive(rects, go)
  end
end




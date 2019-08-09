class("OutsideEvtMonitor", function(self, view)
  self.view = view
  self.mask = nil
  self.bgColor = view.backGroundColor
  self:init()
end)

local m = OutsideEvtMonitor
local EventSystems = UnityEngine.EventSystems

local function fillEntries(trigger)
  local entries = {}
  local triggers = trigger:get_triggers()
  for t in Slua.iter(triggers) do
    entries[t.eventID] = t
  end
  return entries
end

function m:init()
  self.mask = self.view.gameObject:getComponent(UI.Image)
  if self.mask then
    self.mask:set_enabled(true)
  end

  self.mask = self.view.gameObject:addComponent(UI.Image)
  self.mask.type = UI.Image.Type.Sliced
  local color = self.bgColor or Color(0, 0, 0, 0)
  self.mask.color = color

  self:observeEvent()
end

function m:exit()
  self.mask = self.view.gameObject:getComponent(UI.Image)
  if self.mask then
    self.mask:set_enabled(false)
  end

  local eventId = EventSystems.EventTriggerType["PointerClick"]
  local entry = self.entries[eventId]
  self.view:removeAllListeners(entry.callback)
end

function m:observeEvent()
  self.executor = PointClickExecutor()
  self.trigger = self.view.gameObject:getComponent(EventSystems.EventTrigger)
  if is_null(self.trigger) then
    self.trigger = self.view.gameObject:addComponent(EventSystems.EventTrigger)
  end
  self.entries = self.entries or fillEntries(self.trigger)
  local eventId = EventSystems.EventTriggerType["PointerClick"]

  local entry = self.entries[eventId]
  if not entry then
    entry = EventSystems.EventTrigger.Entry()
    entry.eventID = eventId
    self.trigger.triggers:Add(entry)
  end

  local onClick = function(event)
    -- self.mask = self.view.gameObject:getComponent(UI.Image)
    -- logd("double mask "..tostring(self.mask))
    local pos = event.pressPosition

    if not UIUtil.pointInTipDisplayRect(self.view, pos) then
      --ui:remove(self.view)
      -- ui:pop()
      if self.view.onClickOutside and type(self.view.onClickOutside) == "function" then
        self.view.onClickOutside(self.view)
      else
        ui:remove(self.view)
      end

      if type(self.view.onDisappear) == 'function' then
        self.view:onDisappear()
      end

      if self.view.outTouchThrougth then
        if #ui:getViews() > 0 then
          self:forwardEvt(ui:getViews()[#ui:getViews()].gameObject, event)
        else
          self:forwardEvt(ui.baseView.gameObject, event)
        end
      end
    end
  end

  local callback = entry:get_callback()
  self.view:removeAllListeners(callback)
  self.view:addListener(callback, onClick)
  self.entries[eventId] = entry
end

function m:getClickHandler(go, pos, cam)
  local isUI3D = go:getComponent(Game.UI3D)
  if isUI3D then
    return nil
  end

  local g = self.executor:GetEventHandler(go);
  if g then
    local rct = g:getComponent(RectTransform)
    if rct then
      local hit = UnityEngine.RectTransformUtility.RectangleContainsScreenPoint(rct, pos, cam );
      if hit then
        return g
      end
    end
  end

  local sr = go:getComponent(UI.ScrollRect)
  if sr then
    local rct = go:getComponent(RectTransform)
    local hit = UnityEngine.RectTransformUtility.RectangleContainsScreenPoint(rct, pos, cam );
    if not hit then
      return nil
    end
  end

  if go.transform.childCount > 0 then
    for i=go.transform.childCount-1, 0, -1 do
      local cgo = go.transform:GetChild(i).gameObject
      cgo = self:getClickHandler(cgo, pos, cam)
      if cgo then
        return cgo
      end
    end
  end

  return nil
end

function m:forwardEvt(go, event)
  local goTarget = self:getClickHandler(go, event.position, event.pressEventCamera)
  if not goTarget then
    return
  end
  self.executor:Execute(goTarget, event, "pointerClickHandler")
end
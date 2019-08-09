class('ViewReseter', function(self, view)
  self.view = view
  self.states = {}
  --visible progress enable
end)

local m = ViewReseter

function m:recordResetPoint()
  if not self.view then return end
  if not self.view._nodes then return end

  local view = self.view

  -- bind all the nodes if it has a resetter
  local rootMapper = view.class.getRootMapper()
  if rootMapper then
    for varname, _ in pairs(rootMapper) do
      local n = view[varname]
    end
  end

  for k,v in pairs(view._nodes) do
    local visible = v.gameObject:isVisible()
    local record = {categories = v.categories,
                    visible = visible}
    self.states[k] = record
    -- logd(">>>>>>>k:"..k.." : "..inspect(v.categories))
    for _, category in pairs(v.categories) do
      local rcFunc = self["_record_"..category]
      if rcFunc then
        rcFunc(self, v, record)
      end
    end
  end
end

function m:_record_Button(node, record)
  record.enabled = node.button:get_interactable()
end

function m:_record_Toggle(node, record)
  record.isOn = node.toggle:get_isOn()
end

function m:_record_Image(node, record)
  local color = Color.new(node.image:get_color())
  if color then
    record.color = color
  end

  local t = node.image:get_type()
  if t and t == 3 then -- Image.Type.Filled
    record.fillAmount = node.image:get_fillAmount()
  end
end

function m:reset()
  for k,v in pairs(self.states) do
    local node = self.view._nodes[k]
    node:setVisible(v.visible)

    if node.gameObject then
      node.gameObject:setVisible(v.visible)
    end

    local view = node.gameObject:findLua()
    if view then
      view:setVisible(v.visible)
    end
    -- logd("ViewReseter name:%s visible:%s", node.gameObject:get_name(), tostring(v.visible))
    for _, category in pairs(v.categories) do
      local reFunc = self["_reset_"..category]
      if reFunc then
        -- logd(">>>>>>>k:"..inspect(k).." v:"..inspect(v))
        reFunc(self, node, v)
      end
    end
  end
end

function m:_reset_Button(node, record)
  node:setEnabled(record.enabled)
end

function m:_reset_Toggle(node, record)
  if record.isOn then
    node:setOn(record.isOn)
  end
end

function m:_reset_Image(node, record)
  if record.color then
    node.image:set_color(record.color)
  end

  if record.fillAmount then
    node.image:set_fillAmount(record.fillAmount)
  end
end

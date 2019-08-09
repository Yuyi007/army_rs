View('BonusesView', 'prefab/ui/common/bonus_ui', function(self, bonuses)
  self.animType = "level2"
  self.bonuses = bonuses
  self.resultSlots = {}
  self.grade = { '919191FF', '2DC571FF', '2C7CB3FF', 'CF7527FF' }
end)

local m = BonusesView

function m:init()
  self:initButtonSound()

  local alignment = 0
  if #self.bonuses <= 4 then alignment = 1 end
  self:createItems(alignment)
end

function m:initButtonSound()
  local buttonList = {}
  buttonList["btnClose"] = "ui_common/button001"
  UIUtil.resetButtonDefaultSound(self, buttonList)
end

function m:onBtnClose()
  ui:pop()
end

function m:onBtnBg()
	ui:pop()
end

function m:createItems(type)
	local goList = self.resultList.transform:find("List")
  local env = {
    view = self,
    list = self.bonuses,
    sv = self.resultList,
    goList = goList,
    dir = 'v',
    col = 5,
    spacing = 50,
    alignment = type,
    sizeW = 95,
    sizeH = 125,
    paddingTop = 1,
    slots = self.resultSlots,
    getSlot = self.getResultSlot,
    shouldReset = true,
  }  
  ScrollListUtil.MakeGridVOptimized(env)
end

function m:getResultSlot(index, data)
	local update = false
  if self.resultSlots[index] then
    update = true
    self.resultSlots[index]:update(index, data)
  else
    self.resultSlots[index] = BagResultSlot.new(self, index, data)
  end
  return self.resultSlots[index], update
end
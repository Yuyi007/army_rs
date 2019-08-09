View('CommonPopBuyView', 'prefab/ui/common/pop_buy_ui', function(self, options)
  self.animType     = "level2"
  self.options = options or {}
  -- self.__vsIndex = self.options.vsIndex or self.__vsIndex
end)

local m = CommonPopBuyView

function m:init()
  self.upCallback = self.options.upCallback or function()
    ui:pop()
  end
  self.downCallback = self.options.downCallback or function()
    ui:pop()
  end
  self.closeCallback = self.options.closeCallback or function()
    ui:pop()
  end

  self.bg:onClick(self.closeCallback)
  
  local itemNum = table.getn(self.options.items)
  self.kuo:setVisible(itemNum > 1)
  self.item1:setVisible(itemNum >= 1)
  self.item2:setVisible(itemNum >= 2)

  self:initUI(self.options.items)
  self:initButtonSound()
end

function m:initButtonSound()
  local buttonList = {}
  buttonList["btnClose"] = "ui_common/button001"
  UIUtil.resetButtonDefaultSound(self, buttonList)
end


function m:initUI(items)
  self.img:setSprite(self.options.selectIcon)
  self.item1_count:setString(items[1]['itemprice'])
  self.item1_sp:setSprite(items[1]['icon'])
  self.item2_count:setString(items[2]['itemprice'])
  self.item2_sp:setSprite(items[2]['icon'])
end


function m:onBtnClose()
  self.closeCallback()
end

function m:onItem1_btnConfirm()
  self.upCallback()
  ui:pop()
end

function m:onItem2_btnConfirm()
  self.downCallback()
  ui:pop()
end

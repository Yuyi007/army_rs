class('DeskCtrl', function(self, options)
	self:construc(options)
end)

local m = DeskCtrl

function m:construc(options)
	self.view  = options.view
	self.model = DeskModel.new()
	-- self.playerPoint = options.playerPoint
	-- self.leftPoint   = options.leftPoint
	-- self.rightPoint  = options.rightPoint
end


--添加一张卡并设置UI
function m:addCard(card, isSelect, pos)
	local cardView = ViewFactory.make('CardView')
	cardView:setModel(card)
  card:setCardView(cardView)
	cardView.isSelect = isSelect
	card.belongto = CHARACTER.DESK
  
  if pos == 0 then
    -- card.belongto = CHARACTER.DESK
    self.model:addCardList(card, cardView)
    local index = #self.model.cardList
    cardView:setCardPos(self.view.createpoint, index)
    cardView:setImageBack()
    
  elseif pos == 1 then
    -- card.belongto = CHARACTER.ME
    self.model:addPlayerList(card, cardView)
    local index = #self.model.playerList
  	cardView:setCardPos(self.view.plypoint, index)
  	cardView:setImage()
  elseif pos == 2 then
    -- card.belongto = CHARACTER.RIGHT
    self.model:addRightList(card, cardView)
    local index = #self.model.rightList
  	cardView:setCardPos(self.view.rightpoint, index)
  	cardView:setImage()
  else
    -- card.belongto = CHARACTER.LEFT
    self.model:addLeftList(card, cardView)
    local index = #self.model.leftList
  	cardView:setCardPos(self.view.leftpoint, index)
  	cardView:setImage()
  end	

  
end


--清空
function m:clearPoint(pos)
	if pos == 0 then
    for i = 1, #self.model.cardViews do
    	self.model.cardViews[i]:destroyView()
    end
    self.model:clearCardList()
    -- self.view:hideCreatPoint()
	elseif pos == 1 then
    for i = 1, #self.model.playerViews do
    	self.model.playerViews[i]:destroyView()
    end
    self.model:clearPlyaerList()
	elseif pos == 2 then
    for i = 1, #self.model.rightViews do
    	self.model.rightViews[i]:destroyView()
    end
    self.model:clearRightList()
	else
    for i = 1, #self.model.leftViews do
    	self.model.leftViews[i]:destroyView()
    end
    self.model:clearLeftList()
	end 	
end

function m:getCardsList()
  return self.model.cardList
end

function m:showPoint()
  self.view:setShowPoint(self.model.cardList)
end







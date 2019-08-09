class('CharacterCtrl', function(self, options)
	self:construc(options)
end)

local m = CharacterCtrl

function m:construc(options)
	self.view  = options.view
	self.identity = options.identity
	self.model = CharacterModel.new()	
end

function m:addCard(card, isSelect) --isSelect 增高
	self.model:setSaveCards(card)
	local cards = self.model.saveCards
	card.belongto = self.view.tag
	
	self:createCardUI(card, #cards, isSelect)
	
	self.view:setCardsNum(#cards)
	sm:playSound('Sound/givecard')
end

--手牌排序(升序)
function m:sort(asc)
	local cards = self.model.saveCards
	cc:sort(cards, asc)
	for i,model in pairs(cards) do
		for j,view in pairs(self.model.saveViews) do
			if model == view.model then
			  -- logd(">>>>model:%s,index:%s",tostring(model.weight),tostring(i)) 
				view:setCardPos(self.view.point, i)
			end
		end	
	end	
end

--电脑发牌
function m:smartSelectCards(cardType, weight, length, isBiggest)  --isBiggest 是不是最大的那个人
  local cards = self.model.saveCards
	ComputerAI.smartSelectCards(cards, cardType, weight, length,  isBiggest)
	if #ComputerAI.cardList ~= 0 then
		--删除手牌
		self:computerDelectCards()
		return true
  else
  	self.view:showPass()
  	return false
  end	
end

--电脑删除选中的牌
function m:computerDelectCards()
	local cards = ComputerAI.cardList
  -- local views = self.model.tempViews
	if  #cards == 0 then return end

	for i = 1, #cards do
	  table.removeVal(self.model.saveCards, cards[i])
  	table.removeVal(self.model.saveViews, cards[i].view ) 
  	cards[i].view:destroyView()
	end

	self:sort(true)
	self.view:setCardsNum(#self.model.saveCards)
	-- self.model:clearTempData()		
end


function m:createCardUI(card, index, isSelect)
	local cardView = ViewFactory.make('CardView')
	-- ui:push(cardView)
	cardView:setModel(card)
	card:setCardView(cardView)
	cardView.isSelect = isSelect
	cardView:setCardPos(self.view.point, index)
	cardView:setImage()
	self.model:setSaveViews(cardView)
end

--发牌
function m:DealCard()
	local cards = self.model.saveCards
	local count = #cards
	local card = cards(count)
	cards.remove(cards, count)
	return card
end

--玩家选中的牌
function m:findSelectFind()
	self.model:clearTempData()
	local views = self.model.saveViews
	for i = 1, #views do
		if views[i].isSelect then
			self.model:setTempData(views[i], views[i].model)
		end
	end
	cc:sort(self.model.tempCards, true)
  return self.model.tempCards
end


--玩家删除手牌
function m:destroySelectCards()
	local cards =  self.model.tempCards 
	local views = self.model.tempViews
  if #cards == 0 or #views == 0 then return end
  for i = 1,#cards do
    table.removeVal(self.model.saveCards, cards[i])
  	table.removeVal(self.model.saveViews, views[i]) 
  	views[i]:destroyView()
  end
  
  self:sort(true)
  self.view:setCardsNum(#self.model.saveCards)
  self.model:clearTempData()

  -- cc:sort(self.model.saveCards, true)
  return self.model.saveCards
end

--判断手牌为0时胜利
function m:caluWin()
  local cards = self.model.saveCards
  if #cards == 0 then return true end
  return false
end

--电脑是否能抢地主或者叫地主
function m:isDyzAndJdz(index)  --index随机数 1被选为最先叫地主
	local isfind = ComputerAI.caleIsQdZ(self.model.saveCards)
	-- logd(">>>>>>>isfind:%s,index:%s",inspect(isfind),tostring(index))
	if isfind then
		if index == 0 then 
			self.view:showJdz()
		else
		  self.view:showQdz()
		end  	 
  else
  	self.view:showBJ()
  end	
		  
  return isfind
end

function m:showPassView()
	self.view:showPass()
end

function m:myIsDyzAndJdz(index)
	if index == 0 then 
		self.view:showJdz()
	else
		self.view:showQdz()
  end 
end

--显示不叫地主
function m:showBjDz()
	self.view:showBJ()
end

function m:showInteViewGrab()
  local interView = InteractiveView.new()
  ui:push(interView, nil, false)
  interView:showGrabAndDisGrab()
end

function m:showInteViewDealAndPass()
  local interView = InteractiveView.new()
  ui:push(interView, nil, false)
  interView:showDealAndPass()
end


function m:setLandlordSp()
  self.view:setIdentity("Role_Landlord")
  self.identity = IDENTITY.Landlord
end

function m:getIdentity()
	return self.identity
end

function m:exit()
  self.model:clearTempData()
  self.model:clearSaveData()
end







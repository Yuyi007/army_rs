class('CombatController', function(self, roomId)
  self.roomId = roomId
  self.curWeight = nil     --储存当前的权值
  self.curLength = nil     --储存单前牌的长度
  self.biggestPly = nil    --上一回合的出牌者
  self.curPly = nil        --当前回合的出牌者
  self.curCardType = nil   --当前出牌的类型
  self.curIdentity = nil   --当前出牌身份
  -- self:construct()
end)

local m = CombatController

function m:init()
  self.queue = {}
  self.onEnter = false
  self.dzIndex = 0 --抢地主和叫地主基数 0为叫地主 >1为抢地主
  self.dizhuType = CHARACTER.ME
  self.curCardType = CARDTYPE.None
  self.curWeight   = -1
  self.curLength   = -1
  self.biggestPly  = CHARACTER.DESK
  self.curPly      = CHARACTER.DESK
  self.curIdentity = IDENTITY.Desk
  self:initCardLibrary()
  self:CreateGameUI()
  self:initRoundAndInteGration()
  -- CharacterUtil.init()
end

function m:CreateGameUI()
  local view = CharacterView.new(self.roomId)
  ui:setBaseView(view)
  local options = {view = view.playerView, identity = IDENTITY.Farmer}
  self.playerCtrl = CharacterCtrl.new(options)

  options = {view = view.leftView, identity = IDENTITY.Farmer}
  self.leftCtrl = CharacterCtrl.new(options)

  options = {view = view.rigthView, identity = IDENTITY.Farmer}
  self.rightCtrl = CharacterCtrl.new(options)

  options = {view = view.deskView, identity = IDENTITY.Desk}
  self.deskCtrl = DeskCtrl.new(options)
end

function m:initRoundAndInteGration()
  self.ruler = RulerUtil.new()
  -- self.round:init()
  self.integration = IntegrationModel.new()
  local options = 
  {
    meScore = 1000,
    leftScore = 1000,
    rightScore = 1000
  }
  self.integration:init(options)
end


function m:initCardLibrary()
  for col, i in pairs(COLOR) do
    for wei, j in pairs(WEIGHT) do
      if col ~= "None" and wei ~= "SJoker" and wei ~= "LJoker" then
        local name = col..wei
        local options = 
        {
          color    = i,
          weight   = j,
          name     = name,
          belongto = CHARACTER.LIBRARY
        }
        local card = CardModel.new(options)
        table.insert(self.queue, card)
      end
    end
  end
  
  local options = 
  {
    color    = COLOR.None,
    weight   = WEIGHT.SJoker,
    name     = "SJoker",
    belongto = CHARACTER.LIBRARY
  }
  local card = CardModel.new(options)
  table.insert(self.queue, card)
  
  local options = 
  {
    color    = COLOR.None,
    weight   = WEIGHT.LJoker,
    name     = "LJoker",
    belongto = CHARACTER.LIBRARY
  }
  card = CardModel.new(options)
  table.insert(self.queue, card)
  -- logd(">>>>>>>queue:%s",tostring(#self.queue))    
end

--给每个玩家以及桌面发牌
function m:addCard(type, card, point, isSelect) --isSelect (是否为地主牌)三张地主牌是要显示的
  if type == CHARACTER.ME then
    self.playerCtrl:addCard(card, isSelect)
  elseif type == CHARACTER.RIGHT then
    self.rightCtrl:addCard(card, isSelect)
  elseif type == CHARACTER.LEFT then
    self.leftCtrl:addCard(card, isSelect)
  elseif type == CHARACTER.DESK then

    self.deskCtrl:addCard(card, isSelect, point)
  end  
end



--发牌 54张
function m:deal()
  local curType = CHARACTER.ME
  local i  = 1
  local pos = 0
  self.SDeal =  scheduler.schedule(function ()

    if i > 51 then
      curType = CHARACTER.DESK
    else
      if curType == CHARACTER.LIBRARY or curType == CHARACTER.DESK then
        curType = CHARACTER.ME
      end
    end
      
    if i > 54 then
      scheduler.unschedule(self.SDeal)
      self.SDeal = nil 
      self:ctrlAutoSort()
      return
    end
    local card = self:DealCard(curType)
    self:addCard(curType, card, pos, false)
    curType = curType + 1
    i = i + 1

  end, 0.05)
  
end



function m:ctrlAutoSort()
  self.playerCtrl:sort(true)
  -----------------------电脑排序
  self.rightCtrl:sort(true)
  self.leftCtrl:sort(true)
  -------------------------
  self:isJDZ()
end


--自己和电脑判断抢地主事件
function m:isJDZ()

  scheduler.performWithDelay(1, function ()
    local find = self.rightCtrl:isDyzAndJdz(self.dzIndex)
    self.dzIndex = find and self.dzIndex + 1 or self.dzIndex
    self.dizhuType = find and CHARACTER.RIGHT or self.dizhuType
      
  end)  

  scheduler.performWithDelay(2, function ()
    local find = self.leftCtrl:isDyzAndJdz(self.dzIndex)
    self.dzIndex = find and self.dzIndex + 1 or self.dzIndex
    self.dizhuType = find and CHARACTER.LEFT or self.dizhuType
    self.playerCtrl:showInteViewGrab()
  end)
  
end

--玩家自己叫地主或者抢地主
function m:addDZIndex()
  self.playerCtrl:myIsDyzAndJdz(self.dzIndex)
  self.dzIndex = self.dzIndex + 1
  self.dizhuType = CHARACTER.ME
  self:dealDiZhuCards()
  scheduler.performWithDelay(0.5, function ()
    self:start()
  end) 
end

--玩家自己不叫地主
function m:loseDZ()
  self.playerCtrl:showBjDz()
  self:dealDiZhuCards()
  scheduler.performWithDelay(0.5, function ()
    self:start()
  end)  
end

--抢地主的人开始出牌
function m:start()
  self.biggestPly  = self.dizhuType
  self.curPly      =  self.dizhuType
  self:BeginWith(self.dizhuType) 
end

function m:BeginWith(type)
  if type == CHARACTER.ME then
    self.deskCtrl:clearPoint(1)
    self.playerCtrl:showInteViewDealAndPass()
  elseif type == CHARACTER.RIGHT then
    self.deskCtrl:clearPoint(2)
    scheduler.performWithDelay(1.5, function ()
      self.curPly  = CHARACTER.RIGHT
      local ident = self.rightCtrl:getIdentity()
      if self.curIdentity ~= ident or self.biggestPly == CHARACTER.RIGHT or self.curCardType < 5 then 
        local find = self.rightCtrl:smartSelectCards(self.curCardType, self.curWeight, self.curLength, self.biggestPly ==  CHARACTER.RIGHT)
        local win = self.rightCtrl:caluWin()
        if win then
          -- self.curIdentity = ident 
          self:initOverUI(ident, self.playerCtrl:getIdentity())
          return
        end

        if find then
          if self.biggestPly == (CHARACTER.RIGHT or CHARACTER.DESK) or ComputerAI.curType < 4 then 
            logd(">>>>enter-right")
            self:playCardsSound(ComputerAI.curType, ComputerAI.curWeight)
          else
            local si = math.random(1,3)
            sm:playSound('Sound/dani'..si)
          end 
          self.biggestPly  = CHARACTER.RIGHT
          
          self.curWeight   = ComputerAI.curWeight
          self.curLength   = ComputerAI.curLength
          self.curCardType = ComputerAI.curType
          local cards = ComputerAI.cardList
           --显示桌面的牌
          for i,card in pairs(cards) do
            self.deskCtrl:addCard(card, false, 2)
          end
          self.curIdentity = ident
        end
      else
        self.rightCtrl:showPassView()
      end
      
      self:Turn()  
    end) 
  elseif type == CHARACTER.LEFT then
    self.deskCtrl:clearPoint(3)
    scheduler.performWithDelay(1.5, function ()
      self.curPly  = CHARACTER.LEFT

      local ident = self.leftCtrl:getIdentity()
      if self.curIdentity ~= ident or self.biggestPly == CHARACTER.LEFT or self.curCardType < 5 then
        local find = self.leftCtrl:smartSelectCards(self.curCardType, self.curWeight, self.curLength, self.biggestPly ==  CHARACTER.LEFT)
        local win = self.leftCtrl:caluWin()
        if win then 
          self:initOverUI(ident, self.playerCtrl:getIdentity())
          return
        end
        if find then
          if self.biggestPly == (CHARACTER.RIGHT or CHARACTER.DESK) or ComputerAI.curType < 4 then
            logd(">>>>enter-left") 
            self:playCardsSound(ComputerAI.curType, ComputerAI.curWeight)
          else
            local si = math.random(1,3)
            sm:playSound('Sound/dani'..si)
          end 
          self.biggestPly  = CHARACTER.LEFT
          
          self.curWeight   = ComputerAI.curWeight
          self.curLength   = ComputerAI.curLength
          self.curCardType = ComputerAI.curType
          local cards = ComputerAI.cardList
           --显示桌面的牌
          for i,card in pairs(cards) do
            self.deskCtrl:addCard(card, false, 3)
          end
          self.curIdentity = ident
        end
      else
        self.leftCtrl:showPassView()
      end 

      self:Turn()
    end) 
  end
end

function m:canPlay()
  local cards =  self.playerCtrl:findSelectFind()
  local info = self.ruler:canPop(cards)
  if not info then FloatingTextFactory.makeFramed{text = loc("请重新出牌")} return end
  local totalweight = self:getCardsWeight(info.cardData, info.cardType)
  self.curPly  = CHARACTER.ME

  -- logd(">>>>infotype:%s,curType:%s",tostring(info.cardType),tostring(self.curCardType))
  -- logd(">>>>>>totalweight:%s,curWeight:%s",tostring(totalweight),tostring(self.curWeight))
  if self.biggestPly ~= CHARACTER.ME then
    if info.cardType == CARDTYPE.JokerBoom or (info.cardType == CARDTYPE.Boom and info.cardType > self.curCardType) then
      self:setTypeData(info, totalweight)
    elseif info.cardType == self.curCardType and totalweight > self.curWeight then
      self:setTypeData(info, totalweight)
    else
      FloatingTextFactory.makeFramed{text = loc("请重新出牌")}
    end
  else
    self:setTypeData(info, totalweight)
  end  
end

function m:setTypeData(info, totalweight)
  if self.biggestPly == (CHARACTER.ME or CHARACTER.DESK) or ComputerAI.curType < 4 then
  logd(">>>>enter-my") 
  self:playCardsSound(info.cardType, totalweight)
else
  local si = math.random(1,3)
  sm:playSound('Sound/dani'..si)
end 

  ui:removeWithName("InteractiveView")

  self.biggestPly  = CHARACTER.ME
  self.curCardType = info.cardType
  self.curWeight   = totalweight
  self.curLength   = #info.cardData

  for i,card in pairs(info.cardData) do
    self.deskCtrl:addCard(card, false, 1)
  end

  self.playerCtrl:destroySelectCards()
  local win =  self.playerCtrl:caluWin()
  if win then
    local ident = self.playerCtrl:getIdentity()
    self:initOverUI(ident, ident)
    return
  end
  
  self.curIdentity = self.playerCtrl:getIdentity()

  self:Turn()
end

--玩家不出
function m:playPass(ctrl)
  ctrl:showPassView()
  self:Turn()
end

--轮换出牌
function m:Turn()
  self.curPly = self.curPly + 1
  if self.curPly == CHARACTER.DESK  or self.curPly == CHARACTER.LIBRARY then
    self.curPly = CHARACTER.ME
  end
  self:BeginWith(self.curPly) 
end


--将桌面的三张牌给地主
function m:dealDiZhuCards()
  local list = self.deskCtrl:getCardsList()
  for _,card in pairs(list) do
    -- logd(">>>>>>weight:%s",tostring(card.weight))
    self:addCard(self.dizhuType, card, nil, false)
  end
  self.deskCtrl:showPoint()
  self.deskCtrl:clearPoint(0)

  if self.dizhuType ==  CHARACTER.ME then 
    self.playerCtrl:sort(true)
    self.playerCtrl:setLandlordSp()
    self.curIdentity = self.playerCtrl:getIdentity()
  elseif self.dizhuType == CHARACTER.RIGHT then
    self.rightCtrl:sort(true)
    self.rightCtrl:setLandlordSp()
    self.curIdentity = self.rightCtrl:getIdentity()
  else
    self.leftCtrl:sort(true)
    self.leftCtrl:setLandlordSp()
    self.curIdentity = self.leftCtrl:getIdentity()
  end  
end

--洗牌
function m:shuffle()
  local newlist = {}
  local count = table.getn(self.queue)
  for i,card in pairs(self.queue)  do
    local listcount = table.getn(newlist)
    local index = math.random(1, listcount)
    table.insert(newlist, index, card)
  end
  table.clear(self.queue)

  count = table.getn(newlist)
  for i,card in pairs(newlist) do
    table.insert(self.queue, newlist[i])
  end
  table.clear(newlist)
 
end

--发牌
function m:DealCard(sendTo)
  local count = table.getn(self.queue)
  -- if count <= 3 then return end --留三张地主的牌
  local index = math.random(1, count)
  local card = self.queue[index]
  card.belongto = sendTo
  table.remove(self.queue, index)
  return card
end

--排序 asc可能是升序也有可能是降序
function m:sort(cards, asc)
  if asc then --升序
    table.quicksort(cards, nil, nil, function(x, y)
      return x.weight <= y.weight
    end)
  else --降序
    table.quicksort(cards, nil, nil, function (x, y)
      return x.weight >= y.weight
    end)
  end  
end

function m:getCardsWeight(cards, type)
  local totalweight = 0
  
  if type == CARDTYPE.ThreeAndOne or type == CARDTYPE.ThreeAndTwo then
    for i = 1,#cards-2 do
      if cards[i].weight == cards[i + 1].weight and cards[i].weight == cards[i + 2].weight then
        totalweight = totalweight + cards[i].weight * 3
      end
    end
  -- elseif type == CARDTYPE.Straight or type == CARDTYPE.DoubleStraight  then  --or type == CARDTYPE.TwoDouble
  --   totalweight = totalweight + cards[i].weight
  else
    for i = 1, #cards do
      totalweight = totalweight + cards[i].weight
    end 
  end 
  logd(">>>>>>>totalweight:%s",tostring(totalweight))
  return totalweight
end

function m:exit()
  if self.SDeal then
    scheduler.unschedule(self.SDeal)
    self.SDeal = nil
  end 

  self.dzIndex = 0  
end

function m:setDragValue(value)
  self.onEnter = value
end

function m:initOverUI(curident, myident)
  local overView = CombatOverView.new(curident, myident)
  ui:push(overView)
end

function m:playCardsSound(type, weight)
  logd(">>>>>>>type:%s,weight:%s",tostring(type),tostring(weight))
  if type == 1 then
    sm:playSound('Sound/'..weight)
  elseif type == 2 then
    local i = weight/2
    sm:playSound('Sound/dui'..i)
  else
    sm:playSound('Sound/'..SOUNDS[type])
  end  
end







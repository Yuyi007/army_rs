class('DeskModel', function(self)
  self.playerList = {}  
  self.playerViews = {}  
  self.leftList   = {}
  self.leftViews = {}      
  self.rightList  = {} 
  self.rightViews = {}  
  self.cardList = {}
  self.cardViews = {}
end)

local m = DeskModel

function m:addCardList(card, view)
  if card == nil then return end
  table.insert(self.cardList, card)
  table.insert(self.cardViews, view)
end

function m:addLeftList(card, view)
  if card == nil then return end
  table.insert(self.leftList, card)
  table.insert(self.leftViews, view)
end

function m:addRightList(card, view)
  if card == nil then return end
  table.insert(self.rightList, card)
  table.insert(self.rightViews, view)
end

function m:addPlayerList(card, view)
  if card == nil then return end
  table.insert(self.playerList, card)
  table.insert(self.playerViews, view)
end

function m:clearPlyaerList()
  table.clear(self.playerList)
  table.clear(self.playerViews)
end

function m:clearLeftList()
  table.clear(self.leftList)
  table.clear(self.leftViews)
end

function m:clearRightList()
  table.clear(self.rightList)
  table.clear(self.rightViews)
end

function m:clearCardList()
  table.clear(self.cardList)
  table.clear(self.cardViews)
end
class('CharacterModel', function(self)
  self.saveCards = {}      --储存的cards与UI同步
  self.saveViews  = {}      --存储的UI与cards同步
  self.tempCards = {}  --出牌的cards
  self.tempViews = {}  --出牌的UI
end)

local m = CharacterModel

function m:setSaveCards(card)
  if card == nil then return end
  table.insert(self.saveCards, card)
end

function m:setSaveViews(view)
  if view == nil then return end
  table.insert(self.saveViews, view)
end

function m:setTempData(view, card)
  if card == nil or view == nil then return end
  table.insert(self.tempCards, card)
  table.insert(self.tempViews, view)
end

function m:clearTempData()
  table.clear(self.tempCards)
  table.clear(self.tempViews)
end

function m:clearSaveData()
  table.clear(self.saveCards)
  table.clear(self.saveViews)
end

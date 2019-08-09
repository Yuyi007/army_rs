View("CharacterView", "prefab/ui/room/player_ui", function(self, roomId)
  self.roomId = roomId
  self.score = 1000
end)

local m = CharacterView
local str = "剩余手牌:"

function m:init()
  self:initUI()

  self.playerView = MyPlayerView.new(self.me, self)
  self.leftView   = LeftPlayerView.new(self.left, self)
  self.rigthView  = RightPlayerView.new(self.right, self)
  self.deskView   = DeskView.new(self.desk, self)
  -- self:getPlayerData()
  -- cc:deal()
 local interView = InteractiveView.new()
 -- self.interView = ViewFactory.make('InteractiveView')
 ui:push(interView, nil, false)
end

function m:initUI()
	self.me_head:setSprite("Role_Farmer")
	self.left_head:setSprite("Role_Farmer")
	self.right_head:setSprite("Role_Farmer")
	self.me_card:setString("剩余手牌:0")
	self.left_card:setString("剩余手牌:0")
	self.right_card:setString("剩余手牌:0")
	self.me_score:setString(self.score)
  self.left_score:setString(self.score)
  self.right_score:setString(self.score)
end

function m:getPlayerData()
	md:rpcGetPlayerData(self.roomId, function(msg)
		self:updateScore(msg)
	end)
end

function m:updateScore(msg)
  self.me_score:setString(msg['me'])
  self.left_score:setString(msg['left'])
  self.right_score:setString(msg['right'])
end

function m:initSignal()
	self.result = function(msg)
		
	end
	self.sCardNum = function(msg)
		-- self:updateCardNum(msg)
	end

	md:signal("game_over"):add(self.result)
	md:signal("card_num"):add(self.sCardNum)
end



function m:setPlayerIdentity(value)
	self.me_head:setSprite(value)
end

function m:setLeftIdentity(value)
	self.left_head:setSprite(value)
end

function m:setRightIdentity(value)
	self.right_head:setSprite(value)
end

function m:playerAddCard(card)
	CharacterUtil.addCard(card, 1, self.me_point, false, function(num)
		self.me_card:setString(str..num)
	end)
end

function m:rightAddCard(card)
	CharacterUtil.addCard(card, 2, self.right_point, false, function(num)
		self.right_card:setString(str..num)
	end)
end

function m:leftAddCard(card)
	CharacterUtil.addCard(card, 3, self.left_point, false, function(num)
		self.left_card:setString(str..num)
	end)
end

function m:updateCardNum(msg)
	self.me_card:setString(str..msg['me'].cardNum)
	self.left_card:setString(str..msg['left'].cardNum)
	self.right_card:setString(str..msg['right'].cardNum)
end

function m:showDizhuCard(sp)
	self.showpoint:setVisible(true)
	self.showpoint_img1:setSprite(sp[1])
	self.showpoint_img1:setSprite(sp[2])
	self.showpoint_img1:setSprite(sp[3])
end

-- function m:createCardUI(card, index, point)
-- 	local cardView = ViewFactory.make('CardView')
-- 	cardView.setModel(card)
-- 	cardView.setCardPos(point,index)
-- 	cardView:setImage()
-- end

function m:hideDizhuCard()
	self.showpoint:setVisible(false)
end

function m:exit()
  if self.result then
  	md:signal('game_over'):remove(self.result)
  	self.result = nil
  end	
end
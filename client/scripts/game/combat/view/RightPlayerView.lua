View('RightPlayerView', nil, function(self, gameObject, parent)
  self:bind(gameObject)
  self.parent = self
  self.tag = CHARACTER.RIGHT
end)

local m = RightPlayerView
local str = "剩余手牌:"

function m:init()
  
end

function m:exit()
	
end

function m:setIdentity(sp)
  self.head:setSprite(sp)
end

function m:setCardsNum(num)
  self.card:setString(str..num)
end

function m:setScoreNum(num)
  self.score:setString(num)
end

function m:showPass()
  self.pass:setVisible(true)
  --播放不出的声音
  local si = math.random(1,3)
  sm:playSound('Sound/buyao'..si)
  self:performWithDelay(1.5, function()
  	self.pass:setVisible(false)
  end)
end

function m:showJdz()
  self.jdz:setVisible(true)
  --播放叫地主的声音
  sm:playSound('Sound/zhuadizhu')
  self:performWithDelay(1.5, function()
    self.jdz:setVisible(false)
  end)
end

function m:showQdz()
  self.qdz:setVisible(true)
  --播放抢地主的声音
  sm:playSound('Sound/qiangdizhu1')
  self:performWithDelay(1.5, function()
    self.qdz:setVisible(false)
  end)
end

function m:showBJ()
  self.bj:setVisible(true)
  --播放不叫地主的声音
  sm:playSound('Sound/buqiang')
  self:performWithDelay(1.5, function()
    self.bj:setVisible(false)
  end)
end
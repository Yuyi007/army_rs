--移交服务器
class('RoundModel', function(self)
  self.curWeight = nil     --储存当前的权值
  self.curLength = nil     --储存单前牌的长度
  self.biggestPly = nil    --上一回合的出牌者
  self.curPly = nil        --当前回合的出牌者
  self.curCardType = nil   --当前出牌的类型
end)

local m = RoundModel

function m:init()
	self.curCardType = CARDTYPE.None
	self.curWeight   = -1
	self.curLength   = -1
	self.biggestPly  = CHARACTER.DESK
	self.curPly      = CHARACTER.DESK
end

--抢地主的人开始出牌
function m:start(plytype)
	self.biggestPly = plytype
	self.curPly  = plytype
	self:BeginWith(plytype)
end


function m:BeginWith(type)
	-- if type == CHARACTER.ME then
	-- 	--玩家出牌
	-- 	--Signal
 --    ui:signal("me"):fire()
	-- elseif type 
	-- 	--其他玩家出牌
	-- 	--Signal
	-- end	
end

--轮换出牌
function m:Turn()
	self.curPly = self.curPly + 1
	if self.curPly == CHARACTER.DESK  or self.curPly == CHARACTER.LIBRARY then
		self.curPly = CHARACTER.ME
	end
	self:BeginWith(self.curPly)	
end
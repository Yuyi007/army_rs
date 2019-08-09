class('IntegrationModel', function(self)
  self.point      = nil --底分
  self.mul        = nil --倍数
  self.result     = nil --分数
  self.meScore    = nil --玩家积分
  self.leftScore  = nil --左边玩家/电脑左边积分
  self.rightScore = nil --右边玩家/电脑右边积分
end)

local m = IntegrationModel

function m:init(options)
	self.point = 100
	self.mul = 1
	self.result = self.point * self.mul
	self.meScore    = options.meScore
	self.leftScore  = options.leftScore
	self.rightScore = options.rightScore
end

function m:getResult()
	if not self.mul or not self.point then return end
	return self.mul * self.point
end

function m:setMeScore(num)
	local score = 0
	self.meScore = self.meScore + num
	if self.meScore < 0 then self.meScore = 0 end
	score = self.meScore
  --Todo
    --玩家积分上传至服务器
  return score
end

function m:setLeftScore(score)
	self.leftScore = score
	if self.leftScore < 0 then self.leftScore = 0 end
	return self.leftScore
end

function m:setRightScore(score)
	self.rightScore = score
	if self.rightScore < 0 then self.rightScore = 0 end
	return self.rightScore
end


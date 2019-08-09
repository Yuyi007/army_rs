class('RulerUtil', function(self)
	self.Func = {}
  self:construct()
end)

local m = RulerUtil
local Func = {}

--判断能否出牌
function m:canPop(cards)
	local i = #cards
	local cardType = CARDTYPE.None
	local funcs = Func[i]
	for t,func in pairs(funcs) do
    local can = func(cards)
    if can then
    	-- local s = string.sub(tostring(func), 3, -1)
      cardType = CARDTYPE[t]
      logd(">>>>>>>canS:%s,%s",tostring(t),tostring(cardType))
      return {
      	cardType = cardType,
      	cardData = cards
      }
    end	
	end
	return false	
end

--单
local function isSigle(cards)
  return #cards == 1
end

--对儿
local function isDouble(cards)
  local count = #cards
  if count == 2 then
  	if cards[1].weight == cards[2].weight then
  		return true
  	end
  end
  return false		
end


local function isTwoDouble(cards)
	local count = #cards
	if count ~= 4 then return false end

	if cards[1].weight ~= cards[2].weight then return false end
	if cards[3].weight ~= cards[4].weight then return false end
	if cards[1].weight > WEIGHT.One or cards[3].weight > WEIGHT.One then return false end
	if cards[2].weight == cards[3].weight then return false end
	if cards[3].weight - cards[2].weight ~= 1 then return false end
	return true
end

--顺子
local function isStraight(cards)
	local count = #cards

	if count < 5 or count > 12 then return false end

	for i = 1, count-1  do	
		if cards[i + 1].weight - cards[i].weight ~= 1 then
			return false
		end

		if cards[i].weight > WEIGHT.One or cards[i + 1].weight > WEIGHT.One then
		  return false
		end 
	end

	return true	
end

--双顺 33445566
local function isDoubleStraight(cards)
	local count = #cards

	if count % 2 ~= 0 or count < 6 then
		return false
	end

  for i = 1, count-1, 2  do
  	if cards[i + 1 ].weight ~= cards[i].weight then
  		return false
  	end
  	
  	if i + 2 < count then
	  	if cards[i + 2].weight - cards[i].weight ~= 1 then
	  		return false
	  	end
	  end 	
    
    if i + 2 < count then
	    if cards[i].weight > WEIGHT.One or cards[i + 2].weight > WEIGHT.One then
			  return false
			end
		end		
  end

  return true	
end


--飞机
local function isTripleStraight(cards)
	local count = #cards

	if count % 3 ~= 0 or count < 6 then
		return false
	end
  
  for i =1, count-2, 3  do
  	if cards[i + 2].weight ~= cards[i].weight then
  		return false
  	end

    if i + 3 < count  then
	    if cards[i + 3].weight - cards[i].weight ~= 1 then
	  		return false
	  	end
	  end	
    
    if i + 3 < count  then
	  	if cards[i].weight > WEIGHT.One or cards[i + 3].weight > WEIGHT.One then
			  return false
			end
		end	   
  end	

  return true
end

--三不带
local function isThree(cards)
	local count = #cards
	if count == 3 and cards[1].weight == cards[3].weight then 
    return true
  end

  return false  	
end

--三带一  3444 4445
local function isThreeAndOne(cards)
	local count = #cards
	if count ~= 4 then return false end
	if cards[1].weight ~= cards[2].weight then
		if cards[2].weight == cards[4].weight then
			return true
		end
	else		
	  if cards[2].weight == cards[3].weight and cards[3].weight ~=  cards[4].weight then
	  	return true
	  end
	end

	return false
end

--三带二 33444 44455
local function isThreeAndTwo(cards)
	local count = #cards
	if count ~= 5 then return false end
	if cards[1].weight == cards[4].weight then return false end
	if cards[2].weight == cards[5].weight then return false end
	if cards[1].weight == cards[3].weight then return true end
	if cards[3].weight == cards[5].weight then return true end
  
  return false 
end

--炸弹
local function isBoom(cards)
	local count = #cards
	if count ~= 4 then return false end
	if cards[1].weight ~= cards[count].weight then return false end
	return true 
end

--王炸
local function isJokerBoom(cards)
	local count = #cards
	if count ~= 2 then return false end
	if cards[1].weight ~= WEIGHT.SJoker then return false end
	if cards[2].weight ~= WEIGHT.LJoker then return false end
	return true 
end

--牌54张
--每人发17张牌 剩下三张地主牌
function m:construct()
	Func[1]   = { Single = isSigle }
	Func[2]   = { Double = isDouble, JokerBoom = isJokerBoom}
	Func[3]   = { Three = isThree }
	Func[4]   = { TwoDouble = isTwoDouble, ThreeAndOne = isThreeAndOne, Boom = isBoom}
	Func[5]   = { Straight = isStraight, ThreeAndTwo = isThreeAndTwo}
	Func[6]   = { DoubleStraight = isDoubleStraight, Straight = isStraight, TripleStraight = isTripleStraight}
	Func[7]   = { Straight = isStraight }
	Func[8]   = { Straight = isStraight, DoubleStraight = isDoubleStraight}
	Func[9]   = { Straight = isStraight, TripleStraight = isTripleStraight}
	Func[10]  = { Straight = isStraight, DoubleStraight = isDoubleStraight}
	Func[11]  = { Straight = isStraight}
	Func[12]  = { DoubleStraight = isDoubleStraight, TripleStraight = isTripleStraight}
	Func[13]  = {}
	Func[14]  = { DoubleStraight = isDoubleStraight}
	Func[15]  = { TripleStraight = isTripleStraight}
	Func[16]  = { DoubleStraight = isDoubleStraight}
	Func[17]  = {}
	Func[18]  = { DoubleStraight = isDoubleStraight, TripleStraight = isTripleStraight}
	Func[19]  = {}
	Func[20]  = { DoubleStraight = isDoubleStraight}
end	

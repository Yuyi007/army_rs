class('ComputerAI')

local m = ComputerAI
m.cardList = {} --要出的牌
m.curType = CARDTYPE.None
m.curWeight = -1
m.curLength = -1

--智能选牌
function m.smartSelectCards(cards, cardtype, weight, length, isBiggest) --isBiggest是否是最大者
  cardtype = isBiggest and CARDTYPE.None or cardtype
  m.curType = cardtype
  m.curWeight = 0
  m.curLength = 0
  table.clear(m.cardList)
  -- logd(">>>>type555:%s",tostring(cardtype))
  m.selectCardType(cardtype, cards, weight, length)
  -- m.caleCardList()
end

function m.selectCardType(cardtype, cards, weight, length)
  local selectCards = {}
  if cardtype == CARDTYPE.None then
    --随机出牌
    m.cardList = m.findSmallestCards(cards)
  
  elseif cardtype == CARDTYPE.Single then
    m.cardList = m.findSingle(cards, weight)

  elseif cardtype == CARDTYPE.Double then
    m.cardList = m.findDouble(cards, weight)

  elseif cardtype == CARDTYPE.TwoDouble then
    m.cardList = m.findTwoDouble(cards, weight)
 

  elseif cardtype == CARDTYPE.Straight then
    m.cardList = m.findStraight(cards, weight, length)

    if #m.cardList == 0 then  
      m.cardList = m.findBoom(cards, -1)
      if #m.cardList == 0 then
        m.cardList = m.findJokerBoom(cards)
        if #m.cardList > 0 then m.curType =  CARDTYPE.JokerBoom end
      else
        m.curType =  CARDTYPE.Boom
      end  
    else
      m.curType =  CARDTYPE.Straight
    end  

  elseif cardtype == CARDTYPE.DoubleStraight then
    m.cardList = m.findDoubleStraight(cards, weight, length)

    if #m.cardList == 0 then  
      m.cardList = m.findBoom(cards, -1)
      if #m.cardList == 0 then
        m.cardList = m.findJokerBoom(cards)
        if #m.cardList > 0 then m.curType =  CARDTYPE.JokerBoom end
      else
        m.curType =  CARDTYPE.Boom
      end  
    else
      m.curType =  CARDTYPE.DoubleStraight
    end 

  elseif cardtype == CARDTYPE.TripleStraight then
    m.cardList = m.findTripleStraight(cards, weight, length)

    if #m.cardList == 0 then  
      m.cardList = m.findBoom(cards, -1)
      if #m.cardList == 0 then
        m.cardList = m.findJokerBoom(cards)
        if #m.cardList > 0 then m.curType =  CARDTYPE.JokerBoom end
      else
        m.curType =  CARDTYPE.Boom
      end  
    else
      m.curType =  CARDTYPE.TripleStraight
    end 

  elseif cardtype == CARDTYPE.Three then
    m.cardList = m.findThree(cards, weight)

  elseif cardtype == CARDTYPE.ThreeAndOne then
    m.cardList = m.findThreeAndOne(cards, weight)

  elseif cardtype == CARDTYPE.ThreeAndTwo then
    m.cardList = m.findThreeAndTwo(cards, weight)

  elseif cardtype == CARDTYPE.Boom then
    m.cardList = m.findBoom(cards, weight)

    if #m.cardList == 0 then
      m.cardList = m.findJokerBoom(cards)
      m.curType =  CARDTYPE.JokerBoom
    end 

  elseif cardtype == CARDTYPE.JokerBoom then
    
  end
end

--找单牌
function m.findSingle(cards, weight, ti) --ti 是否为三带一
  local selects = {}
  local count = #cards
  for i=1,count do
    if cards[i].weight > weight then
      table.insert(selects, cards[i])
      if not ti then
        m.curWeight = cards[i].weight
        m.curLength = 1
      end  
      break
    end  
  end
  return selects 
end

--找双牌 33
function m.findDouble(cards, weight, ti) --ti 是否为三带二
  local selects = {}
  if #cards < 2 then return selects end
  for i=1,#cards-1 do
    if cards[i].weight == cards[i + 1].weight then
      local totalweight = cards[i].weight + cards[i + 1].weight
      if totalweight > weight then
        table.insert(selects, cards[i])
        table.insert(selects, cards[i+1])
        if not ti then
          m.curWeight = totalweight
          m.curLength = 2
        end  
        break
      end  
    end  
  end
  return selects
end

--找双对 3344 4455
function m.findTwoDouble(cards, weight)
  local selects = {}
  if #cards < 4 then return selects end 
  for i=1,#cards - 3 do
    if cards[i].weight == cards[i + 1].weight and 
       cards[i+2].weight == cards[i+3].weight and
       cards[i+2].weight - cards[i + 1].weight == 1 then
      
      if cards[i+3].weight > WEIGHT.One then return selects end
      
      local totalweight = cards[i].weight * 2 + cards[i+2].weight * 2
      if totalweight > weight then
        table.insert(selects, cards[i])
        table.insert(selects, cards[i+1])
        table.insert(selects, cards[i+2])
        table.insert(selects, cards[i+3])
        m.curWeight = totalweight
        m.curLength = 4
        break
      end  
    end  
  end
  return selects
end

--找顺子
function m.findStraight(cards, weight, length)
  local selects = {}
  local counter = 0
  local indexList = {} --card索引
  if #cards < 5 then return selects end
  -- logd(">>>>>length:%s",tostring(length))
  for i=1,#cards - 4 do
    if cards[i].weight > weight then

      counter = 1
      table.clear(indexList)
      table.insert(indexList, i)
      -- logd(">>>>>st222:%s-%s-%s",tostring(#indexList),tostring(i),tostring(indexList[#indexList]))

      for j = i+1, #cards do
        if cards[j].weight > WEIGHT.One then break end

        if cards[j].weight - cards[i].weight == counter then
          table.insert(indexList, j)
          counter = counter + 1
          -- logd(">>ts000:%s-%s-%s-%s",tostring(cards[i].weight),tostring(cards[j].weight),tostring(i),tostring(j))
          -- logd(">>st111:%s,%s,%s",inspect(indexList),tostring(counter),tostring(length))
        else
          break
        end

        if counter == length then 
          
          break 
        end
      end
    end
    if counter == length then
      -- logd(">>st222:%s,%s",tostring(counter),tostring(length))
      -- table.insert(indexList, 1, i)
      break
    end  
  end

  if counter == length then
    for i=1,#indexList do
      local index = indexList[i]

      table.insert(selects, cards[index])
      -- logd(">>>ts333:%s",tostring(cards[index].weight))
      m.curWeight = m.curWeight + cards[index].weight
    end
    m.curLength = length  
  end  
  return selects
end

--找双顺 556677
function m.findDoubleStraight(cards, weight, length)
  local selects = {}
  local counter = 0
  
  local indexList = {} --card索引
  if #cards < 6 then return selects end
  for i=1,#cards - 5 do
    if cards[i].weight > weight then
      counter = 0
      table.clear(indexList)
      table.insert(indexList, i)
      local temp = 1  --偶数位加counter,奇数为不加counter 

      for j = i+1, #cards do
        if cards[j].weight > WEIGHT.One then break end

        if cards[j].weight - cards[i].weight == counter then          
          temp = temp + 1
          table.insert(indexList, j)
          if temp%2 == 0 then counter = counter + 1 end
          -- logd(">>ds000:%s-%s-%s-%s",tostring(cards[i].weight),tostring(cards[j].weight),tostring(i),tostring(j))
          -- logd(">>ds111:%s,%s,%s",inspect(indexList),tostring(counter),tostring(length))
        else
          break
        end  

        if counter == length/2 then
          
          break 
        end
      end
    end
    if counter == length/2 then 
      -- logd(">>ds222:%s,%s",tostring(counter),tostring(length))
      -- table.insert(indexList, 1, i) 
      break 
    end 
  end

  if counter == length/2 then
    for i=1,#indexList do
      local index = indexList[i]
      table.insert(selects, cards[index])
      -- logd(">>>ds333:%s",tostring(cards[index].weight))
      m.curWeight = m.curWeight + cards[index].weight 
    end
    m.curLength = length  
  end  
  return selects
end

--找飞机 333444
function m.findTripleStraight(cards, weight, length)
  local selects = {}
  local counter = 0
  local indexList = {} --card索引
  if #cards < 6 then return selects end
  for i=1,#cards - 5 do
    if cards[i].weight > weight then
      counter = 0
      table.clear(indexList)
      table.insert(indexList, i)
      local temp = 1  --偶数位加counter,奇数为不加counter 

      for j = i+1, #cards do
        if cards[j].weight > WEIGHT.One then break end

        if cards[j].weight - cards[i].weight == counter then     
          temp = temp + 1
          -- 
          table.insert(indexList, j)
          if temp%3 == 0 then counter = counter + 1 end
          -- logd(">>ts000:%s-%s-%s-%s",tostring(cards[i].weight),tostring(cards[j].weight),tostring(i),tostring(j))
          -- logd(">>ts111:%s,%s,%s",inspect(indexList),tostring(counter),tostring(length))
        else
          break 
        end

        if counter == length/3 then break end
      end
    end
    if counter == length/3 then 
      -- logd(">>ts222:%s,%s",tostring(counter),tostring(length))
      -- table.insert(indexList, 1, i) 
      break 
    end 
  end

  if counter == length/3 then
    for i=1,#indexList do
      local index = indexList[i]

      table.insert(selects, cards[index])
      -- logd(">>>ts333:%s",tostring(cards[index].weight))
      m.curWeight = m.curWeight + cards[index].weight 
    end
    m.curLength = length  
  end  
  return selects
end

--找三不带
function m.findThree(cards, weight, ti)
  local selects = {}
  if #cards < 3 then return selects end
  for i=1,#cards - 2 do
    if cards[i].weight == cards[i + 1].weight and cards[i].weight == cards[i + 2].weight then
      local totalweight = cards[i].weight * 3
      if totalweight > weight then
        table.insert(selects, cards[i])
        table.insert(selects, cards[i+1])
        table.insert(selects, cards[i+2])
        if not ti then 
          m.curWeight = totalweight
          m.curLength = 3
        end  
        break
      end
    end  
  end
  return selects
end

--找三带二
function m.findThreeAndTwo(cards, weight)
  local selects = {}
  local newcards = {}

  for i = 1, #cards do
    newcards[i] = cards[i]
  end
    
  local three = m.findThree(cards, weight, true)
  if #three > 0 then
    for i=1,#three do
      table.removeVal(newcards, three[i])
      table.insert(selects, three[i])
      m.curWeight = m.curWeight + three[i].weight
    end
    local two = m.findDouble(newcards, weight, true)
    if #two > 0 then
      for i = 1,#two do
        table.insert(selects, two[i])
      end
      m.curLength = 5
    else
      m.curWeight = 0
      m.curLength = 0
      table.clear(selects)
    end   
  end
  
  return selects
end

--找三带一
function m.findThreeAndOne(cards, weight)
  local selects = {}
  local newcards = {}

  for i = 1, #cards do
    newcards[i] = cards[i]
  end
    
  local three = m.findThree(cards, weight, true)
  if #three > 0 then
    for i=1,#three do
      table.removeVal(newcards, three[i])
      table.insert(selects, three[i])
      m.curWeight = m.curWeight + three[i].weight
    end

    local one = m.findSingle(newcards, weight, true)
    if #one > 0 then
      for i = 1,#one do
        table.insert(selects, one[i])
      end 
      m.curLength = 4 
    else
      m.curWeight = 0
      m.curLength = 0
      table.clear(selects)
    end 

  end
  return selects
end

--寻找炸弹
function m.findBoom(cards, weight)
  local selects = {}
  if #cards < 4 then return selects end
  for i=1,#cards - 4 do
    if cards[i].weight == cards[i + 1].weight and 
       cards[i].weight == cards[i + 2].weight and
       cards[i].weight == cards[i + 3].weight then
      
      local totalweight = cards[i].weight * 4
      if totalweight > weight then
        table.insert(selects, cards[i])
        table.insert(selects, cards[i + 1])
        table.insert(selects, cards[i + 2])
        table.insert(selects, cards[i + 3])
        m.curWeight = totalweight
        m.curLength = 4
        break
      end  
    end  
  end
  return selects
end

--寻找王炸
function m.findJokerBoom(cards)
  local selects = {}
  if #cards ~= 2 then return selects end
  for i=1,#cards-1 do
    if cards[i].weight == WEIGHT.SJoker and
       cards[i].weight == WEIGHT.LJoker then
        table.insert(selects, cards[i])
        table.insert(selects, cards[i+1])
        m.curWeight = 99
        m.curLength = 2
        break 
    end  
  end
  return selects
end

function m.findSmallestCards(cards)
  local selects = {}
  
  --找飞机
  for i = 18, 6, -3 do
    selects = m.findTripleStraight(cards, -1, i)
    if #selects ~= 0 then
      m.curType = CARDTYPE.TripleStraight
      break
    end
  end
  
  --找双顺
  if #selects == 0 then
    for i = 20, 6, -2 do
      selects = m.findDoubleStraight(cards, -1, i)
      if #selects ~= 0 then
        m.curType = CARDTYPE.DoubleStraight
        break
      end  
    end
  end   

  --先出顺
  if #selects == 0 then
    for i = 12, 5, -1 do
      selects = m.findStraight(cards, -1, i)
      if #selects ~= 0 then
        m.curType = CARDTYPE.Straight
        break
      end  
    end
  end  
  
  --三带二 3 * 3 = 9  3 * Two = 45
  if #selects == 0 then
    for i = 9, 45, 3 do
      selects = m.findThreeAndTwo(cards, i-1)
      if #selects ~= 0 then
        m.curType = CARDTYPE.ThreeAndTwo
        break
      end 
    end 
  end 
  
  --三带一
  if #selects == 0 then
    for i = 9, 45, 3 do
      selects = m.findThreeAndOne(cards, i-1)
      if #selects ~= 0 then
        m.curType = CARDTYPE.ThreeAndOne
        break
      end 
    end 
  end
  
  --三不带
  if #selects == 0 then
    for i = 9, 45, 3 do
      selects = m.findThree(cards, i-1)
      if #selects ~= 0 then
        m.curType = CARDTYPE.Three
        break
      end 
    end 
  end
  
  --找双对
  if #selects == 0 then
    for i = 6, 30, 2 do
      selects = m.findTwoDouble(cards, i-1)
      if #selects ~= 0 then
        m.curType = CARDTYPE.TwoDouble
        break
      end 
    end 
  end

  --找双 2 * 3 = 6  2 * Two = 30
  if #selects == 0 then
    for i = 6, 30, 2 do
      selects = m.findDouble(cards, i-1)
      if #selects ~= 0 then
        m.curType = CARDTYPE.Double
        break
      end 
    end 
  end
  
  
  
  --找单
  if #selects == 0 then
    selects = m.findSingle(cards, -1)
    m.curType = CARDTYPE.Single
  end


  return selects

end

function m.caleIsQdZ(cards)
  local isfind =  m.findJokerBoom(cards)

  if #isfind ~= 0 then return true end
  isfind = m.findBoom(cards, -1)
  if #isfind ~= 0 then return true end

  for i = 18, 6, -3 do
    isfind = m.findTripleStraight(cards, -1, i)
    if #isfind ~= 0 then return true end  
  end
  
  isfind =  m.findThree(cards, 39)
  if #isfind ~= 0 then return true end
  
  isfind = m.findDouble(cards, 28)
  if #isfind ~= 0 then
    local ti = m.findSingle(cards, 15)
    if #ti ~= 0 then return true end
  end
  
  return false
end

function m.caleCardList()
  for i,card in pairs(m.cardList) do
    logd(">>>>>>[card%s]:%s",tostring(i),tostring(card.weight))
  end
  logd(">>>>>>>cardType:%s",tostring(m.curType))  
end




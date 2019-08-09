class("TreasureUtil")

local m = TreasureUtil

function m.showTreasure(gNum, dNum, cNum)
  if gNum then gNum:setString(md:curInstance().coins) end

  if dNum then dNum:setString(md:curInstance().fragments) end

  if cNum then cNum:setString(md.chief.credits) end
end
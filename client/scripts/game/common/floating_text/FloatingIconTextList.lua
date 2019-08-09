class('FloatingIconTextList', function(self)
  self.messages = {}
  self.index = 1
end)

local m = FloatingIconTextList

local mInstance = nil

function FloatingIconTextList.instance()
  if mInstance == nil then
    mInstance = FloatingIconTextList.new()
    ui:signal("leave_main_scene"):add(function()
      if mInstance then
        mInstance:stop()
      end
    end)
  end
  return  mInstance
end

function FloatingIconTextList.setInstance(inst)
  mInstance = inst
end

function m:addMessage(message, onComplete, bonusId, bonusCount)
  local grade = cfg:getType(bonusId).grade
  table.insert(self.messages, {message = message, onComplete = onComplete, bonusId = bonusId, bonusCount = bonusCount, grade = grade})
  self:show()
end

function m:addBonusMessages(bonuses, onComplete)
  -- logd("add bonsu messages: %s, %s, %s, %s", table.getn(bonuses), table.getn(self.messages), self.index, inspect(bonuses))
  local count = #bonuses
  for i = 1, #bonuses do local bonus = bonuses[i]
    local onCom = nil
    if i == count then
      -- onCom = function()
      --   self:show()
      -- end
    -- else
      onCom = onComplete
    end
    local grade = cfg:getType(bonus.bonusId).grade
    table.insert(self.messages, {message = loc("str_redeem_bonus_desc", Util.getNameText(bonus.bonusId), bonus.bonusCount), onComplete = onCom, bonusId = bonus.bonusId, bonusCount = bonus.bonusCount, grade = grade})
  end
  self:show()
end


function m:addBonusMessage(bonusId, bonusCount, onComplete)
  local grade = cfg:getType(bonusId).grade
  table.insert(self.messages, {message = loc("str_redeem_bonus_desc", Util.getNameText(bonusId), bonusCount), onComplete = onComplete, bonusId = bonusId, bonusCount = bonusCount, grade = grade})
  -- logd("add bonsu message: %s, %s, %s, %s", bonusId, bonusCount, table.getn(self.messages), self.index)
  self:show()
end

function m:addFriendshipMessage(npcId, frienship, onComplete)
  local npcType = cfg.npcs[npcId]
  local color,str_friendship = "", ""
  if frienship > 0 then
    str_friendship = "+"..frienship
    color = "green"
  else
    str_friendship = frienship
    color = "red"
  end
  local message = ColorUtil.getColorString(loc("str_friendship_up_down_desc", npcType.name, str_friendship), color)
  table.insert(self.messages, {message = message, onComplete = onComplete, iconPath = "images/icons/npc", iconName = npcType.icon})
  self:show()
end

function m:addFriendshipSpecAttrMessage(npctid, attrInfo, onComplete)
  local npcType = cfg.npcs[npctid]
  local color,attrName, npcName = "green", loc('str_' .. attrInfo.name), npcType.name
  attrName = ColorUtil.getColorString(attrName, color)
  local message = loc("str_npc_fsh_spec_attr_tip", npcName, attrName)
  table.insert(self.messages, {message = message, onComplete = onComplete, iconPath = "images/icons/npc", iconName = npcType.icon})
  self:show()
end

-- function m:showChain()
--   if self.index <= table.getn(self.messages) then
--     FloatingTextFactory.makeIcon({onComplete = self.messages[self.index].onComplete,
--                           text = self.messages[self.index].message,
--                           iconPath = self.messages[self.index].iconPath,
--                           iconName = self.messages[self.index].iconName,
--                           bonusId = self.messages[self.index].bonusId,
--                           bonusCount = self.messages[self.index].bonusCount,
--                           grade = self.messages[self.index].grade
--                           })
--     self.index = self.index + 1
--   end
-- end

function m:show()
  if self.questHandler ~= nil then return end
  local fun = function()
    -- logd("update FloatingTextFactory: %s, %s", self.index, table.getn(self.messages))
    if self.index > table.getn(self.messages) then
      self:stop()
    else
      FloatingTextFactory.makeIcon({onComplete = self.messages[self.index].onComplete,
                            text = self.messages[self.index].message,
                            iconPath = self.messages[self.index].iconPath,
                            iconName = self.messages[self.index].iconName,
                            bonusId = self.messages[self.index].bonusId,
                            bonusCount = self.messages[self.index].bonusCount,
                            grade = self.messages[self.index].grade
                            })
      self.index = self.index + 1
    end
  end
  self.questHandler = scheduler.schedule(fun, 0.6)
  fun()
end

function m:stop()
  -- logd("stop FloatingIconTextList 111")
  scheduler.unschedule(self.questHandler)
  self.questHandler = nil
  self.messages = {}
  self.index = 1
end
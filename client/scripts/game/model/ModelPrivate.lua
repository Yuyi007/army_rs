-- ModelPrivate.lua
-- NOTE: These following methods should only be called from ModelRpc methods
--       DO NOT call these from other contexts, instead, use ModelRpc to wrap them

function Model:updateLoginCommon(data, msg)
  if msg.success and msg.success ~= cjson.null then
    md.loggedIn = true
    md.is_gm = not not msg.is_gm
    md.allow_full_controller = nil
    -- md.allow_full_controller = not not msg.allow_full_controller
    md.disable_chongzhi = not not msg.disable_chongzhi

    mp:kcpFinish()

    if msg.sid and msg.udp_key and msg.udp_port then
      mp:initKcp(msg.sid, msg.udp_key, msg.udp_port)
    end

    if data.id == self.account.defaultId then
      self.account:setLastLoginZone(self.account.defaultId, data.zone)
    else
      self.account.id = msg.id
      self.account.email = data.email or self.account.email
      self.account:setLastLoginZone(self.account.id, data.zone)
    end
    self.account:saveDefaults()
    self.account.connected = true
  end

  self:updateNonce(msg)
  self:processAfterGetOpenZones(msg)
end

function Model:updateNonce(msg)
  logd("<>>>>msg.nonce:%s", tostring(msg.nonce))
  if msg.nonce then
    -- logd("setting session nonce to %s", peek(msg.nonce))
    local nonce = string.pack('b' .. #msg.nonce, unpack(msg.nonce))
    -- local biNonce = string.pack('b' .. #msg.bi_nonce, unpack(msg.bi_nonce))
    mp.codecState.nonce = nonce
  end
end

function Model:applyGetGameDataResult(msg)
  -- we must selectively update the model from the data, because some of the key are conflicting
  -- with the methods we have in the model. evepoe
  if msg.instances then
    self.instances = msg.instances
  end
  
  if msg.person then
    self.person = msg.person
  end  
  self.total_paid = tonumber(msg.total_paid) or 0

  if msg.chief then
    self.chief = msg.chief
  end

  if msg.mailCount then
    self.mailCount = msg.mailCount
  end

  self.deny_talk = msg.deny_talk
end


function Model:updateChief(chief)
  for k, v in pairs(chief) do
    self.chief[k] = v
  end
end


function Model:preProcMsg(msg)
  if not msg then return end
  self:handleBonuses(msg)
  self:updateMails(msg)
end

function Model:handleBonuses(msg)
  if not msg.bonuses then return end
  -- logd(">>>>>>>>>statistics bonus %s", inspect(msg.bonuses))

  each(function(bonus)
      local tid = bonus["tid"]
      if tid:match("^ite") then
        self:updateItemChange(bonus)
      elseif tid:match("^avatar") then
        
      elseif tid:match("^deco") then

      elseif tid:match("^paint") then

      end
    end, msg.bonuses)
end

function Model:updateItemChange(item)
  local tid = item["tid"]
  if not tid then  loge("Bonus item doesn't contain tid!!!") end

  local t = cfg.items[tid]
  if not t then loge("Bonus item config doesn't exist!!!") end

  if t.func_cat == "currency" then
    local addAttr = t["add_attr"]
    if addAttr == 'credits' then
      self.chief.credits = self.chief.credits + item.count
    elseif addAttr == "coins" then
      local instance = self:instance()
      instance.coins = instance.coins + item.count
    elseif addAttr == "fragments" then
      local instance = self:instance()
      instance.fragments = instance.fragments + item.count
    elseif addAttr == "exp" then
      local instance = self:instance()
      instance.exp = instance.exp + item.count
      if item["level"] then
        instance.level = item["level"]
      end
      if item["cur"] then
        instance.exp = item["cur"]
      end
    else
      loge("Not support currency:%s", tostring(addAttr))
    end
  else
    local items = self:items()
    local it = items[item.tid]
    if it then
      it.count = item.count
      if it.count <= 0 then
        items[item.tid] = nil
      end
    else
      items[item.tid] = item
    end
  end
end


function Model:setMails(msg)
  if msg.success == false then return end
  if msg.mails then
    if self:hasInstance() then
       self.mails = msg.mails
    end
  end
end

function Model:removeMails(id)
  for type, t in pairs(self.mails) do
    for key, value in pairs(t) do
	    if value.id == id then
	    	table.remove(t, key)
	      return
	    end
	  end
  end
end

function Model:handleMails(listOrId)
	if self:hasInstance() then
		if type(listOrId) == 'table' then
	    for key, value in pairs(listOrId) do
	    	self:removeMails(value.mail_id)
	    end
		elseif type(listOrId) == 'number' then
	    self:removeMails(listOrId)
		end
  end
end

function Model:handleMailsReadInfo(msg)
  if msg.success == false then return end
  if self:hasInstance() then
    self.readInfos = nil
    self.readInfos = msg.read_infos

    local num = 0
    for type, t in pairs(msg.read_infos) do
	    for key, value in pairs(t) do
		    if value == "1" then
		      num = num + 1
		    end
		  end
	  end
	  self.unReadMailNum = num
  end
end

function Model:handleMailsRedeemInfo(msg)
  if msg.success == false then return end
  if self:hasInstance() then
     self.redeemInfos = nil
     self.redeemInfos = msg.redeem_infos
  end
end

function Model:updateMails(msg)
  if msg.all_mails then
    self.unReadMailNum = 0
    for _, mail in pairs(msg.all_mails) do
      if mail.is_open == false then
        self.unReadMailNum = self.unReadMailNum + 1
      end
    end
  end
end

function Model:handleItems(msg)
	local items = self:items()
	if msg.item then
	  local it = items[msg.item.tid]
	  if it then
      if msg.item.count >= 0 then
	      it.count = msg.item.count
        if it.count == 0 then items[msg.item.tid] = nil end
      else
        items[msg.item.tid].expired = true
	    end
	  end
	end

  if msg.expired_items then
    for key, value in pairs(msg.expired_items) do
      items[key].expired = true
    end
  end

  if msg.new_items then
    for key, value in pairs(msg.new_items) do
      items[key].newGet = true
    end
  end

  self:addGain(msg)

  if msg.gift and type(msg.gift) == 'table' then
    for key, value in pairs(msg.gift.detail) do
    	local itemID = value.tid
      self:setAvatarData(itemID, value)
      if itemID:match('^car') then
      	local profile = cfg.heroes[itemID]
        local bt = profile.body_id
        local wt = profile.wheel_id
        local tt = profile.tail_id
        self:setAvatarData(bt, value)
        self:setAvatarData(wt, value)
        self:setAvatarData(tt, value)

        if msg.gift.equipped_data then
          local equippedData = self:curInstance().avatar_data.equipped_data
          equippedData[itemID] = msg.gift.equipped_data
        end
      end
    end
  end
end

function Model:setAvatarData(id, value)
	if not id or id == '' then return end
  local avatarData = self:curInstance().avatar_data.bag
	avatarData[id] = {}
	avatarData[id].count = value.count
  avatarData[id].end_time = value.end_time
  avatarData[id].tid = id
end

function Model:updateExpiredItems(msg)
	local items = self:items()
	if msg.items then
	  for key, value in pairs(msg.items) do
      items[key] = nil
    end
	end

	self:addGain(msg)
end

function Model:addGain(msg)
	if msg.gain then
    for key, value in pairs(msg.gain) do
    	if value.tid == '' then return end
    	local addAttr = cfg.items[value.tid].add_attr
      if addAttr == 'credits' then
	      self.chief.credits = self.chief.credits + value.count
	    elseif addAttr == "coins" then
	      local instance = self:instance()
	      instance.coins = instance.coins + value.count
	    elseif addAttr == "fragments" then
	      local instance = self:instance()
	      instance.fragments = instance.fragments + value.count
	    end
    end
  end
end
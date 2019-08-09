class('ChatMessageDecorator')

local m = ChatMessageDecorator

function m.decorate(o)
  local mt = getmetatable(o) or {}
  mt.__index = m.funcs()
  setmetatable(o, mt)
  return o
end

function m.funcs()
  local mt = {}

  function mt.expired(self)
    self.content.end_time = self.content.end_time or 0
    if self.content.end_time == 0 then return false end
    if self.content.status == 'expired' then return true end
    return ServerTime.time() >= self.content.end_time and self.content.status == 'waiting'
  end

  function mt.isGift(self)
    return self.content.type == 'gift'
  end

  function mt.giftRedeemed(self)
    return op.truth(self.content.redeemed)
  end

  function mt.canRedeemGift(self)
    if self:isFromMe() then return false end
    if self:giftRedeemed() then return false end
    if self:endTime() == 0 then return true end
    return self:endTime() > ServerTime.time()
  end

  function mt.isWanted(self)
    if self:isFromMe() then return false end
    if self.content.type ~= 'wanted' then return false end
    if self.content.the_end then return false end
    if self.content.be_use and self.content.be_use == true then return false end
    return self:endTime() > ServerTime.time()
  end


  function mt.isGoto(self)
    if self:isFromMe() then return false end
    return self.content.help_type and self.content.help_type ~= "nothing" or false
  end

  function mt.isFriendRequest(self)
    if self:isFromMe() then return false end
    return self.content.friend_request and true or false
  end

  function mt.endTime(self)
    return self.content.end_time or 0
  end

  function mt.isQuestion(self)
    if self:isFromMe() then return false end
    if self.content.type ~= 'question' then return false end
    if self.content.the_end then return false end
    return self:endTime() > ServerTime.time()
  end

  function mt.shouldShowEffectText(self)
    if self:isFromMe() then return false end
    if self:isGift() then return true end
    if self.content.type == 'wanted' and self.content.be_use == true then return false end
    return self:endTime() ~= 0
    --  then return false end
    -- return self.content.status ~= 'none'
  end


  function mt.isFromMe(self)
    return self.pid == md:pid()
  end

  function mt.isFromNpc(self)
    return self.pid:match('^npc')
  end

  function mt.needsReply(self)
    if not self:isFromNpc() then return false end
    if self:endTime() == 0  then return false end
    if self:expired()       then return false end
    if self:isWanted()      then return false end
    if self:isQuestion()    then return false end
    if self.content.the_end then return false end
    return true
  end

  return mt
end


setmetatable(m, {__call = function(t, ...) return m.decorate(...) end })


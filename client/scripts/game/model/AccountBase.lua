-- AccountBase.lua

class('AccountBase', function(self)
  self:clear()
  self.connected = false
end)

local m = AccountBase

function m:init()
  self:loadDefaults()
end

function m:clear()
  self.defaultId = 0
  self.defaultEmail = ''
  self.defaultPass = ''

  self.id = 0
  self.pass = ''
  self.email = ''
  self.zone = nil
  self.zoneName=''

  self.guestId = 0
  self.platform = 0
  self.loginFail = 0
  self.msgNum = 0 
  self.timer = 0
  self.day =0
end

function m:loadDefaults()
  logd('Account: loadDefaults'..debug.traceback())

  self.defaultId = unity.getInt('account.defaultId')
  self.defaultEmail = unity.getString('account.defaultEmail')
  self.defaultPass = unity.getString('account.defaultPass')
  self.id = unity.getInt('account.id')
  self.pass = unity.getString('account.pass')
  self.email = unity.getString('account.email')
  self.nickName = unity.getString('account.nickName')
  self.zone = unity.getInt('account.zone')
  self.guestId = unity.getInt('account.guestId')
  self.platform = unity.getInt('account.platform')
  self.loginFail = unity.getInt('account.loginFail')
  self.msgNum = unity.getInt('account.msgNum')
  self.timer = unity.getInt('account.timer')
  self.day = unity.getInt('account.day')
  self.zoneName = unity.getString('account.zoneName')
  self:dump()
  -- self:updateCurrentZone()

  -- if self.zone == nil or self.zone < 1 then
  --   logd('Account: zone=%s set to 1', tostring(self.zone))
  --   self.zone = 1
  -- end
end

function m:saveDefaults()
  logd('Account: saveDefaults')

  unity.setInt('account.defaultId', self.defaultId)
  unity.setString('account.defaultEmail', self.defaultEmail)
  unity.setString('account.defaultPass', self.defaultPass)
  unity.setInt('account.id', self.id)
  unity.setString('account.pass', self.pass)
  unity.setString('account.email', self.email)
  unity.setString('account.nickName', self.nickName)
  unity.setInt('account.zone', self.zone or 0)
  unity.setInt('account.guestId', self.guestId)
  unity.setInt('account.platform', self.platform)
  unity.setInt('account.loginFail', self.loginFail)
  unity.setInt('account.msgNum', self.msgNum)
  unity.setInt('account.timer', self.timer)
  unity.setInt('account.day', self.day)
  unity.setString('account.zoneName',self.zoneName)
  -- self:updateCurrentZone()
end

--[[
function m:updateCurrentZone()
  if self:hasAccount() then
    self.zone = self:lastZones(self.id)
  elseif self:hasDefaultAccount() then
    self.zone = self:lastZones(self.defaultId)
  else
    self.zone = table.getn(cfg.zones)
  end

  if self.zone < 1 or self.zone > table.getn(cfg.zones) then
    self.zone = table.getn(cfg.zones)
  end
end
]]

function m:dump() -- for debug
  logd('Account: defaultId=' .. self.defaultId ..
    ' defaultEmail=' .. self.defaultEmail ..
    ' defaultPass=' .. self.defaultPass ..
    ' id=' .. self.id ..
    ' nickName=' .. self.nickName ..
    ' email=' .. tostring(self.email) ..
    ' pass=' .. tostring(self.pass) ..
    ' zone=' .. tostring(self.zone))
end

function m:hasDefaultAccount()
  return self.defaultId > 0 and string.len(self.defaultPass) > 0
end

function m:defaultAccountHasEmail()
  return string.len(self.defaultEmail) > 0
end

function m:hasAccount()
  return self.email and self.pass and string.len(self.email) > 0 and string.len(self.pass) > 0
end

function m:lastZones(id)
  if id then
    local zone1 = unity.getInt('lastZone1_' .. id)
    local zone2 = unity.getInt('lastZone2_' .. id)
    return zone1, zone2
  else
    return 0, 0
  end
end

function m:setLastLoginZone(id, zone)
  local zone1 = unity.getInt('lastZone1_' .. id)
  local zone2 = unity.getInt('lastZone2_' .. id)
  if zone1 ~= zone then
    unity.setInt('lastZone1_' .. id, zone)
    unity.setInt('lastZone2_' .. id, zone1)
  end
end

function m:passToDisplay()
  if string.len(self.pass) > 0 then
    return '********'
  else
    return ''
  end
end

function m:isFacebookAvailable()
  return false
end

-- 'static' methods

function m.hashPass(pass)
  return string.sub(sha256.sum('darE'..'yOu'..pass..'pEEk'):tohex(), 1, 32)
end

function m.validateEmail(email)
  if email then
    local len = string.len(email)
    local i = string.find(email, '@')
    local j = string.find(email, '.', i)
    return i and j and len and i > 1 and i < len and j > 1 and j < len
  else
    return false
  end
end

function m.validatePass(pass)
  if pass then
    local len = string.len(pass)
    return len >= 6 and len <= 12
  else
    return false
  end
end


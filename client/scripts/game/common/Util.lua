declare_module('Util')

Util.sizeBigTitle = 24
Util.sizeTitle = 20
Util.sizeContent = 18

local abs = math.abs
local MovUtil = Game.MovUtil
local Time = Time
local Application = Application
local OsCommon = OsCommon
local NotReachable = SystemStatusUtil.NetworkReachability.NotReachable


CHANNEL_BIT={
  world  = bit.lshift(1,0),
  now    = bit.lshift(1,1),
  team   = bit.lshift(1,2),
  system = bit.lshift(1,4),
  other  = bit.lshift(1,4),  -- 和 系统消息归为一个开关 其余的逻辑走独自的
}


CURRENCY_TO_TID={
  coins   = 'ite8000001',
  money   = 'ite8000002',
  credits = 'ite8000003',
  exp     = 'ite8000004',
}

CURRENCIES={
  'coins',
  'fragments',
  'credits',
}

CURRENCIES_INDEX={
  coins   = 1,
  fragments   = 2,
  credits = 3,
}


-- TODO: remove the folowing two param, get icon from config
CURRENCY_ICON_LIST={
  coins        = "icnui029",
  fragments        = "icnui030",
  credits      = "icnui031",
  exp          = "icnui063",
}


ELEMENT_TYPE = {"random", "ap", "ew"}

function getElementType(index)
  return ELEMENT_TYPE[index]
end

function getChannelBit(channelName)
  local list = string.split(channelName, "_", 1)
  local cid = list[1]
  return CHANNEL_BIT[cid]
end

function setCurrencyIcon(t, icn)
  local itemType = cfg:getType(t)
  if itemType then
    if itemType.currency_icon then
      icn:setSprite(itemType.currency_icon)
    elseif itemType.category == 'currency' and cfg.currency_icons[itemType.addattr] then
      icn:setSprite(cfg.currency_icons[itemType.addattr])
    end
  else
    -- in fact this condition should never run if designer make the config correct.
    if cfg.currency_icons[t] then
      icn:setSprite(cfg.currency_icons[t])
    end
  end
  icn:setNativeSize()
end


function getCurrencyText(attr, value)
  if cfg.currency_icons[attr] then
    local str = string.format("<quad path=images/ui/symbol name=%s size=30/> %s", cfg.currency_icons[attr], tostring(value))
    return str
  else
    return attr .. ' ' ..tostring(value)
  end
end

function setPing(text)
  if not text then return end
  local ping = mp:getAverageRTT()
  local color = nil
  if ping >= 100 then
    color = ColorUtil.red_str
  elseif ping >= 60 and ping < 100 then
    color = ColorUtil.yellow_str
  else
    color = ColorUtil.green_str
  end
  text:setString(loc.color(color, loc('str_ping', ping)))
end

function updateNetStatus(wifi, wifiSignals, mobileNetwork)
  local hasWifi = OsCommon.isLocalWifiAvailable()
  local lv = nil
  if hasWifi then
    wifi:setVisible(true)
    mobileNetwork:setVisible(false)
    if Application:get_internetReachability() == NotReachable then
      lv = 1
    else
      lv = 3
    end
    for i = 1, 3 do
      if lv >= i then
        wifiSignals[i]:setColor(ColorUtil.white)
      else
        wifiSignals[i]:setColor(ColorUtil.gray)
      end
    end
  else
    wifi:setVisible(false)
    mobileNetwork:setVisible(true)
  end
end

function setIcon2(id, mc, npcborder)
  mc:setVisible(id ~= nil)
  mc.transform:set_localScale(Vector3(1.0, 1.0, 1.0))
  if npcborder then npcborder:setVisible(false) end
  if not id then return end

  local tid = getTidById(id)
  if tid:match('^ite') or tid:match('^pro') then
    local itemType = cfg.items[tid]
    if itemType.addattr == 'friendship' then
      NpcUtil.setIcon(itemType.icon, mc)
      if npcborder then npcborder:setVisible(true) end
      mc.transform:set_localScale(Vector3(1.3, 1.2, 1.0))
    else
      Util.setIcon(tid, mc)
    end
  else
    Util.setIcon(id, mc)
  end
end

function setIcon(id, mc)
  unity.beginSample('setIcon')

  mc:setVisible(id ~= nil)
  if not id then
    unity.endSample()
    return
  end

  if true then
    -- logd(">>>>>>>id:%s",tostring(id))
  	mc:setSprite(cfg.expression[id].icon_res)
  	return
  end

  local tid = getTidById(id)
  if tid:match('^ite') or tid:match('^pro') then
    ItemUtil.setIcon(tid, mc)
  elseif tid:match('^ski') then
    SkillUtil.setIcon(tid, mc)
  elseif tid:match("^func") then
    local funType = cfg.functions[tid]
    if funType and funType.icon then
      mc:setSprite(funType.icon)
    end
  elseif cfg.currency_icons[id] then
    mc:setSprite(cfg.currency_icons[id])
  elseif id:match('^flag') then
    local config = cfg.guild_banners[id]
    mc:setSpriteAsync(config.icon)
  elseif tid:match('^icon_show') then
    mc:setSprite(tid)
  else
    -- logd(">>>>>>>debug.traceback()"..debug.traceback())
    loge("Util.setIcon not exist:"..tostring(id))
  end

  unity.endSample()
end

function setReviveCoinIcon(mc)
  mc:setSprite("icnui005")
end

function setCombatItemIcon(id, mc)
  mc:setVisible(id ~= nil)
  if not id then return end
  local tid = getTidById(id)
  if tid:match('^ite') or tid:match('^pro') then
    ItemUtil.setCombatItemIcon(tid, mc)
  elseif tid:match('^ski') then
    SkillUtil.setCombatItemIcon(tid, mc)
  end
end

function setCamProperty(camera, key, data)
  local cams = camera.gameObject:GetComponentsInChildren(UnityEngine.Camera, true)
  for k = 1, #cams do local v = cams[k]
    v[key] = data
  end
end

function currencyToTid(c)
  return CURRENCY_TO_TID[c]
end

function tidToCurrency(tid)
  return cfg.items[tid]["add_attr"]
end


function currencySortFunc(lhs, rhs)
  if lhs:match('^ite') then
    lhs = tidToCurrency(lhs)
  end
  if rhs:match('^ite') then
    rhs = tidToCurrency(rhs)
  end
  return CURRENCIES_INDEX[lhs] < CURRENCIES_INDEX[rhs]
end

function currencyNum(c)
  -- logd("check c:"..tostring(c)..","..tostring(cfg.items[c]))
  -- if TID_TO_CURRENCY[c] then
  --   c = TID_TO_CURRENCY[c]
  -- end
  if  c:match('^ite') then
    local item = cfg.items[c]

    if item and item.category == "currency" then
      c = item.addattr
    end
  end
  -- c is just a string: an item id or the following speicial string
  if c == 'coins' then
    return md:curInstance().coins
  elseif c == 'money' then
    return md:curInstance().money
  elseif c == 'credits' then
    return md:curInstance().credits
  elseif c == 'exp' then
    return md:curInstance().hero.exp
  elseif c:match('^ite') then
    -- return user item num
    return md:itemCount(c)
  else
    return 0
  end
end



function getTidById(id)
  if id and id:match('^i_') then
    return id:split('_')[3]
  else
    return id
  end
end

function getNpcTid(pid)
  if pid:match('^npc') == nil then
    loge("getNpcTid---> pid is not a npc pid:"..tostring(pid))
  end
  local parts = string.split(pid, '_')
  return parts[1]
end

function getSignedValueString(val)
  if val >= 0 then
    return '+' .. tostring(val)
  else
    return tostring(val)
  end
end

function getNameText(id, num, note)
  local tid = getTidById(id)
  if tid:match('^ite') or tid:match('^pro') then
    return ItemUtil.getNameText(tid, num, note)
  elseif tid:match('^eqp') then
    return EquipmentUtil.getNameText(id, num, note)
  elseif tid:match('^bbe') then
    return GarmentUtil.getNameText(id, num, note)
  end
end

function getClearName(id, num)
  local tid = getTidById(id)
  if tid:match('^ite') or tid:match('^pro') then
    return ItemUtil.getClearName(tid, num)
  elseif tid:match('^eqp') then
    return EquipmentUtil.getClearName(id, num)
  elseif tid:match('^bbe') then
    return GarmentUtil.getClearName(id, num)
  else
    return id
  end
end

function setName(id, txt)
  local tid = getTidById(id)
  if tid:match('^ite') or tid:match('^pro') then
    ItemUtil.setName(tid, txt)
  elseif tid:match('^ski') then
    SkillUtil.setName(tid, txt)
  elseif tid:match("^eqp") then
    -- use id instead of tid deliberately
    EquipmentUtil.setName(id, txt)
  elseif tid:match('^bbe') then
    GarmentUtil.setName(tid, txt)
  end
end


function setCondition(id, txtLv, txtTask)
  local tid = getTidById(id)
  if tid:match('^ite') or tid:match('^pro') then
    ItemUtil.setCondition(tid, txtLv, txtTask)
  elseif tid:match('^ski') then
    SkillUtil.setCondition(tid, txtLv, txtTask)
  end
end


local strArr = {}
function strElem(color, size, content)
  table.clear(strArr)
  if color then
    strArr[#strArr + 1] = string.format('<color=%s>', color)
  end

  if size then
    strArr[#strArr + 1] = string.format('<size=%s>', size)
  end

  strArr[#strArr + 1] = content

  if size then
    strArr[#strArr + 1] = '</size>'
  end

  if color then
    strArr[#strArr + 1] = '</color>'
  end

  local strRes = table.concat(strArr, '')
  table.clear(strArr)

  return strRes
end

function strUnderLine(str)
  return string.format('[u]%s[/u]', str)
end

function getBagEmptySlotCount(containerType)
  local count = 0
  if containerType == nil then
    containerType = "property"
  end
  for i,v in ipairs(md:curInstance().bag.containers[containerType].slots) do
    if v.id == "" or v.count == 0 then
      count = count + 1
    end
  end
  return count
end

function isBagFull(containerType)
  if containerType == nil then
    containerType = "property"
  end
  for i,v in ipairs(md:curInstance().bag.containers[containerType].slots) do
    if v.id == "" or v.count == 0 then
      return false
    end
  end
  return true
end

function fixStringWidth(txt, mc)
  local rectSize = mc.gameObject:getComponent(RectTransform):get_sizeDelta()
  local sizeDelta = Vector2(txt:GetComponent(UI.Text):get_preferredWidth() + 15, rectSize[2])
  mc.gameObject:getComponent(RectTransform):set_sizeDelta(sizeDelta)
  txt.gameObject:getComponent(RectTransform):set_sizeDelta(sizeDelta)
end


function hashElemCount(hash)
  local count = 0
  for k, v in pairs(hash) do
    if v then count = count + 1 end
  end
  return count
end

function isHashEmpty(hash)
  for k, v in pairs(hash) do
    if v then
      return false
    end
  end
  return true
end


function isEquip(id)
  if id:match('^i_eqp') then
    return true
  end
  return false
end

function getGlobalEffect(t)
  return md:curInstance().global_effects.effects[t]
end

-- if you want title bars or floating text can be seen
-- in cutscene, you should use Util.curCamera to get
-- the current camera to adjust the rotation of your ui
function curCamera()
  local cc = rawget(_G, 'cc')
  if cc and cc.camera then 
    return cc.camera
  end
  return SceneUtil.getMainCam()
end

function setNumberImg(num, img)
  img:setSprite('font0' .. tostring(math.round(54+num)))
end

function autoCenterHoz(nodes, centerPos, slotSize, padding, offset)
  local xArr = _calcCenterLayoutPos(#nodes, centerPos.x, slotSize, padding, offset)
  for i = 1, #nodes do local v = nodes[i]
    local xv = xArr[i]
    v:setPosition(Vector3(xv, centerPos.y, v.transform:get_position().z))
  end
end

function autoCenterVert(nodes, centerPos, slotSize, padding, offset)
  local yArr = _calcCenterLayoutPos(#nodes, centerPos.y, slotSize, padding, offset)
  for i = 1, #nodes do local v = nodes[i]
    local yv = yArr[i]
    v:setPosition(Vector3(centerPos.x, yv, v.transform:get_position().z))
  end
end

function _calcCenterLayoutPos(slotNum, center, slotSize, padding, offset)
  local halfNum = math.floor(slotNum/2)
  local stp = nil
  if slotNum % 2 == 0 and halfNum > 0 then
    stp = center - (halfNum - 0.5) * (slotSize + padding)
  else
    stp = center - (halfNum) * (slotSize + padding)
  end
  local res = {}
  local cur = stp
  for i = 1, slotNum do
    table.insert(res, cur+(i-1)*(slotSize+padding)+offset)
  end
  return res
end

function mergeBonuses(bonuses)
  local bonusesTable = {}
  for k, thing in pairs(bonuses) do

    if not bonusesTable[thing.id] then
      bonusesTable[thing.id] = 0
    end
    bonusesTable[thing.id] = thing.count + bonusesTable[thing.id]
  end
  return bonusesTable
end

function playRandomAnim(view3d, anims)
  if type(anims) == 'string' and anims ~= '' then
    view3d:playAnim(anims)
    return anims
  elseif type(anims) == 'table' and #(anims) > 0 then
    local index = math.random(1, #(anims))
    local action = anims[index]
    view3d:playAnim(action)
    return action
  end
  return nil
end


local BONUS_TAGS_INDEX = {
  city   = 1,
  common = 2,
  effect = 3,
}
function sortBonuses(bs)
  table.sort(bs, function(lhs, rhs)
    local ltag = lhs['tag']
    local rtag = rhs['tag']
    if BONUS_TAGS_INDEX[ltag] == nil then
      return false
    elseif BONUS_TAGS_INDEX[rtag] == nil then
      return true
    end
    return BONUS_TAGS_INDEX[ltag] < BONUS_TAGS_INDEX[rtag]
  end)
  return bs
end

function sortCampaignResultBonuses(bonuses)

  local getTypeValue = function(tid)
    if tid:match('^ite') or tid:match('^pro') then
      return 1
    elseif tid:match('^eqp') then
      return 3
    elseif tid:match('^bbe') then
      return 2
    end
    return 0
  end

  table.sort(bonuses, function(lhs, rhs)
    local ltype = cfg:getType(lhs.tid)
    local rtype = cfg:getType(rhs.tid)

    if not ltype then return false end
    if not rtype then return true end

    -- 1、品质：橙色>紫色>蓝色>绿色
    if ltype.grade ~= rtype.grade then
      return ltype.grade > rtype.grade
    end

    -- 2、同品质下根据类型：装备>时装>道具。
    local ltv = getTypeValue(lhs.tid)
    local rtv = getTypeValue(rhs.tid)
    if ltv ~= rtv then
      return ltv > rtv
    end

    return lhs.tid > rhs.tid
  end)
  return bonuses
end

function setBonusTag(bonus, prefix, view)
  local tag = bonus.tag
  local mc = view[prefix]
  local txt = view[prefix .. '_text']
  if tag == 'city' then
    mc:setVisible(true)
    txt:setString(loc('str_ui_bonus_' .. tag))
  else
    mc:setVisible(false)
  end
end

local chooseAngles = {-360, 0, 360}
function chooseNearestToAngle(fromAngle, toAngle)
  -- check x angle
  local min = 360
  local deltax = 0
  for i = 1, #chooseAngles do
    local v = chooseAngles[i]
    local d = abs(fromAngle[1] - (toAngle[1] + v))
    if d < min then
      min = d
      deltax = v
    end
  end
  -- check y angle
  min = 360
  local deltay = 0
  for i = 1, #chooseAngles do
    local v = chooseAngles[i]
    local d = abs(fromAngle[2] - (toAngle[2] + v))
    if d < min then
      min = d
      deltay = v
    end
  end
  -- check z angle
  min = 360
  local deltaz = 0
  for i = 1, #chooseAngles do
    local v = chooseAngles[i]
    local d = abs(fromAngle[3] - (toAngle[3] + v))
    if d < min then
      min = d
      deltaz = v
    end
  end
  return Vector3(toAngle[1] + deltax, toAngle[2] + deltay, toAngle[3] + deltaz)
end

function vecNearlyEqual(v1, v2)
  local diff = v1 - v2
  return abs(diff[1]) <= 0.01 and abs(diff[2]) <= 0.01 and abs(diff[3]) <= 0.01
end

function colorStrWithNum(num, judgeNum, lessColor, moreColor)
  local str         = tostring(num)
  local judgeNumStr = tostring(judgeNum)
  if num >= judgeNum then
    str         = Util.strElem(moreColor, nil, str)
    judgeNumStr = Util.strElem(moreColor, nil, judgeNumStr)
  else
    str         = Util.strElem(lessColor, nil, str)
    judgeNumStr = Util.strElem(lessColor, nil, judgeNumStr)
  end
  return str, judgeNumStr
end

function getTimeStampValue(stampValue)
  local interval = stime() - stampValue.last_refresh_time
  local temporary_value = stampValue.value
  local addValue = (math.floor(interval / stampValue.wait_interval) * stampValue.increase_value)
  temporary_value = temporary_value + addValue
  if temporary_value < 0 then temporary_value = 0 end
  -- if stampValue.limit and (stampValue.limit > 0) and (temporary_value > stampValue.limit) then temporary_value = stampValue.limit end
  return math.ceil (temporary_value)
end

function getPlayerID()
  return md:pid()
end

function getPlayerIDValue(id)
  local zone, cid, iid = decodePid(id)
  return tonumber(cid) or 0
end

function isInGuild()
  return md.guild ~= nil
end

function isInTeam()
  return TeamUtil.isInTeam()
end

function getDialogCamType(entity)
  local bone_id = entity.config.bone_id
  logd('getDialogCamType %s', peek(bone_id))
  return cfg.dialog_cams[bone_id] or cfg.dialog_cams['male101']
end

function makeFloatingTextList(bonusesTable)
  local messages ={}
  local index = 1
  for id, count in pairs(bonusesTable) do
    messages[index] = "获得"..ItemUtil.getNameText(id) .. loc("%s",count)
    index = index + 1
  end
  FloatingTextList.instance():addMessages(messages)
end

function playMovie(name)
  logd('playMovie name=%s start', tostring(name))
  keepConnectionBegin()
  local path = getMoviePath(name)
  if game.ios() then
    MovUtil.playMovName('file://'..path)--"episode1.mp4"
  elseif game.android() then
    MovUtil.playMovName(path)
  end
  logd('playMovie name=%s finished', tostring(name))
end

function playMovieNoSkip(name)
  logd('playMovieNoSkip name=%s start', tostring(name))
  keepConnectionBegin()
  local path = getMoviePath(name)
  if game.ios() then
    MovUtil.playMovNameNonInteractive('file://'..path)--"episode1.mp4"
  elseif game.android() then
    MovUtil.playMovNameNonInteractive(path)
  end
  logd('playMovieNoSkip name=%s finished', tostring(name))
end

function getMoviePath(name)
  local path = engine.fullPathForFilename(name)
  -- local deviceModel = game.systemInfo.deviceModel
  -- 2017-7-3: fix some android devices (Xiaomi, Honor etc.) play movie
  if string.match(path, '^jar:file:') then
    local file = string.gsub(path, '^jar:file:.+assets/', '')
    local rootpath = UpdateManager.rootpath()
    local filepath = rootpath .. '/' .. file
    local hasExternal = (lfs.attributes(filepath, 'mode') == 'file' and lfs.attributes(filepath, 'size') > 0)
    if not hasExternal then
      mkpath(rootpath)
      logd('copy movie file from %s to %s', path, filepath)
      if not engine.copyFile(name, filepath) then
        logd('getMoviePath: copying failed, deleting...')
        engine.deleteFile(filepath)
      end
    end
    path = filepath
  end
  return path
end

function batchSell(options)
  ui:push(SellPopView.new(options))
end

function getRealInterval(inst, reset)
  local curTime = Time:get_realtimeSinceStartup()
  inst.__lastRealTimeSinceStartup = inst.__lastRealTimeSinceStartup or curTime
  if reset then
    inst.__lastRealTimeSinceStartup = curTime
  end
  local interval = curTime - inst.__lastRealTimeSinceStartup
  inst.__lastRealTimeSinceStartup = curTime
  return interval
end

function curCampaignType()
  local scene = cc.scene
  if scene == nil then return 'none' end
  if scene.class == PveFightScene then
    return 'single_pve'
  elseif scene.class == MultiPveFightScene then
    return 'multi_pve'
  elseif scene.class == PvpFightScene then
    return 'pvp'
  else
    return 'main'
  end
end

-- images/ui/symbol/
local digitImgTable = nil
function _checkImgTable()
  if not digitImgTable then
    digitImgTable = {}
    for i = 0, 9 do
      digitImgTable[tostring(i)] = loc('font%03d', 54+i)
    end
  end
end

function setDigitImage(ctrl, digit)
  _checkImgTable()
  -- logd('setDigitImage %s, %s', peek(digit), debug.traceback())
  ctrl:setSprite(digitImgTable[tostring(digit)])
end

function clearAllColorTag(str)
  str = string.gsub(str, "<%s*color%s*=%s*#%x*%s*>", '')
  str = string.gsub(str, "<%s*/%s*color%s*>", '')
  return str
end

function getClearStr(str)
  str = string.gsub(str,'%[link_item', '****')
  str = string.gsub(str,"%[link_player","****")
  str = string.gsub(str,"%[link_team","****")
  str = string.gsub(str,"%[url","****")
  str = string.gsub(str,"%[u","****")
  str = string.gsub(str,"%<","*")
  str = string.gsub(str,"%>","*")
  return str
end

function getLinkStr(str, itemIdTable)
  for k, content in utf8.gmatch(str, "(%w*)%[(%w*)%]") do
    for k, hashTable in pairs(itemIdTable) do
      local id       = hashTable.id
      local nameNote = hashTable.nameNote
      local name     = hashTable.name
      if content == name or content == name..nameNote then
        local gsStr = linkStr(id, nameNote)
        str = string.gsub(str, "%["..content.."%]", gsStr)
      end
    end
  end
  return str
end

function linkStr(id, nameNote)
  nameNote = nameNote or ''
  local colorName = Util.getNameText(id, -1, nameNote)
  return loc("[link_item=%s]%s[/link_item]",id, colorName)
end


function getRecruitStr(cinfo, cid)
  return recruitStr(cinfo, cid)
end

function recruitStr(cinfo, cid)
  local team = TeamUtil.getMyTeam()
  local str = RecruitUtil.getLinkStr(cid)
  -- loge("team:%s, cid:%s, cinfo:%s", inspect(team), tostring(cid), tostring(cinfo))
  local id = string.format('%s|%s|%s', team.pid, cid, cinfo)
  return loc("[link_team=%s]%s[/link_team]", id, str)
  -- return str
end

function mergeItemInfos(opts, itemIdTable)
  for _, hash in pairs(itemIdTable) do
    mergeItemWithId(opts, hash.id)
  end
end

function mergeItemWithId( opts, id )
  if opts.itemInfos == nil then opts.itemInfos = {} end
  if id:match('^i_eqp') then
    local equip = md:equip(id)
    opts.itemInfos[id] = equip
  elseif id:match('^i_bbe') then
    local garment = md:garment(id)
    opts.itemInfos[id] = garment
  end
end

function getExpressionStrCharNum(inStr)
  local escapedTagStr, count = utf8gsub(inStr, '<[^>]+>', '')
  local str = escapedTagStr
  for k, content in utf8.gmatch(escapedTagStr, "#%d%d") do
    local emoId = string.format("emo%03d", tonumber(string.sub(k, 2, -1)))
    local cfgType = cfg.emoticons[emoId]
    if cfgType then
      local gsStr = '惊'
      str = string.gsub(str, k, gsStr, 1)
    end
  end
  -- logd('getExpressionStrCharNum org: %s, new: %s, len: %s', inStr, str, utf8len(str))
  return utf8len(str)
end

function getExpressionStr(str, iconWidth, heightDelta)
  iconWidth = iconWidth or 30
  heightDelta = heightDelta or -10
  for k, content in utf8.gmatch(str, "#%d%d%d%d") do
    -- logd('getExpressionStr k:%s, sub:%s', k, string.sub(k, 2, -1))
    -- local emoId = string.format("emo%03d", tonumber(string.sub(k, 2, -1)))
    -- local cfgType = cfg.emoticons[emoId]

    local emoId = string.format("exp%s", tostring(string.sub(k, 2, -1)))
    -- logd(">>>>>>>>>>>emoId:%s",tostring(emoId))
    local cfgType = cfg.expression[emoId]
    if cfgType then
      -- local gsStr = string.format("<sprite=images/icons/emoticons name=%s width=%d height=%d heightDelta=%d/> ", cfgType.icon, iconWidth, iconWidth, heightDelta)
      local gsStr = string.format("<sprite=images/ui/icon171 name=%s width=%d height=%d heightDelta=%d/> ", cfgType.icon_res, iconWidth, iconWidth, heightDelta)
      str = string.gsub(str, k, gsStr, 1)
    end
  end
  return str
end

function linkHandle(id, str, idTable)
  local name = Util.getClearName(id)
  local itemlimit = 3
  local equiplimit = 1
  local repeatNameTime = 0

  for i = #idTable, 1, -1 do
    local data = idTable[i]
    local x, y = string.find(str, ("%["..data.name..data.nameNote.."%]"))
    if y == nil then
      table.remove(idTable, i)
    end
  end
  local lasteEquipIndex = 0
  local equipSum = 0
  for index, data in pairs(idTable) do
    if id == data.id then return str end
    if name == data.name then repeatNameTime = repeatNameTime + 1 end
    if data.id:match('eqp') or data.id:match('bbe') then
      lasteEquipIndex = index
      equipSum = equipSum + 1
    end
  end
  local nameNote = repeatNameTime > 0 and "_"..repeatNameTime or ""
  local dataTable = {id = id, name = name, nameNote = nameNote, tag = "item"}
  if (id:match('eqp') or id:match('bbe')) and equipSum >= equiplimit then
    local oldLastData = idTable[lasteEquipIndex]
    str = string.gsub(str, oldLastData.name..oldLastData.nameNote, dataTable.name..dataTable.nameNote)
    idTable[lasteEquipIndex] = dataTable
  elseif table.nums(idTable) >= itemlimit then
    local oldLastData = idTable[table.nums(idTable)]
    str = string.gsub(str, oldLastData.name..oldLastData.nameNote, dataTable.name..dataTable.nameNote)
    idTable[table.nums(idTable)] = dataTable
  else
    local linkStr = loc("[%s]", dataTable.name..dataTable.nameNote)
    table.insert(idTable, dataTable)
    str = str..linkStr
  end
  return str
end

function pushRichSystemMessage(title, locText, ids)  -- locText : '获得装备%s一件 %s一个'  ids : {'i_eqp_eqp11001201_19', 'ite1001002'}
  title   = title or loc("str_ui_msg")
  local content  = {}
  local args     = {}
  for _, id in pairs(ids) do
    table.insert(args, Util.linkStr(id))
    Util.mergeItemWithId(content, id)
  end
  local text = loc(locText, unpack(args))
  Util.pushSystemMessage(title, text, content)
end

function pushSystemMessage(title, text, content)
  -- queue system message because there can be many bonus text at once (when drop doobers) and
  -- TableViewController update is slow
  HeavyTaskQueue.submit('sys_msg', title, Util.doPushSystemMessage, title, text, content)
end

function doPushSystemMessage(title, text, content)
  unity.beginSample('pushSystemMessage')

  title   = title or loc("str_ui_msg")
  content = content or {}
  if text == nil or string.gsub(text," ", "") == "" then
    unity.endSample()
    return
  end

  local textStr = loc("[%s] %s",title, text)--<color=#ffc500> </color>
  if title == loc("str_ui_msg") then
    --textStr = loc("<color=#ffc500>%s</color>",textStr)
    if content.color then
      local str = "<color=" .. content.color .. ">%s</color>"
      textStr = loc(str,textStr)
    else
      textStr = loc("<color=#ffc500>%s</color>",textStr)
    end
  end
  local chat = {cid = "system", text = textStr, content = content}

  --md:signal('channel_chat'):fire(chat)
  md:signal('system_notice_message'):fire(chat)

  unity.endSample()
end

function pushPrivateChatChannel(pname, text)
  title = loc("str_contacts")
  local chat = {cid = "other", text = text, title = title, pname = pname, privateChannel = true}
  chat.color = unity.newHexToColor("ff7e1f")
  md:signal('channel_chat'):fire(chat)
end

function systemWithBonusHandle(bonus)
  unity.beginSample('systemWithBonusHandle')

  if bonus.not_show_system_message then
    unity.endSample()
    return
  end

  if bonus.id:match('^i_eqp') then
    local str = loc("str_system_channel5")
    pushRichSystemMessage(nil, str, {bonus.id})
  elseif bonus.id:match('^ite') then
    local cfgit = cfg.items[bonus.id]
    if cfgit.category and cfgit.category == 'currency' then  -- 货币类型获得  不显示颜色
      if cfgit.usages.npc or cfgit.addattr == "experience" then  -- 如果是好感度 的物品 则不提示
      elseif bonus.count > 0 then
        local content = string.format("%s[%s]+%s",
        loc("str_ui_received"),
        Util.getClearName(bonus.id),
        tostring(bonus.count))
        Util.pushSystemMessage(loc("str_ui_msg"), content)
      end
    else
      if bonus.count > 0 then
        local str = loc("str_system_channel6")..'+'..bonus.count
        pushRichSystemMessage(nil, str, {bonus.id})
      end
    end
  elseif bonus.id:match('^i_bbe') then
    local str = loc("str_system_channel7")
    pushRichSystemMessage(nil, str, {bonus.id})
  end

  unity.endSample()
end

function forceRemoveCutsceneTransitionView()
  -- logd("CutsceneTransitionView force remove ...."..debug.traceback())
  local ctv = Util.checkCutsceneTransitionView()
  if ctv then
    ui:removeWithName('CutsceneTransitionView')
  end
end

function checkCutsceneTransitionView(options)
  -- logd("CutsceneTransitionView check show ...."..debug.traceback())
  local ctv = ui:findViewByName('CutsceneTransitionView')
  if not ctv then
    -- logd("CutsceneTransitionView create new.... %s", debug.traceback())
    ctv = CutsceneTransitionView.new(options)
    ui:push(ctv)
  elseif options then
    logd("CutsceneTransitionView exist....")
    ctv:setOptions(options)
  end
  return ctv
end

function setFactionIcon(faction, mc)
  if is_null(faction) then return end
  local iconPath = cfg:rolefaction(faction).occupation_icon
  if mc then
    mc:setSprite(iconPath)
  else
    loge('mc is nil %s', debug.traceback())
  end
end

function setFactionBigIcon(faction, mc)
  if is_null(faction) then return end
  local iconPath = cfg:rolefaction(faction).occupation_icon .. "_b"
  if mc then
    mc:setSprite(iconPath)
  end
end

function setPartitionIcon(partition, mc)

end

function inGroup()
  return CommonGroupUtil.getMyGroup() or JiubaUtil.getMyGroup()
end


function getCurPortraitId()
  local curInstance = md:curInstance()
  if not curInstance then return nil end

  return curInstance.hero.portrait.cur_id
end

function showCreditPopup()
  sm:playSound("button018")
  ui:push(CommonPopup.new({
    strDesc       = loc('str_currency_exchange_1'),
    strRightBtn   = loc('str_recharge'),
    rightCallback = function()
      sm:playSound("button008")
      ui:removeWithName('CommonPopup')
      local mallRoot = ui:findViewByName("MallRootView")
      if mallRoot then
        mallRoot:selectMall(5)
      else
        local mallRoot = ViewFactory.make('MallRootView', {type=5})
        ui:push(mallRoot)
      end
    end,
    }))
end

function showCurrencyNotEnoughPopup(currencyType, needNum, onComplete)
  if currencyType == "coins" or currencyType == "ite8000001" then
    sm:playSound("button018")
    ui:push(BuyCoinsPopup.new(needNum, onComplete))
  elseif currencyType == "money" or currencyType == "ite8000002" then
    sm:playSound("button018")
    ui:push(BuyMoneyPopup.new(needNum, onComplete))
  elseif currencyType == "credits" or currencyType == "ite8000003" then  -- credits
    sm:playSound("button018")
    showCreditPopup()
  else
    local itemType = cfg:getType(currencyType)
    currencyName = itemType and itemType.name or currencyType
    FloatingTextFactory.makeFramed{text=loc("str_smth_not_enough", currencyName)} --xxx不够
  end
end

function inspectPlayer(hid, pid, options)
  local zone, cid, iid = decodePid(pid)
  local view = options.view
  local fullscreen = options.fullscreen

  local ipc = nil
  if view then
    view.__inspectPlayerCache = view.__inspectPlayerCache or {}
    ipc = view.__inspectPlayerCache
  end
  ipc = ipc or {}

  local showHIV = function(mdl, instance)
    mdl.instance = instance
    ui:push(HeroInformationView.new(mdl, {fullscreen=fullscreen}))
  end

  local data = ipc[pid]
  if not data then
    local model = {}
    model.tid = hid
    model.pid = cid
    model.inst_id = iid
    model.zone = zone
    md:rpcInspectPlayer(iid, cid, zone,
      function(msg)
        if msg.success then
          ipc[pid] = {
            model = model,
            inst = msg.instance,
          }
          showHIV(model, msg.instance)
        end
      end
    )
  else
    showHIV(data.model, data.inst)
  end
end

function exitGameCleanup()
  IntervalChecker.stop()
  md:clearChatCacheList()
  FloatingTextList.instance():stop()
  reportGameData('exitServer')
end

function tryExitGame()
  local function cleanup()
    exitGameCleanup()
  end

  local function leaveGroup()
    md:rpcLeaveAllGroups(function(msg)

    end)
  end

  ui:push(CommonPopup.new({strDesc = 'str_mobile_view_exit_text',
    rightCallback = function()
      local curViewName = ui:curViewName()
      if curViewName ~= 'LoginView' then
        cleanup()
        LoginView.createRoleAndEnterGame({
          needGetGameData = true,
        })
        leaveGroup()
      else
        ui:pop()
      end
    end,
    strLeftBtn = loc("str_login_6"),
    strRightBtn = loc("str_login_4"),
    leftCallback = function()
      local curViewName = ui:curViewName()
      if curViewName ~= 'LoginView' then
        cleanup()
        ui:goto(LoginView.new())
        leaveGroup()
      else
        ui:pop()
      end
    end}
    ))
end


function getAchievementCurValue(tid)
  local ac = md:curInstance().achievement_box.achievements[tid]
  if ac then
    return ac.cur_value
  else
    return 0
  end
end

function translateHelpLinkStr(str)
  local strContent = string.gsub(str, '<%s*item%s*=%s*(%w*)%s*>', function(tid)
    local strName = getNameText(tid, 0)
    return loc("[link_item=%s]%s[/link_item]",tid, strName)
  end)
  return strContent
end

function getFightingValue(cate)
  local hero = md:curHero()
  if hero == nil then return 0 end
  if hero.fight_vals == nil then return 0 end
  if hero.fight_vals[cate] == nil then return 0 end
  return math.round(hero.fight_vals[cate])
end

function pushHelpView(helpTid)
  if helpTid == nil then return end
  local htype = cfg.help.data[helpTid]
  if htype == nil then return end
  local helpTab1 = htype.order1
  local helpTab2 = htype.order2
  local helpTab3 = htype.order3
  if helpTab3 == 0 then helpTab3 = nil end
  ui:push(HelpMainView.new({tab1=helpTab1, tab2=helpTab2, tab3=helpTab3}))
end

function pushGuideView(options)
  local view = ChaptersUnlockNavigationView.new(options)
  ui:push(view)
end

--统一处理道具数量的显示问题
-- 有的数字有前后缀，本身和前缀后缀还有颜色,
-- color 如果没有，则默认颜色是“white”
-- 例如：
-- options = { prefix = {str = "daoju", color = "orange"},
--             middle = {num = 99999},
--             suffix = {str = "ge", color = "green"}
--           }
function setCountStr(node, options)
  local preStr = ""
  local prefix = options.prefix
  if prefix then
    local str = prefix.str
    local color = prefix.color
    preStr = ColorUtil.getColorString(str, color)
  end

  local midStr = ""
  local middle = options.middle
  if middle then
    local count = middle.num
    local countStr = tostring(count)
    local color = middle.color

    if count >= 1000 then
      if count < 99000 then
        local thousand = math.floor(count/1000)
        countStr = tostring(thousand) .. "k"
      else
        countStr = "99k"
      end
    else
      countStr = tostring(count)
    end
    midStr = ColorUtil.getColorString(countStr,color)
  end

  local sufStr = ""
  local suffix = options.suffix
  if suffix then
    local str = suffix.str
    local color = suffix.color
    sufStr = ColorUtil.getColorString(str, color)
  end
  local lastStr = preStr .. midStr .. sufStr

  node:setString(lastStr)
end

function getCountStr(num)
  local count = num
  local countStr = ""
  if count >= math.pow(10, 8) then
    local hundredMillion = math.floor(count/math.pow(10, 8))
    countStr = tostring(hundredMillion) .. loc('str_icon_num_unit_2')
  elseif count >= math.pow(10, 6) then
    local tenThousand = math.floor(count/math.pow(10, 4))
    countStr = tostring(tenThousand) .. loc('str_icon_num_unit_1')
  elseif count >= math.pow(10, 4) then
    local tenThousand = MathUtil.GetPreciseDecimal(count/math.pow(10, 4), 1)
    countStr = tostring(tenThousand) .. loc('str_icon_num_unit_1')
  else
    countStr = tostring(count)
  end
  return countStr
end

function getBaseFaction()
  local hero = md:curHero()
  if hero and hero.tid then
    return cfg.heroes[hero.tid].faction
  end
end

-- 天赋强化
function isTalentUnlock()
  return md:isFunUnlock("func1001") and HeroUtil.isSeniorFaction()
end

-- 装备提升开启
function isEquipStrengthUnlock()
  return md:isFunUnlock('func1601')
end

-- 伙伴羁绊开启
function isPartnerUnlock()
  return md:isFunUnlock('func2301')
end

-- 肌体提升开启
function isMuscleUnlock()
  return md:isFunUnlock('func1201')
end

-- 招式开启
function isSkillUnlock()
  return md:isFunUnlock('func0901')
end

function getZoneName(zone)
  local ztype = cfg.zones[tonumber(zone)]
  if ztype == nil then
    return 'none'
  end
  return ztype.number
end

function getidFromPid(pid)
  local zone, cid, iid = decodePid(pid)
  return cid
end

function getZoneDisplay(zone)
  if zone == md.chief.zone then
    return ''
  else
    return '(' .. getZoneName(zone) .. ')'
  end
end
--显示阅历界面
function showExperienceView(bonuses)
  -- if not md:isFunUnlock('func2501') then return end
  -- if bonuses then
  --   for k, bonus in pairs(bonuses) do
  --     if bonus.id == "ite8000014" then
  --       qm.addBeforeAction("levelup", {name = 'show_city_event_exp', args = bonus})
  --     end
  --   end
  -- end
end

-- 检查背包界面是否打开
function checkIsBagViewOpen()
  local key, vsIndex = ui:findViewIndex("BagView")
  if key then
    return true
  else
    return false
  end
end

function refreshCombatUIAttrCache(view, attrName, forceRefresh)
  local attrCache = view.prevDispData.attrCache
  local attrNameCache = view.prevDispData.attrNameCache
  attrNameCache[attrName] = attrNameCache[attrName] or {}
  attrNameCache[attrName]['cur'] = attrNameCache[attrName]['cur'] or 'cur_'..attrName
  local curAttrName = attrNameCache[attrName]['cur']

  if forceRefresh then
    attrCache[curAttrName] = view.model:clampedAttr(curAttrName)
    attrCache[attrName] = view.model:clampedAttr(attrName)
  else
    attrCache[curAttrName] = attrCache[curAttrName] or view.model:clampedAttr(curAttrName)
    attrCache[attrName] = attrCache[attrName] or view.model:clampedAttr(attrName)
  end
end

function getBirthdayString()
  local t = md:record().first_time_landing_time or 0
  return ServerTime.getDateString(t)
end

function makeTipOptions(id, compareAttr)
  local options = {btn={}, posType='left'}
  options.noBtn = true
  if showAtRight then
    options.posType = 'right'
    options.compareAttr = compareAttr
    options.isComparing = true
  end
  return options
end

function calcDistance(options)
  local distance = -1
  local stopId = options.stopId
  local guider = options.guider

  local curCityId  = cc.scene.cityId
  local cityType   = cfg.city[curCityId]
  local relationCityId = cfg.city_relations[curCityId]

  local fromPos = nil
  if curCityId ~= relationCityId then
    fromPos = cityType.relation.pos
    fromPos.y = 0
    fromPos = Util.posToPoint(fromPos)
  else
    local hero = cc.findMyHero()
    fromPos = hero:position()
  end

  if stopId then
    local stopType = cfg.taxi.stop_list[stopId]
    local destCityId = stopType.position.city_id
    local destCity = cfg.city[destCityId]
    local destRelationTid = cfg.city_relations[destCityId]

    local toPos = stopType.position
    toPos = Vector3.new(toPos.coordinate[1], 0, toPos.coordinate[3])
    if destCityId ~= destRelationTid then
      toPos = destCity.relation.pos
      toPos = Vector3.new(toPos.x, 0, toPos.z)
    end
    distance = TaxiUtil.getTaxiDistByCityId(relationCityId, destRelationTid, fromPos, toPos)
  else
    local destRelationTid = cfg.city_relations[guider.dstCityID]
    local toPos = guider.ptDst
    local dstCityID = guider.dstCityID
    if dstCityID ~= destRelationTid then
      local destCity = cfg.city[dstCityID]
      toPos = destCity.relation.pos
      toPos = Vector3.new(toPos.x, 0, toPos.z)
    end
    distance = TaxiUtil.getTaxiDistByCityId(relationCityId, destRelationTid, fromPos, toPos)
  end
  return distance
end

function guideTo(options)
  md.openNpcFunc = nil

  local opt = nil
  local stopId = options.stopId
  local category = options.category
  if category == "position" then
    -- 打车或者步行去某个场景某个坐标点, dir表示朝向, desc可以为空，表示的是将要去的坐标点的名称,用于界面上显示目的地名称
    opt = { category = "position", sid = options.tid , pos = options.pos, lookPos = true, desc = options.desc}
  elseif category == "facility" then
    local facility = cfg.facilities[options.tid]
    stopId = facility.quick_taxi or stopId
    opt = { category = "facility", facility_id = options.tid, facility_param = options.facility_param}
  elseif category == "npc" then
    local npc = cfg.npcs[options.tid]
    stopId = npc.quick_taxi or stopId
    opt = { category = "npc", npc_id = options.tid}
  elseif category == "item" then
    local itemType = cfg.items[options.tid]
    if itemType.usages and itemType.usages.navigation then
      local paths = itemType.usages.navigation.paths
      if paths and paths[1] then
        stopId = itemType.usages.navigation.quick_taxi
        opt = paths[1]
      end
    end
  elseif category == 'dnpc' then
    opt = { category = "dnpc", npc_id = options.tid}
  elseif category == "scene" then   --用于内景
    stopId = options.stopId
    opt = {category = "scene", sid = options.tid}
  end
  if opt == nil then
    loge("guider opt is nil!!")
    return
  end

  --是否步行
  local isWalk = false
  if category == 'npc' and stopId == 'position' and md:isFunUnlock('func1801') and not isWalk then
    local dstCityID, ptDst, dir = Guider.getDstInfoNpc(options.tid)
    if dstCityID and ptDst then
      local pos = Util.posToPoint(ptDst)
      pos = Vector3(pos)
      local dir2 = UIUtil.getForwardFromDirIndex(dir)
      -- loge('dir2=%s dir=%s', tostring(dir2), dir)

      local npcType = cfg.npcs[options.tid]
      local talkRadius = 1

      if npcType.direct_func and npcType.direct_func.tid and npcType.direct_func.tid ~= '' then
        if npcType.talk_radius then talkRadius = npcType.talk_radius / 2 - 0.2 end
      end

      local offset = Vector3.new(dir2 * (-talkRadius))

      opt = {category = 'position', sid = dstCityID, pos = {pos[1], pos[2], pos[3]}, offset = offset, dir = dir, lookPos = true, desc = cfg.city[dstCityID].name}
      category = 'position'
    end
  elseif category == 'dnpc' and stopId == 'position' then
    local dstCityID, ptDst, dir = Guider.getDstInfo_dnpc(opt)

    if dstCityID and ptDst then
      local pos = Util.posToPoint(ptDst)
      pos = Vector3(pos)
      local dir2 = UIUtil.getForwardFromDirIndex(dir)

      local talkRadius = 1

      local offset = Vector3.new(dir2 * (-talkRadius))

      opt = {category = 'position', sid = dstCityID, pos = {pos[1], pos[2], pos[3]}, offset = offset, dir = dir, lookPos = true, desc = cfg.city[dstCityID].name}
      category = 'position'
    end
  end

  if stopId == 'position' then stopId = nil end

  local guider = GuiderFactory.makeManualGuider(opt)

  if category == "position" then
    isWalk = options.isWalk
  else
    isWalk = options.isWalk or (stopId == nil)
  end

  local distance = options.distance or calcDistance({stopId = stopId, guider = guider})
  if distance >= 0 and distance <= cfg.common["taxi_cannot_distance"] then
    -- logd('guideTo isWalk 2 %s', tostring(isWalk))
    isWalk = true
  end

  if guider.dstCityID == cc.scene.cityId and cc.scene:isInteriorScene() then
    isWalk = true
  end

  if GuildUtil.isInDungeon() then
    isWalk = true
  end

  if options.category == 'npc' and options.openFunc then
    local npcType = cfg.npcs[options.tid]
    if npcType and npcType.direct_func then
      guider.options.funcNpc = guider.options.funcNpc or options.tid
    end
  end

  if md:isFunUnlock('func1801') and (not isWalk) then
    sm:playSound("button018")

    if options.category == 'npc' and options.openFunc then
      local npcType = cfg.npcs[options.tid]
      if npcType and npcType.direct_func then
        md.openNpcFunc = deepCopy(npcType.direct_func)
        md.openNpcFunc.npcId = options.tid
      else
        md.openNpcFunc = nil
      end
    else
      md.openNpcFunc = nil
    end

    ui:push(ChapterAppGuiderView.new({guider = guider, stopId = stopId}))
  else

    if md:isFunUnlock('func1801') and stopId then
      FloatingTextFactory.makeFramed{text=loc('str_not_far_away_just_fucking_walk_there')}
    end

    ui:popAll()
    gcr.mGuiderMan:stopGuide()
    gcr.mGuiderMan:setGuider(guider, GuiderManager.GUIDER_CAT_MANUAL)
    gcr.mGuiderMan:setCurGuider(GuiderManager.GUIDER_CAT_MANUAL)
    gcr.mGuiderMan:startGuide()
  end
end

function showMarquee(message, loopNum, priority)
  -- logd("check cc.scene23: %s", tostring(cc.scene.gameEntered))
  if cc.scene and cc.scene.gameEntered then
    MarqueeList.instance():addMessage(message, loopNum, priority)
  end
end

function getPagedDataList(fullList, numInPage, page, res)
  -- first page is 1

  res = res or {}
  table.clear(res)

  local startIndex = (page - 1) * numInPage + 1
  local endIndex = math.min(startIndex + numInPage - 1, #fullList)

  for i = startIndex, endIndex do
    table.insert(res, fullList[i])
  end

  return res
end

function getTotalPageNum(listSize, numInPage)
  return math.ceil(listSize / numInPage)
end

function getFuncNpc(funName)
  if funName == 'hospital_drug' then
    local shopNpcs = cfg.func_npcs['shop']
    local res = {}
    for i, v in ipairs(shopNpcs) do
      local npcType = cfg.npcs[v]
      if npcType and
         npcType.direct_func and
         (npcType.direct_func.param == 'sho30011') then
        table.insert(res, v)
      end
    end
    return res
  else
    return cfg.func_npcs[funName]
  end
end

function getNearestNpc(funName)
  if not cc.scene then return nil end
  local me = cc.findMyHero()
  if not me then return nil end

  local tids = getFuncNpc(funName)
  if not tids then return end

  local tid = nil
  local dist = nil
  local opts = { category="npc", npc_id=nil }
  for _,v in pairs(tids) do
    logd('getNearestNpc %s', peek(v))
    opts.npc_id = v
    local g = Guider.new(opts)
    local d = g:calcDist()
    if d ~= 0 then
      dist = dist or d
      tid = tid or v
      if d and d ~= 0 and d < dist then
        dist = d
        tid = v
      end
    end
  end
  return tid
end

function getNearestNpcScene(funName)
  local tid = Util.getNearestNpc(funName)
  if not tid then return nil end
  return cfg.cityNpc[tid]
end

function getNearestFacilityScene(funName)
  local fid = Util.getNearestFacility(funName)
  if not fid then return nil end
  local facilities = cfg.cityfacility[fid]
  return facilities[1]
end

function getNearestFacility(funName)
  if not cc.scene then return nil end
  local me = cc.findMyHero()
  if not me then return nil end

  local tid = nil
  local dist = nil
  local opts = { category="facility", facility_id=nil }
  local tids = cfg.func_facilities[funName]
  for _, v in pairs(tids) do
    opts.facility_id = v
    local g = Guider.new(opts)
    local d = g:calcDist()
    dist = dist or d
    tid = tid or v
    if d and d ~= 0 and d < dist then
      dist = d
      tid = v
    end
  end
  return tid
end

function getNearestFuncUnitTid(funName)
  if getFuncNpc(funName) then
    return getNearestNpc(funName)
  elseif cfg.func_facilities[funName] then
    return getNearestFacility(funName)
  end
end

function getNearestUnitScene(funName)
  if getFuncNpc(funName) then
    return getNearestNpcScene(funName)
  elseif cfg.func_facilities[funName] then
    return getNearestFacilityScene(funName)
  end
end

-- function getNearestNpc(funName)
--   if not cc.scene then return nil end
--   local me = cc.findMyHero()
--   if not me then return nil end

--   local tid = nil
--   local dist = nil
--   local opts = { category="facility", facility_id=nil }
--   for fid, profile in pairs(cfg.facilities) do
--     if profile.func and profile.func.tid == funName then
--       opts.facility_id = fid
--       local g = Guider.new(opts)
--       local d = g:calcDist()
--       dist = dist or d
--       tid = tid or fid
--       if d and d ~= 0 and d < dist then
--         dist = d
--         tid = fid
--       end
--     end
--   end
--   return tid
-- end

function posToPoint(pos)
  local x, y, z = pos[1], pos[2], pos[3]
  if x and y and z then
    -- is a vector representation
    return {x, y, z}
  else
    -- is a config representation
    return {pos.x or 0, pos.y or 0, pos.z or 0}
  end
end

function nestKey(...)
  local t = {...}
  local key = ""
  local len = #t
  for i=1,len do
    key = key .. tostring(t[i])
    if i ~= len then
      key = key .. '.'
    end
  end
  return key
end

function uStringKey(app, key)
  local pid = md:pid()
  return Util.nestKey('app', app, pid, key)
end

-- 购买并使用商品
function buyAndUse(tid, shopId)
  local itemPrice = cfg.goods.items[tid].cost
  if md:curInstance().credits < itemPrice then
    ui:pop()
    Util.showCreditPopup()
  else
    local isLimitEvent = false
    local theShopId = shopId or "sho0001"
    local setNumber = 10001
    local tabIndex = get_tab_index_by_setNumber(theShopId, setNumber)
    local data = cfg.shops[theShopId].tabs[tabIndex]
    local category = data.category
    local floatPrice = getFloatPrice(cfg.goods.items[tid])
    md:rpcBuyGoods(theShopId, tid, floatPrice, 1, category, function(msg)
      sm:playSound("button020")
      local itemId = cfg.goods.items[tid].item_tid
      md:signal("mall_buy"):fire(itemId)
      FloatingTextFactory.makeFramed{text=loc("str_buy_success"),color=ColorUtil.white,autoDestroy=true} --购买成功
      BagUtil.useItem(itemId)
      ui:pop(2)
    end, isLimitEvent)
  end
end

function get_tab_index_by_setNumber(shopId, setNumber)
  local tabs = cfg.shops[shopId].tabs
  local index = 1
  for i,v in ipairs(tabs) do
    if v.sets == setNumber then
      index = i
      break
    end
  end

  return index
end

function getFloatPrice(profile)
  if profile.float_num and profile.float_num > 0 then
    local goodsKey = string.format("{shop}:%s", tostring(profile.tid))
    local rc = md.goodsRecords[goodsKey]
    if rc then
      return rc.cur_price
    end
  end
  return nil
end

function isCameraHighStatus()
  local qsettings = QualityUtil.cachedQualitySettings()
  if cc.scene and cc.scene:couldUseHighCamera() then
    if qsettings.cameraStatus == 'high' then return true end
  end
  return false
end

function maxVigour()
  if md and md:curInstance() and md:curInstance().record then
    local record = md:curInstance().record
    local add = GlobalEffectUtil.getEffectValue('vigour_limit')
    logd("record.max_vigour:%s", tostring(record.max_vigour))
    if record.max_vigour then
      return record.max_vigour + add
    end
  end
  return 0
end

function maxSpirit()
  if md and md:curInstance() and md:curInstance().record then
    local record = md:curInstance().record
    local add = GlobalEffectUtil.getEffectValue('spiritual_limit')
    if record.max_spiritual > 0 then
      return record.max_spiritual + add
    end
  end
  return 0
end

function getMallTabIndex(shopId, set)
  local shopCfg = cfg.shops[shopId]
  for k, v in pairs(shopCfg.tabs) do
    if v.sets == set then
      return k
    end
  end
  return nil
end

function getRealBotLevel(cid, isAdvance)
  local cfgCam = cfg.campaigns[cid]
  local lvRgn = cfgCam.bot_level
  if not lvRgn then
    return nil
  end

  local lv = md:curHero().level
  if not isAdvance then
    lv = md:curInstance().city_event.level
  end

  local realLv = lvRgn["min"]

  if lv > lvRgn["min"] then
    realLv = lv
  end

  if lv > lvRgn["max"] then
    realLv = lvRgn["max"]
  end
  return realLv
end



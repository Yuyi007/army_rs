local m = Model

function m:isFunUnlock(funTid)
  local curInstance = self:curInstance()
  if not curInstance then return false end
  return (curInstance.record.unlock_functions[funTid] == true)
end

function m:onFunctionUnlock(funcTid, msg)
  UnlockUtil.showFunctionUnlock(funcTid, msg)
end

function m:onSkillUnlock(sid)
  if md:isFunUnlock('func0901') then
    UnlockUtil.showSkillUnlock(sid)
  end
end

function m:onRuneUnlock(sid)
  if md:isFunUnlock('func0901') then
    UnlockUtil.showRuneUnlock(sid)
  end
end

function m:onSkillSlotUnlock(ustid)
  if md:isFunUnlock('func0901') then
    UnlockUtil.showSkillSlotUnlock(ustid)
  end
end

function m:onEnterBackground()
  local gcr = rawget(_G, 'gcr')
  if gcr and gcr.wushu then
    gcr.wushu:onEnterBackGround()
  end

  if md then
    md:signal('enter_background'):fire()
  end
end


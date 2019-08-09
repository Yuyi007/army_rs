-- SDKStandard.lua

class('SDKStandard')

local transNum = 0

function SDKStandard.init()
  logd('SDKStandard.init')
end

function SDKStandard.checkUpdate(onComplete)
  logd('SDKStandard.checkUpdate')
end

function SDKStandard.login(onComplete)
  logd('SDKStandard.login')
end

function SDKStandard.pay(id, transId, onComplete)
  logd('SDKStandard.pay ' .. tostring(id))

  local res = {
    ret = 0,
    transId = transId,
  }

  onComplete({
    success = true,
    message = '',
  })

  md:rpcFreeGoodsDispatch(transId, function ()
    logd('rpcFreeGoodsDispatch done')
  end)

  return res
end

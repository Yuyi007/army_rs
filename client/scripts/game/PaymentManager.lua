-- PaymentManager.lua

class('PaymentManager', function (self)
  self.transactions = {}
end)

function PaymentManager:init()
end

function PaymentManager:handleReceipt(msg)
  if msg.trans_id == 'web' then
    self:dispatchGoods(nil, msg)
    return
  end

  local trans = self.transactions[msg.trans_id]
  if trans then
    self:dispatchGoods(trans, msg)
    self.transactions[msg.trans_id] = nil
  end
end

function PaymentManager:onReconnectSuccess()
    -- ui:top():update()
end

function PaymentManager:pay(options)
  self.success = false
  if game.sdk == 'standard' then
    md:rpcGenOrderId(options.id, function(msg)
      local res = SDKStandard.pay(
        options.id, msg.order_id, function (msg)
          if msg.success and not self.success then
            FloatingTextFactory.makeFramed { text = loc('str_adding_credits') }
          end
          logd('pay standard result success=' .. tostring(msg.success) ..
            ' message=' .. tostring(msg.message))
        end)

      logd('pay standard ret=' .. tostring(res.ret) ..
        ' transId=' .. tostring(res.transId))
      self.transactions[msg.order_id] = {
        transId    = msg.order_id,
        goodsId    = options.id,
        onComplete = options.onComplete,
      }
    end)
  else

    if md.disable_chongzhi then
      FloatingTextFactory.makeFramed {text = loc('str_ioscb_locked')}
      return
    end

    md:rpcGenOrderId(options.id, function(msg)
      if msg.success then
        local res = SDKFirevale.pay(options.id, msg.order_id, function(res)
            if res then
              logd('pay firevale result=' .. peek(res))
            else
              loge('pay fireval res=nil')
            end
          end)

        self.transactions[msg.order_id] = {
          transId    = msg.order_id,
          goodsId    = options.id,
          onComplete = options.onComplete,
        }
      else
       FloatingTextFactory.makeFramed {text=loc('str_floating_58')}
      end
    end)
  end

end

function PaymentManager:dispatchGoods(trans, msg)
  if trans then
    local transId = trans.transId
    local goodsId = trans.goodsId
    logd('dispatching goods transId=' .. transId .. ' goodsId=' .. goodsId)
  end

  if msg.pid == md:pid() then
    if msg.bonuses then
      md:showFloatingBonus(msg)
      md:updateBonuses(msg.bonuses)
    end

    if msg.bag then
      md:updateBag(msg.bag)
    end

    if msg.credits then
      md:instance().credits = msg.credits
    end

    if msg.record then
      md:updateRecord(msg)
    end

    if msg.vip then
      md:updateVip(msg)
    end

    if msg.unlock_apps then
      md:handleUnlockApps(msg)
    end

    if msg.base_activity_diff then
      md:handleDailyActivity(msg)
      if msg.daily_activity then
        md:curInstance().daily_activity = msg.daily_activity
      end
    end

    if msg.total_paid then
      md.total_paid = tonumber(msg.total_paid) or 0
    end

    if msg.global_effects then
      md:handleGlobalEffects(msg)
    end

    ui:iterViews(function(v) v:update() end)

    -- fire callback
    if trans and type(trans.onComplete) == 'function' then
      trans.onComplete()
      trans.onComplete = nil
    end
  end

  self.success = true
  FloatingTextFactory.makeFramed {text=loc('str_chongzhi_success')}
end

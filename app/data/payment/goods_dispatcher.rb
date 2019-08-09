
class GoodsDispatcher
  include Loggable

  @@order_processing = {}

  def self.dispatch(params)
    player_id = params[:id]
    pid       = params[:pid]
    zone      = params[:zone]
    sdk       = params[:sdk]
    platform  = params[:platform]
    trans_id  = params[:trans_id] # trans_id = cp_order_id
    goods_id  = params[:goods_id]
    price     = params[:price]
    location  = params[:location]
    market    = params[:market]
    count     = 1

    return false if Player.get_cached(pid).nil?

    if @@order_processing[trans_id] then
      error("GoodsDispatcher: already processing #{trans_id} for #{pid}")
      return false
    end

    d { "dispatch goods, player_id:#{player_id} pid:#{pid} zone:#{zone} sdk:#{sdk} platform:#{platform} transId:#{trans_id} goods_id:#{goods_id} count:#{1} price:#{price}" }

    # here we may take a while before finishing dispatching
    # so save a local var to avoid dispatch twice
    begin
      @@order_processing[trans_id] = true

      CachedGameData.take_or_ask(player_id, zone, GoodsDispatchJob,
        sdk, platform, trans_id, goods_id, market, price, location, pid)
    rescue => er
      error("GoodsDispatcher: take_or_ask #{pid} Error", er)
      false
    ensure
      @@order_processing.delete(trans_id)
    end
  end
end

class GoodsDispatchJob < CachedGameDataJob
  include Loggable

  def self.perform(id, zone, model, sdk, platform,
    trans_id, goods_id, market, price, location, pid)
    # dispatch goods here
    d { "start dispatch goods, player_id:#{id} pid:#{pid} zone:#{zone} trans_id:#{trans_id} goods_id:#{goods_id} count:#{1} price:#{price}" }

    # notify the player by issuing a notification
    receipt = {}
    receipt.trans_id = trans_id

    opts = {
      'sdk'      => sdk,
      'platform' => platform,
      'location' => location,
    }

    info "dispatch goods id=#{id} zone=#{zone} pid=#{pid}"

    bonuses, instance = model.chongzhi(pid, goods_id, opts)
    cfg = GameConfig.chongzhi[goods_id]
    receipt.bonuses       = bonuses
    receipt.bag           = instance.bag.to_hash
    receipt.credits       = instance.credits
    receipt.record        = instance.record.to_hash
    receipt.vip           = instance.vip.to_hash
    receipt.unlock_apps   = instance.record.unlock_apps
    receipt.global_effects = instance.global_effects

    if instance.daily_activity.base_activity_diff > 0
      receipt['base_activity_diff'] = instance.daily_activity.base_activity_diff
      instance.daily_activity.base_activity_diff = 0
      receipt.daily_activity = instance.daily_activity.to_hash
    end

    receipt.cid = id
    receipt.pid = pid
    receipt.total_paid = PayDb.get_record_by_cid(id)

    d { "start dispatch goods, player_id:#{id} pid:#{pid}, zone:#{zone} trans_id:#{trans_id} goods_id:#{goods_id} count:#{1} price:#{price}" }

    gm_pay = trans_id =~ /^gm_/
    status = DynamicAppConfig.maintainance_status
    in_id_whitelist = false
    in_id_whitelist = status.in_id_whitelist?(id) || status.in_id_whitelist?(pid) if !status.nil?

    if !(in_id_whitelist && gm_pay)
      stat("-- payment, #{id}, #{pid}, #{zone}, #{goods_id}, #{1}, #{price}, #{sdk}, #{platform}, #{market}")
    end

    Channel.publish('receipt', zone, receipt)

    true
  end

end


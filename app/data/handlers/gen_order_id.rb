

class GenOrderId < Handler

  def self.process(session, msg, model)
    goods_id  = msg['goods_id']

    ret_fail = {'success' => false}
    return ng('str_pay_invalid_goods_id') if goods_id.nil? || GameConfig.chongzhi[goods_id].nil?
    return ng('no auth') if session.player_id == '$noauth$'

    instance = model.instance

    doProcess(session.player_id, instance.player_id, session.zone,
      session.sdk, session.platform, goods_id, model)
  end

  def self.doProcess(cid, pid, zone, sdk, platform, goods_id, model)
    res = model.valid_chongzhi?(pid, goods_id)
    return res unless res.success

    order_id = PayOrder.gen_id
    order = PayOrder.new(order_id)
    cfg = GameConfig.chongzhi[goods_id]

    order.cid      = cid
    order.zone     = zone
    order.pid      = pid
    order.sdk      = sdk
    order.platform = platform
    order.goods_id = goods_id
    order.time     = Time.now.to_i
    order.credits  = cfg.reward_num
    order.price    = cfg.cost
    order.save

    return {'success' => true, 'order_id' => order_id, 'order' => order.to_hash}
  end

end


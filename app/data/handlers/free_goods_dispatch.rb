# FreeGoodsDispatch.rb

class FreeGoodsDispatch < Handler

  # for debug payment with debug sandbox

  def self.process(session, msg, model)
    return ng('') unless AppConfig.dev_mode?
    trans_id  = msg['transId']

    order = PayOrder.get(trans_id)
    return ng('str_pay_invalid_order') if order.nil?

    goods_id = order.goods_id

    cfg = GameConfig.chongzhi[goods_id]
    price = cfg.cost

    EM::Synchrony.next_tick do
      ret = GoodsDispatcher.dispatch(
        :id       => order.cid,
        :pid      => order.pid,
        :sdk      => order.sdk,
        :platform => order.platform,
        :zone     => order.zone,
        :trans_id => order.id,
        :goods_id => order.goods_id,
        :price    => price)

      if ret
        d {'dispatch success! deleting order'}
        order.delete!
      end
    end

    { "success" => true }
  end

end
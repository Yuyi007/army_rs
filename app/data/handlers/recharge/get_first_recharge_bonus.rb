class GetFirstRechargeBonus < Handler
  def self.process(session, msg, model)
    instance = model.cur_instance
    record = instance.record
    recharge = record.recharge

    return ng('str_not_first_recharged') if !recharge.first_recharged?
    return ng('str_first_bonus_received') if recharge.first_bonus_recieved?

    bonuses = []
    t = GameConfig.first_recharge['fcg001']

    list = []
    (1..5).each do |i|
      o = {}
      tid = t.send("reward#{i}_id")
      num = t.send("reward#{i}_num")

      if tid then
        o.tid = tid
        o.num = num
        list << o
      end
    end

    instance.safe_add_bonuses(list, bonuses, 'first_recharge') if list.size > 0
    recharge.receive_first_bonus
    bag = instance.bag.to_hash

    {
      'success' => true,
      'recharge' => recharge.to_hash,
      'bonuses' => bonuses,
      'bag' => bag,
    }
  end
end
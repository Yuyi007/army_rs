class GetMonthCardBonus < Handler
  def self.process(session, msg, model)
    tid = msg['tid']
    return ng('str_ivalid_tid') if tid. nil?

    instance = model.cur_instance
    record = instance.record
    card = record.month_cards[tid]
    return ng('str_card_not_exist') if card.nil?
    return ng('str_card_cant_receive') if !card.can_receive?

    tcard = GameConfig.month_card[tid]
    bonuses = []
    instance.safe_add_bonus(tcard.reward_id, tcard.reward_num, bonuses, 'month_card')

    card.receive
    res = {'success'=> true}
    res['card'] = card.to_hash
    res['bonuses'] = bonuses
    res.bag = instance.bag.to_hash
    res
  end
end
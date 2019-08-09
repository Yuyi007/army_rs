class GetGrowthFundBonus < Handler
  def self.process(session, msg, model)
    instance = model.cur_instance
    record = instance.record
    growth_fund = record.growth_fund

    tid = msg.tid

    return ng('str_growth_fund_get_fail') if tid.nil? || tid == 'fund001'
    return ng('str_growth_fund_got') if growth_fund.got_tids[tid]
    cfg = GameConfig.growth_fund[tid]
    return ng('str_growth_fund_get_fail') if cfg.nil? || cfg.condition > instance.hero.level

    bonuses, in_mail = growth_fund.get(tid)

    { 'success' => true, 'bonuses' => bonuses, 'in_mail' => in_mail, 'growth_fund' => growth_fund.to_hash , 'bag' => instance.bag.to_hash}

  end
end
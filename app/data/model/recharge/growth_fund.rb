class GrowthFund
  attr_accessor :buy_time
  attr_accessor :got_tids
  attr_accessor :got_all

  attr_accessor :total_coupon

  attr_accessor :got_coupon

  include Loggable
  include Jsonable

  gen_from_hash
  gen_to_hash

  def initialize
    @buy_time ||= 0
    @got_tids ||= {}
    @got_all  ||= false
    @got_coupon ||= 0
    @total_coupon ||= get_total_coupon
  end

  def refresh
    @total_coupon = get_total_coupon
  end

  def get_total_coupon
    total = got_coupon
    GameConfig.growth_fund.each do |k, v|
      total += v.coupon if !got_tids[k] && v.coupon
    end

    total
  end

  def buy
    @buy_time = Time.now.to_i
    @got_tids['fund001'] = true
    @total_coupon = get_total_coupon
    @got_coupon = 0
  end

  def get(tid)
    return [[], false] if tid == 'fund001' || !bought?

    bonuses = []
    in_mail = false
    if !got_tids[tid]
      @got_tids[tid] = true
      @got_all = got_tids.length >= GameConfig.growth_fund.length
      cfg = GameConfig.growth_fund[tid]
      if cfg
        reward = cfg.reward
        reward.each do |bonus|
          bonus, im = instance.add_data_to_bag_or_mail(bonus.tid, bonus.num, false, 1, 'growth_fund')
          bonuses = BonusHelper.merge_bonuses(bonuses, bonus) unless im
          in_mail |= im
        end
        @got_coupon += cfg.coupon if cfg.coupon
      end
    end
    instance.flush_limbo_list if in_mail
    [bonuses, in_mail]
  end

  def bought?
    got_tids['fund001']
  end

  def instance
    record.instance
  end

 def record
    __owner__
  end

end
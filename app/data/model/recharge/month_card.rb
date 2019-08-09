class MonthCard
  attr_accessor :tid
  attr_accessor :first_day
  attr_accessor :last_day
  attr_accessor :last_receive_day #received reset day

  include Loggable
  include Jsonable

  gen_from_hash
  gen_to_hash

  def initialize(tid = nil)
    @tid = tid
    @first_day = 0
    @last_day = 0
    @last_receive_day = 0
  end

  def can_receive?
    (Helper.reset_time >= @first_day && Helper.reset_time <= @last_day) &&
    (@last_receive_day.nil? || @last_receive_day < Helper.reset_time)
  end

  def receive
    @last_receive_day = Helper.reset_time
  end

  def recharge
    cfg = GameConfig.month_card[@tid]
    if @last_day < Helper.reset_time
      @first_day = Helper.reset_time
      @last_day = @first_day + (24 * 60 * 60) * (cfg.days.to_i - 1)
    else
      @last_day += (24 * 60 * 60) * cfg.days.to_i
    end
  end

  def valid?
    @last_day >= Helper.reset_time
  end
end
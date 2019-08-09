class RechargeStatus < Enum
  enum_attr :FIRST_UNRECHARGE, 0
  enum_attr :FIRST_RECHARGED, 1
  enum_attr :FIRST_BONUS_RECEIVED, 2
end

class RechargeRecord
  attr_accessor :recharge_status  #首冲状态
  attr_accessor :extra_bonus      #充值额外给予总和  
  attr_accessor :extra_rids       #充值额外给予的充值id和数量

  include Loggable
  include Jsonable

  gen_from_hash
  gen_to_hash

  def initialize
    @recharge_status = RechargeStatus::FIRST_UNRECHARGE
    @extra_bonus ||= 0
    @extra_rids ||= {}
  end

  def give_extra?(rid)
    @extra_rids[rid].nil?
  end

  def record_extra_bonus(rid, num)
    @extra_rids[rid] = num
    @extra_bonus += num
  end

  def first_recharged?
    @recharge_status == RechargeStatus::FIRST_RECHARGED ||
    @recharge_status == RechargeStatus::FIRST_BONUS_RECEIVED
  end

  def first_recharge
    @recharge_status = RechargeStatus::FIRST_RECHARGED
  end

  def first_bonus_recieved?
    @recharge_status == RechargeStatus::FIRST_BONUS_RECEIVED
  end

  def receive_first_bonus
    @recharge_status = RechargeStatus::FIRST_BONUS_RECEIVED
  end
end
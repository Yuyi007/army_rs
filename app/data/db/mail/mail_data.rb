class MailData
  attr_accessor :read_infos    #已读数据
  attr_accessor :redeem_limit, :redeem_limit_daily
  #attr_accessor :group_mail_ids #所有本id已经获取的群发或者常驻邮件的id

  include Jsonable

  gen_from_hash
  gen_to_hash

  def initialize
    @read_infos ||= {}
    @redeem_limit ||= {}
    @redeem_limit_daily ||= {}
    #@group_mail_ids ||= {}
  end

  def refresh_redeem
    @redeem_limit_daily.each do|st, d|
      rt = Helper.reset_time()
      if d and d.time < rt
        d.num = 0
        d.time = rt
      end
    end
  end

  def inc_time(sub_type)
    @redeem_limit_daily[sub_type] ||= {'time' => Time.now().to_i, 'num' => 0}
    @redeem_limit[sub_type] ||= {'num' => 0}
    @redeem_limit_daily[sub_type].num += 1
    @redeem_limit[sub_type].num += 1
  end

  def check_redeem_time_restrict(sub_type)
    return false, 1 if @redeem_limit and @redeem_limit[sub_type] and @redeem_limit[sub_type].num and GameConfig.mails[sub_type] and @redeem_limit[sub_type].num >= GameConfig.mails[sub_type]['redeem_count'] and GameConfig.mails[sub_type]['redeem_count'] >= 0
    return false, 2 if @redeem_limit_daily and @redeem_limit_daily[sub_type] and @redeem_limit_daily[sub_type].num and GameConfig.mails[sub_type] and @redeem_limit_daily[sub_type].num >= GameConfig.mails[sub_type]['redeem_count_daily'] and GameConfig.mails[sub_type]['redeem_count_daily'] >= 0
    return true
  end
end
require 'json'

class ReportFixer
  def initialize(options = {})
    @options = options
    @date = options[:date]
    @config = options[:config]
    @env = options[:env]
  end

  def fix
    # fix_pid
  end

  def parse_pid(uid)
    arr = uid.split('_')
    if arr.length == 1
      return [uid, uid]
    else
      return [uid, arr[1]]
    end
  end

  def fix_pid
    date26 = Time.parse('2017-11-26').to_i
    return if @date.to_i > date26

    logouts = StatsModels::GameUser.where("last_login_at is null")
    logouts.each do |rc|
      r = StatsModels::GameUser.where("sid like '%#{rc.sid}%' and last_login_at is not null").first
      if r 
        puts ">>>fix game users: #{rc.sid} #{rc.active_secs} "
        r.last_logout_at = rc.last_logout_at
        r.active_secs = rc.active_secs
        r.total_active_secs = rc.total_active_secs
        r.active_days = rc.active_days
        r.save
      end
    end
    StatsModels::GameUser.where("last_login_at is null").destroy_all

    StatsModels::GameAccount.where("active_secs = 0").destroy_all
  end


end
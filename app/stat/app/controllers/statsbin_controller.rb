require_relative 'stats_req'

class StatsbinController < ApplicationController

  def _workable
    rc = StatsModels::SysFlags.where(:flag => 'today_gen_task').first_or_initialize
    return false if rc.nil?
    return true if rc.value == 'idle'
    return false
  end

  def _set_working
    rc = StatsModels::SysFlags.where(:flag => 'today_gen_task').first_or_initialize
    rc.value = 'working'
    rc.save
    puts ">>>>set gen today stats working!!!"
  end

  def do_gen_today_stats
    return ng('verify fail') if !check_session
    if _workable 
      _set_working 
      # StatsHelper.gen_stats
      begin
      t = Thread.new do
        date = Time.now.to_date
        env = Rails.env
        cmd = "/usr/local/rs/app/stat/bin/stat regen --env=#{env} --date=#{date.strftime('%Y-%m-%d')} &"
        puts ">>>cmd:#{cmd}"
        system(cmd)
      end
      rescue
        p $! 
      end
      sendok()
    else
      sendc({'success' => 'ok', 'working' => true});
    end
  end

  def do_check_today_gen
    return ng('verify fail') if !check_session
    complete = _workable 
    sendc({'success' => 'ok', 'complete' => complete});
  end

end
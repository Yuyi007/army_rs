require_relative 'stats_req'

class LossController < ApplicationController
  include EnumLevel

  def get_loss_consume_report
  	return ng('verify fail') if !check_session

  	days = params[:days]
  	zone_id = params[:zone_id]
  	cost_type = params[:cost_type]
  	return ng('invalid args') if zone_id.nil? || days.nil? || cost_type.nil?

  	data = {}
  	today = Time.now.to_date
  	last_day = today - days.to_i

    sql = %Q{
      select c.*, u.level
      from user_consume as c left join zone_users as u on c.pid = u.sid
      where c.zone_id = #{zone_id} and u.last_login_at < '#{last_day}';
    }
  	rcs = execSql(sql)
    if !rcs.nil?
      rcs.each do |rc|
      	pid = rc.pid
        sys_name = rc.sys_name
      	data[sys_name] ||= empty
      	d = data[sys_name]
 			  level = rc.level
      	level_rgn = 10
	      if level <= 20
	        level_rgn = (level.to_f/10).ceil*10
	      else
	        level_rgn = (level.to_f/5).ceil*5
	      end

        sd = d[level_rgn.to_s]
      	sd[:num] += rc.consume
        sd[:players] += 1
      end
  	end

  	res = {'success' => 'ok'}
    # puts ">>>>data:#{data}"
    res['res'] = data
    sendc(res)
  end

  def get_loss_recharge_report
  	return ng('verify fail') if !check_session

    days = params[:days]
    zone_id = params[:zone_id]
    return ng('invalid args') if zone_id.nil? || days.nil?

    data = {}
    today = Time.now.to_date
    last_day = today - days.to_i
    sql = %Q{
      select r.*, u.level
      from recharge_record as r left join zone_users as u on r.pid = u.sid
      where r.zone_id = #{zone_id} and u.last_login_at < '#{last_day}';
    }
    rcs = execSql(sql)
    if !rcs.nil?
      rcs.each do |rc|
        pid = rc.pid
        goods = rc.goods
        data[goods] ||= empty
        d = data[goods]
        level_rgn = lv_rgn(rc.level)
        sd = d[level_rgn.to_s]
        sd[:num] += rc.num
        sd[:players] += 1
      end
    end

    res = {'success' => 'ok'}
    # puts ">>>>data:#{data}"
    res['res'] = data
    sendc(res)
  end

  def get_loss_report
    return ng('verify fail') if !check_session
    days = params[:days]
    zone_id = params[:zone_id]
    kind = params[:kind]
    sdk = params[:sdk]
    platform = params[:platform]
    #kind support: chief_level main_quest main_quest_campaign 
    return ng('invalid args') if zone_id.nil? || days.nil? || kind.nil? || sdk.nil? || platform.nil?

    cond_sdk = 'and true'
    cond_platform = 'and true'
    cond_zone = 'and true'
    cond_sdk = "and u.sdk = '#{sdk}'" if sdk != 'all' 
    cond_platform = "and u.platform = '#{platform}'" if platform != 'all'
    cond_zone = "and u.zone_id = #{zone_id}" if zone_id.to_i != 0

    today = Time.now.to_date
    last_day = today - days.to_i
    sql = %Q{
      select r.*
      from player_record as r left join zone_users as u on r.pid = u.sid
      where r.kind = '#{kind}' and u.last_login_at < '#{last_day}' #{cond_zone} #{cond_sdk} #{cond_platform};
    }
    rcs = execSql(sql)

    data = {}
    if !rcs.nil?
      rcs.each do |rc|
        key = rc.data.to_s
        data[key] ||= 0
        data[key] += 1
      end
    end

    arr = []
    data.each do |k, v|
      arr << {:kind => k, :players => v}
    end

    res = {'success' => 'ok'}
    res['res'] = arr
    sendc(res)
  end


end
require_relative 'stats_req'
class RealtimestatsController < ApplicationController
  include RsRails

  def get_new_user_report
    return ng('verify fail') if !check_session
    zone_id = params[:zone_id]
    return ng('invalid args') if zone_id.nil?

    rcs = StatsDB.get_new_user_report(zone_id.to_i)
    sendc({'success' => 'fail', 'reason' => 'empty'}) if !rcs
    ret = []
    rcs.map do |rc|
      ret << JSON.parse(rc)
    end
    sendc({'success' => 'ok', 'res' => ret})
  end

  def get_active_user_report
    return ng('verify fail') if !check_session
    zone_id = params[:zone_id]
    return ng('invalid args') if zone_id.nil?

    rcs = StatsDB.get_active_report(zone_id.to_i)
    sendc({'success' => 'fail', 'reason' => 'empty'}) if !rcs

    ret = []
    rcs.map do |rc|
      ret << JSON.parse(rc)
    end

    sendc({'success' => 'ok', 'res' => ret})
  end

  def get_max_online_report
    return ng('verify fail') if !check_session
    zone_id = params[:zone_id]
    return ng('invalid args') if zone_id.nil?

    rcs = StatsDB.get_max_online_report(zone_id.to_i)
    sendc({'success' => 'fail', 'reason' => 'empty'}) if !rcs

    ret = []
    rcs.map do |rc|
      ret << JSON.parse(rc)
    end

    sendc({'success' => 'ok', 'res' => ret})
  end

  def get_ave_online_report
     return ng('verify fail') if !check_session
    zone_id = params[:zone_id]
    return ng('invalid args') if zone_id.nil?

    rcs = StatsDB.get_ave_online_report(zone_id.to_i)
    sendc({'success' => 'fail', 'reason' => 'empty'}) if !rcs

    ret = []
    rcs.map do |rc|
      ret << JSON.parse(rc)
    end
    # puts ">>>>>ret:#{ret}"
    sendc({'success' => 'ok', 'res' => ret})
  end
end
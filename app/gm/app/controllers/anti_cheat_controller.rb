
require 'will_paginate/array'

class AntiCheatController < ApplicationController

  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin
    allow :admin, :p0, :p1, :p2, :p3, :p4 => [ :index, :search_cheater, :search_monitor ]
  end

  PER_PAGE = 30

  def search_monitor
    pid = params[:pid]
    monitors = []

    if pid and pid != '' then
      time = AntiCheatDb.monitor_time(pid)
      logger.info "pid=#{pid} time=#{time}"
      if time then
        monitors << make_monitor(pid, time)
      end
    else
      time_s = TimeHelper.parse_date_time(params[:time_s]).to_i
      time_e = TimeHelper.parse_date_time(params[:time_e]).to_i
      time_e = Time.now.to_i if time_e <= 0
      per_page = params[:per_page].to_i
      per_page = PER_PAGE if per_page <= 0
      page = params[:page].to_i
      page = 1 if page <= 0
      offset = 0
      count = 99_999
      logger.info "time_s=#{time_s} time_e=#{time_e} per_page=#{per_page} page=#{page} offset=#{offset} count=#{count}"

      list = AntiCheatDb.recent_monitors(time_s, time_e, offset, count, true)
      if list then
        list.each do |item|
          monitors << make_monitor(item[0], item[1])
        end
      end
    end

    @monitors = monitors.paginate(:page => page, :per_page => per_page)
  end

  def add_monitor
    pid = params[:pid]

    if pid
      res = AntiCheatDb.add_monitor(pid)

      current_user.site_user_records.create(
        :action => 'add_cheat_monitor',
        :success => res,
        :param1 => pid,
      )

      if res
        flash[:notice] = "Monitor added!"
      else
        flash[:error] = "Something wrong!"
      end
    end

    redirect_to search_monitor_url
  end

  def del_monitor
    pid = params[:pid]

    if pid
      res = AntiCheatDb.remove_monitor(pid)

      current_user.site_user_records.create(
        :action => 'remove_cheat_monitor',
        :success => res,
        :param1 => pid,
      )

      if res
        flash[:notice] = "Monitor deleted!"
      else
        flash[:error] = "Something wrong!"
      end
    end

    redirect_to search_monitor_url
  end

  def clear_monitors
    res = AntiCheatDb.clear_monitors()

    current_user.site_user_records.create(
      :action => 'clear_cheat_monitors',
      :success => res,
    )

    if res
      flash[:notice] = "Monitors cleared!"
    else
      flash[:error] = "Something wrong!"
    end

    redirect_to search_monitor_url
  end

  def index
    params[:page] ||= 1
    params[:per_page] ||= cookies[:cheater_per_page].to_i
    params[:per_page] = PER_PAGE if params[:per_page] <= 0
    params[:time_s] ||= TimeHelper.gen_date_time(Time.now - 3600 * 1)
    params[:time_e] ||= TimeHelper.gen_date_time(Time.now)

    @cheaters = do_search_cheater(params)

    render :search_cheater
  end

  def search_cheater
    if params[:per_page]
      cookies[:cheater_per_page] = params[:per_page].to_i
    else
      params[:per_page] = cookies[:cheater_per_page]
    end

    @cheaters = do_search_cheater(params)
  end

  def do_search_cheater(params)
    pid = params[:pid]
    cheaters = []

    if pid and pid != '' then
      time = AntiCheatDb.cheater_time(pid)
      logger.info "pid=#{pid} time=#{time}"
      if time then
        cheaters << make_cheater(pid, time)
      end
    else
      time_s = TimeHelper.parse_date_time(params[:time_s]).to_i
      time_e = TimeHelper.parse_date_time(params[:time_e]).to_i
      time_e = Time.now.to_i if time_e <= 0
      per_page = params[:per_page].to_i
      per_page = 10 if per_page <= 0
      page = params[:page].to_i
      page = 1 if page <= 0
      offset = 0
      count = 99_999
      logger.info "time_s=#{time_s} time_e=#{time_e} per_page=#{per_page} page=#{page} offset=#{offset} count=#{count}"

      list = AntiCheatDb.recent_cheaters(time_s, time_e, offset, count, true)
      logger.info "list=#{list}"
      if list then
        list.each do |item|
          cheaters << make_cheater(item[0], item[1])
        end
      end
    end

    cheaters.paginate(:page => page, :per_page => per_page)
  end

  def add_cheater
    pid = params[:pid]

    if pid
      res = AntiCheatDb.add_cheater(pid)

      current_user.site_user_records.create(
        :action => 'add_cheater',
        :success => res,
        :param1 => pid,
      )

      if res
        flash[:notice] = "Cheater added!"
      else
        flash[:error] = "Something wrong!"
      end
    end

    redirect_to search_cheater_url
  end

  def del_cheater
    pid = params[:pid]

    if pid
      res = AntiCheatDb.remove_cheater(pid)

      current_user.site_user_records.create(
        :action => 'remove_cheater',
        :success => res,
        :param1 => pid,
      )

      if res
        flash[:notice] = "Cheater deleted!"
      else
        flash[:error] = "Something wrong!"
      end
    end

    redirect_to search_cheater_url
  end

  def clear_cheaters
    res = AntiCheatDb.clear_cheaters()

    current_user.site_user_records.create(
      :action => 'clear_cheaters',
      :success => res,
    )

    if res
      flash[:notice] = "Cheaters cleared!"
    else
      flash[:error] = "Something wrong!"
    end

    redirect_to search_cheater_url
  end

  def make_monitor(pid, time)
    {
      'id' => pid,
      'time' => time,
    }
  end

  def make_cheater(pid, time)
    zone, cid, iid = Helper.decode_player_id(pid)
    {
      'id' => cid,
      'zone' => zone,
      'pid' => pid,
      'time' => time,
    }
  end

end

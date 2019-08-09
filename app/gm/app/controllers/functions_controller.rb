# events_controller.rb

class FunctionsController < ApplicationController

  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1
  end



  def index
  end

  def isCantLossOpen
    zone = params[:zone].to_i
    opened = RsRails.isCantLossEventOpen(zone)
    render :json => { 'opened' => opened }
  end

  def setCantLossOpen
    zone = params[:zone].to_i
    open = params[:cantlossEnabled] or false
    RsRails.setCantLossEventOpen(zone, open)

    current_user.site_user_records.create(
      :action => 'update_event',
      :success => true,
      :zone => zone,
      :param1 => 'cantloss',
      :param2 => open,
    )

    render :json => { 'success' => true }
  end

  def isArenaBonusOpen
    zone = params[:zone].to_i
    opened = RsRails.isArenaBonusEventOpen(zone)
    render :json => { 'opened' => opened }
  end

  def setArenaBonusOpen
    zone = params[:zone].to_i
    open = params[:arenabonusEnabled] or false
    RsRails.setArenaBonusEventOpen(zone, open)

    current_user.site_user_records.create(
      :action => 'update_event',
      :success => true,
      :zone => zone,
      :param1 => 'arenabonus',
      :param2 => open,
    )

    render :json => { 'success' => true }
  end

  def isYunbiaoOpen
    ios, android = RsRails.isYunbiaoEventOpen()
    render :json => { 'ios' => ios, 'android' => android }
  end

  def setYunbiaoOpen
    ios = params[:ybIOSEnabled] or false
    android = params[:ybAndroidEnabled] or false
    RsRails.setYunbiaoEventOpen(ios, android)

    current_user.site_user_records.create(
      :action => 'update_event',
      :success => true,
      :zone => 999,
      :param1 => 'yunbiao',
      :param2 => ios,
    )

    render :json => { 'success' => true }
  end

end
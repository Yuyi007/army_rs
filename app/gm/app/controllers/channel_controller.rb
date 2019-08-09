# channel_controller.rb

class ChannelController < ApplicationController

  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2, :p3, :p4
  end



  def index
    @scheduleChats = RsRails.get_schedule_chats.sort {|a, b| b.start_time <=> a.start_time}
  end

  def notice
    text = params[:noticeText]
    zone = params[:zone]
    success = RsRails.publishNotice(text, zone)

    current_user.site_user_records.create(
      :action => 'send_notice',
      :success => success,
      :zone => zone,
      :param2 => text,
    )

    render :json => { 'success' => success }
  end

  def chat
    name = params[:chatName]
    text = params[:chatText]
    zone = params[:zone]
    time = params[:time].to_i
    color = params[:input_color_1]
    all_zone = params[:all_zone]
    # logger.debug "check all zone: #{all_zone}"
    zone = 0 if all_zone
    # logger.debug "check fainl zone: #{zone}"

    success = true
    # current_user.site_user_records.create(
    #   :action => 'send_chat',
    #   :success => success,
    #   :zone => zone,
    #   :param1 => name,
    #   :param2 => text,
    # )
    ChannelHelper.send_system_message_with_zone(nil, zone, text, time, color)

    render :json => { 'success' => success }
  end

  def add_chat_schedule
    success, reason = RsRails.add_schedule_chat(params)
    if success 
      @scheduleChats = RsRails.get_schedule_chats
      redirect_to :action => "index"
    else
      render :json => { 'success' => false, 'reason' => reason }
    end
  end

  def remove_chat_schedule
    RsRails.remove_schedule_chat(params)
    @scheduleChats = RsRails.get_schedule_chats
    render :json => { 'success' => true }
  end

end
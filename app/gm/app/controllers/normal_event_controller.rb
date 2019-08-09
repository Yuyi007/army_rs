# normal_event_controller.rb

class NormalEventController < ApplicationController
  # include Cacheable
  # include Configurable

  include RsRails

  layout 'main'

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2, :p3
  end

  protect_from_forgery

  # include ConfigHelper
  # include Eventable


  def list
    @event_list = NormalEventDb.all_to_hash_list()
    @event_list.each do |o|
      o.prepare_time = parse_time_simple(o.prepare_time)
      o.end_time = parse_time_simple(o.end_time)
      o.start_time = parse_time_simple(o.start_time)
      o.finish_time = parse_time_simple(o.finish_time)
    end
  end

  def edit
    id = params[:id].to_s
    @event = NormalEventDb.get_event_hash(id)
    parse_to_display(@event)
  end

  def update
    o = params[:normal_event]
    parse_to_data(o)

    suc, reason = NormalEventDb.validate_update?(o)

    if suc
      flash[:success] = 'saved'
      NormalEventDb.update_event(o)
      redirect_to normal_event_list_url
    else
      flash[:error] = reason
      redirect_to :back
    end
  end

  def new
    if @event.nil?
      now = Time.now.to_i
      @event = {}
      @event.zones = 'all'
      GameConfig.evt_total_credit.each do|tid, data|
        @event.type = tid
        break
      end
      @event.prepare_time = now
      @event.start_time = now + 60
      @event.end_time = now + 120
      @event.finish_time = now + 180
    end
    parse_to_display(@event)
  end

  def parse_to_data(o)
    o.prepare_time = parse_time_simple(o.prepare_time)
    o.end_time = parse_time_simple(o.end_time)
    o.start_time = parse_time_simple(o.start_time)
    o.finish_time = parse_time_simple(o.finish_time)
    o.zones = parse_zones_to_data(o.zones)
    o
  end

  def create
    o = params[:normal_event]
    parse_to_data(o)
    suc, reason = NormalEventDb.validate_opts?(o)

    if suc
      flash[:success] = 'saved'
      NormalEventDb.create_event(o)
      redirect_to normal_event_list_url
    else
      flash[:error] = reason
      redirect_to :back
    end
  end

  def parse_to_display(o)
    o.prepare_time = parse_time_simple(o.prepare_time)
    o.end_time = parse_time_simple(o.end_time)
    o.start_time = parse_time_simple(o.start_time)
    o.finish_time = parse_time_simple(o.finish_time)
    o
  end

  def parse_zones_to_data(zones)
    if zones == 'all' then
      zones
    else
      zones.split(',').map{|x| x.strip.to_i}
    end
  end

  def delete
    id = params[:id].to_s
    NormalEventDb.delete_event(id)
    redirect_to normal_event_list_url
  end
end

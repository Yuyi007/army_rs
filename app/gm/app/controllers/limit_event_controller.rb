class LimitEventController < ApplicationController
  include RsRails
  include Cacheable
  include Configurable

  layout 'main'

  protect_from_forgery
  include Eventable

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2, :p3
  end

  def list
    @event_list = LimitEvent.all.to_a.to_data
    @event_list.each do |o|
      o.prepare_time = parse_time_simple(o.prepare_time)
      o.end_time = parse_time_simple(o.end_time)
      o.start_time = parse_time_simple(o.start_time)
      o.finish_time = parse_time_simple(o.finish_time)
    end
  end

  def edit
    id = params[:id].to_s
    @limit_event = LimitEvent[id].to_data
    parse_to_display(@limit_event)
  end

  def update
    o = params[:limit_event]
    parse_to_data(o)

    suc, reason = LimitEvent.validate_update?(o)

    if suc
      flash[:success] = 'saved'
      LimitEvent.update_limit_event(o)
      redirect_to limit_event_list_url
    else
      flash[:error] = reason
      redirect_to :back
    end
  end

  def new
    if @limit_event.nil?
      @limit_event = LimitEvent.new.to_data
      now = Time.now.to_i
      @limit_event.prepare_time = now
      @limit_event.start_time = now + 60
      @limit_event.end_time = now + 120
      @limit_event.finish_time = now + 180
      @limit_event.donate_max = 1000
    end
    parse_to_display(@limit_event)
  end

  def parse_to_data(o)
    o.prepare_time = parse_time_simple(o.prepare_time)
    o.end_time = parse_time_simple(o.end_time)
    o.start_time = parse_time_simple(o.start_time)
    o.finish_time = parse_time_simple(o.finish_time)
    o
  end

  def create
    o = params[:limit_event]
    o.create = true
    parse_to_data(o)
    suc, reason = LimitEvent.validate_opts?(o)

    if suc
      flash[:success] = 'saved'
      LimitEvent.create_limit_event(o)
      redirect_to limit_event_list_url
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

  def delete
    id = params[:id].to_s
    LimitEvent.delete_limit_event(id)
    redirect_to limit_event_list_url
  end
end

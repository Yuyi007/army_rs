# events_controller.rb

class EventsZonemarketController < EventsController
  #layout 'main'
  layout 'events'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1
  end

  set_tab :zone_market

  include Eventable
  gen_controller_event :zonemarket


  def list
    @active = "zonemarket_link"
    @zone = params[:zone] || 1
    @list = proxy.get_zonemarket_events(@zone)
    @list.each {|n| parse_time(n, n) }
  end

  def new
    zone = params[:zone]
    @zonemarket = {'zone' => zone}
  end

  def edit
    @id = params[:id]
    @zone = params[:zone]
    @zonemarket = proxy.get_zonemarket_event(@id)
    parse_time(@zonemarket, @zonemarket)
  end

  def create_zonemarket
    data = params[:zonemarket]
    zone = params[:zone]
    parse_time(data, data)
    res, data = proxy.create_zonemarket_event(data.zone, data, cur_user)
    if res['success']
      redirect_to :action => 'edit', :zone => zone, :id => data.id
    else
      render :json => res
    end
  end

  def delete_zonemarket
    user = cur_user
    zone = params[:zone].to_i
    id = params[:id].to_i
    res = proxy.delete_zonemarket_event(id, user)
    if res['success']
      current_user.site_user_records.create(
        :action => 'delete_event',
        :success => true,
        :zone => zone,
        :param1 => 'zonemarket',
        :param2 => id,
      )
      redirect_to :action => 'list', :zone => zone
    else
      render :json => res
    end
  end

  def update
    user = cur_user
    data = params[:zonemarket]
    zone = params[:zone]
    parse_time(data, data)

    res = proxy.save_zonemarket_event(zone, data, user)
    if res['success']
      redirect_to :action => 'edit', :zone => zone, :id => data.id
    else
      render :json => res
    end
  end

end

# events_controller.rb

class EventsXuezhanController < EventsController
  #layout 'main'
  layout 'events'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1
  end

  set_tab :xuezhan_event

  include Eventable
  gen_controller_event :xuezhan

  def index
  end

  def list
    @active = "xuezhan_link"
    @auth = curAuth()
    @zone = params[:zone] || 1
    @list = proxy.get_xuezhan_events(@zone)
    @list.each {|n| parse_time(n, n) }
  end

  def new
    @active = "xuezhan_link"
    @zone = params[:zone]
    @xuezhan = {'zone' => @zone}
  end

  def edit
    @active = "xuezhan_link"
    @zone = params[:zone]
    @id = params[:id]
    @xuezhan = proxy.get_xuezhan_event(@id)
    parse_time(@xuezhan, @xuezhan)
  end

  def create_xuezhan
    data = params[:xuezhan]
    zone = params[:zone]
    parse_time(data, data)
    res, data = proxy.create_xuezhan_event(data.zone, data, cur_user)
    if res.success
      flash[:success] = 'created'
      redirect_to :action => 'edit', :zone => zone, :id => data.id
    else
      flash[:error] = "creation failed! #{res.reason}"
      redirect_to :action => :new, :zone => zone
    end
  end

  def update
    user = cur_user
    data = params[:xuezhan]
    zone = params[:zone]
    parse_time(data, data)

    res = proxy.save_xuezhan_event(zone, data, user)
    if res.success == true
      flash[:success] = 'saved'
    else
      flash[:error] = "save failed #{res.reason}"
    end

    redirect_to :back
  end

   def delete_xuezhan
    user = cur_user
    zone = params[:zone].to_i
    id = params[:id].to_i
    res = proxy.delete_xuezhan_event(id, user)
    if res['success']
      current_user.site_user_records.create(
        :action => 'delete_event',
        :success => true,
        :zone => zone,
        :param1 => 'xuezhan',
        :param2 => id,
      )
      redirect_to :action => 'list', :zone => zone
    else
      flash[:error] = "delete failed #{res.reason}"
      redirect_to :back
    end
  end


end
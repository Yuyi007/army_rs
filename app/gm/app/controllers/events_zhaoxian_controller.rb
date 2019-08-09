class EventsZhaoxianController < EventsController
  layout 'events'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1
  end

  set_tab :zhaoxian_event
  include Eventable

  gen_controller_event :zhaoxian

  def index
    @active = "zhaoxian_link"
    @eventType = 'zhaoxian'
    @grantInfo = proxy.getGrantFlag(@eventType)
    if @grantInfo
      @grantInfo['lastAlertTime'] = TimeHelper.gen_date_time(Time.at(@grantInfo['lastAlertTime'])) if @grantInfo['lastAlertTime']
    end
    @auth = curAuth()
  end

  def list
    @active = "zhaoxian_link"
    @zone = params[:zone] || 1
    @list = proxy.get_zhaoxian_events(@zone)
    @list.each {|n| parse_time(n, n) }
  end

  def new
    zone = params[:zone]
    @zhaoxian = {'zone' => zone}
  end

  def edit
    @id = params[:id]
    @zone = params[:zone]
    @zhaoxian = proxy.get_zhaoxian_event(@id)
    parse_time(@zhaoxian, @zhaoxian)
  end

  def create_zhaoxian
    data = params[:zhaoxian]
    zone = params[:zone]
    parse_time(data, data)
    res, data = proxy.create_zhaoxian_event(data.zone, data, cur_user)
    if res['success']
      flash[:success] = 'created'
      redirect_to :action => 'edit', :zone => zone, :id => data.id
    else
      flash[:error] = "creation failed! #{res.reason}"
      redirect_to :back
    end
  end

  def delete_zhaoxian
    user = cur_user
    zone = params[:zone].to_i
    id = params[:id].to_i
    res = proxy.delete_zhaoxian_event(id, user)
    if res['success']
      current_user.site_user_records.create(
        :action => 'delete_event',
        :success => true,
        :zone => zone,
        :param1 => 'zhaoxian',
        :param2 => id,
      )
      redirect_to :action => 'list', :zone => zone
    else
      flash[:error] = "delete failed! #{res.reason}"
      redirect_to :back
    end
  end


  def update
    user = cur_user
    data = params[:zhaoxian]
    zone = params[:zone]
    parse_time(data, data)

    res = proxy.save_zhaoxian_event(zone, data, user)
    if res['success']
      flash[:success] = 'saved'
    else
      flash[:error] = "save failed #{res.reason}"
    end

    redirect_to :back
  end
end

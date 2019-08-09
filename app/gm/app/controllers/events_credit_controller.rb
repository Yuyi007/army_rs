class EventsCreditController < EventsController
  layout 'events'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1
  end

  set_tab :credit_event
  include Eventable

  gen_controller_event :credit

  def index
    @active = "credit_link"
    @eventType = 'credit'
    @grantInfo = proxy.getGrantFlag(@eventType)
    if @grantInfo
      @grantInfo['lastAlertTime'] = TimeHelper.gen_date_time(Time.at(@grantInfo['lastAlertTime'])) if @grantInfo['lastAlertTime']
    end
    @auth = curAuth()
  end

  def list
    @active = "credit_link"
    @zone = params[:zone] || 1
    @list = proxy.get_credit_events(@zone)
    @list.each {|n| parse_time(n, n) }
  end

  def new
    @active = "credit_link"
    zone = params[:zone]
    @credit = {'zone' => zone}
  end

  def edit
    @id = params[:id]
    @zone = params[:zone]
    @credit = proxy.get_credit_event(@id)
    logger.debug("===========================> " + @credit.to_s)
    parse_time(@credit, @credit)
  end

  def ranking
    @id = params[:id]
    @list = proxy.get_credit_ranking(@id)
  end

  def create_credit
    data = params[:credit]
    zone = params[:zone]
    parse_time(data, data)
    data.rewards = data.rewards.map {|k, v| v }
    res, data = proxy.create_credit_event(data.zone, data, cur_user)
    if res['success']
      flash[:success] = 'created'
      redirect_to :action => 'edit', :zone => zone, :id => data.id
    else
      flash[:error] = "creation failed! #{res.reason}"
      redirect_to :back
    end
  end

  def delete_credit
    user = cur_user
    zone = params[:zone].to_i
    id = params[:id].to_i
    res = proxy.delete_credit_event(id, user)
    if res['success']
      current_user.site_user_records.create(
        :action => 'delete_event',
        :success => true,
        :zone => zone,
        :param1 => 'credit',
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
    data = params[:credit]
    zone = params[:zone]
    parse_time(data, data)
    data.rewards = data.rewards.map {|k, v| v }
    res = proxy.save_credit_event(zone, data, user)
    if res['success']
      flash[:success] = 'saved'
    else
      flash[:error] = "save failed #{res.reason}"
    end

    redirect_to :back
  end
end

class EventsCampaignExpController < EventsController

  include RsRails

  layout 'events'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1
  end

  set_tab :campaign_exp_event
  include Eventable

  gen_controller_event :campaign_exp

  def index
    @active = "campaign_exp_link"
    @eventType = 'campaign_exp'
    @grantInfo = proxy.getGrantFlag(@eventType)
    if @grantInfo
      @grantInfo['lastAlertTime'] = TimeHelper.gen_date_time(Time.at(@grantInfo['lastAlertTime'])) if @grantInfo['lastAlertTime']
    end
    @auth = curAuth()
  end

  def list
    @active = "campaign_exp_link"
    @zone = params[:zone] || 1
    @list = proxy.get_campaign_exp_events(@zone)
    @list.each {|n| parse_time(n, n) }
  end

  def new
    zone = params[:zone]
    @campaign_exp = {'zone' => zone}
  end

  def edit
    @id = params[:id]
    @zone = params[:zone]
    @campaign_exp = proxy.get_campaign_exp_event(@id)
    parse_time(@campaign_exp, @campaign_exp)
  end

  def create_campaign_exp
    data = params[:campaign_exp]
    zone = params[:zone]
    parse_time(data, data)
    res, data = proxy.create_campaign_exp_event(data.zone, data, cur_user)
    if res['success']
      flash[:success] = 'created'
      redirect_to :action => 'edit', :zone => zone, :id => data.id
    else
      flash[:error] = "creation failed! #{res.reason}"
      redirect_to :back
    end
  end

  def delete_campaign_exp
    user = cur_user
    zone = params[:zone].to_i
    id = params[:id].to_i
    res = proxy.delete_campaign_exp_event(id, user)
    if res['success']
      current_user.site_user_records.create(
        :action => 'delete_event',
        :success => true,
        :zone => zone,
        :param1 => 'campaign_exp',
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
    data = params[:campaign_exp]
    zone = params[:zone]
    parse_time(data, data)

    res = proxy.save_campaign_exp_event(zone, data, user)
    if res['success']
      flash[:success] = 'saved'
    else
      flash[:error] = "save failed #{res.reason}"
    end

    redirect_to :back
  end
end

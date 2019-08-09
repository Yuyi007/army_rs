# events_controller.rb

class EventsCampaigndropController < EventsController

  include RsRails

  #layout 'main'
  layout 'events'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1
  end

  set_tab :campaign_drop_event

  include Eventable

  gen_controller_event :campaign

  def index
  end

  def list
    @active = "campaigndrop_link"
    @eventType = 'CampaignDrop'
    @grantInfo = RsRails.getGrantFlag(@eventType)
    if @grantInfo
      @grantInfo['lastAlertTime'] = TimeHelper.gen_date_time(Time.at(@grantInfo['lastAlertTime'])) if @grantInfo['lastAlertTime']
    end
    @auth = curAuth()
  end

  def new
    @active = "campaigndrop_link"
  end

  def edit
    @active = "campaigndrop_link"
    @zone = params[:zone]
    @id = params[:id]
  end

end
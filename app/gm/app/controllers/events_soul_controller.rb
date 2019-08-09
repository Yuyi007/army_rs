# events_controller.rb

class EventsSoulController < EventsController
  #layout 'main'
  layout 'events'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1
  end

  set_tab :pick_hero_send_soul

  include Eventable

  gen_controller_event :soul

  def index
    @active = "soul_link"
    @eventType = 'Soul'
    @grantInfo = RsRails.getGrantFlag(@eventType)
    if @grantInfo
      @grantInfo['lastAlertTime'] = TimeHelper.gen_date_time(Time.at(@grantInfo['lastAlertTime'])) if @grantInfo['lastAlertTime']
    end
    @auth = curAuth()
  end

  def list
    @active = "soul_link"
  end

  def edit
    @active = "soul_link"
    @zone = params[:zone]
    @id = params[:id]
  end

  def new
    @active = 'soul_link'
    @zone = params[:zone]
  end

end
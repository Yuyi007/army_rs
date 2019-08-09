# encoding: utf-8

class NotifAlertsController < ApplicationController

  include Statsable
  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :require_no_user, :only => [ :check_all ]
  before_filter :require_user, :only => [ :new, :create, :show, :edit, :update, :list, :index ]

  access_control do
    allow :admin, :p0
    allow all, :to => [ :check_all ]
  end

  def new
    @alert = NotifAlert.new
  end

  def create
    @alert = NotifAlert.new(params[:notif_alert])

    if @alert.save
      flash[:notice] = "Alert created!"
      current_user.site_user_records.create(
        :action => 'create_notif_alert',
        :success => true,
      )
      redirect_to list_notif_alerts_url
    else
      flash[:notice] = "There was a problem creating alert."
      render :action => :new
    end
  end

  def show
    @alert = NotifAlert.find(params[:id])
  end

  def edit
    @alert = NotifAlert.find(params[:id])
  end

  def update
    @alert = NotifAlert.find(params[:id])
    res = @alert.update_attributes(params[:notif_alert])

    current_user.site_user_records.create(
      :action => 'update_notif_alert',
      :success => res,
    )

    if res
      flash[:notice] = "Alert updated!"
      render :edit
    else
      flash[:error] = "Something wrong!"
      render :action => :edit
    end
  end

  def destroy
    @alert = NotifAlert.find(params[:id])
    res = @alert.destroy()

    current_user.site_user_records.create(
      :action => 'delete_notif_alert',
      :success => res,
    )

    if res
      flash[:notice] = "Alert deleted!"
      redirect_to list_notif_alerts_url
    else
      flash[:error] = "Something wrong!"
      redirect_to list_notif_alerts_url
    end
  end

  def list
    @alerts = NotifAlert.find(:all)
  end

  def index
    @alerts = NotifAlert.find(:all)
    render :list
  end

  def check_all
    @alerts = NotifAlert.find(:all)
    alert_count = 0
    @alerts.each do |alert|
      if check_alert(alert) then
        alert_count += 1
      end
    end
    render :json => { 'success' => true, 'alerts' => alert_count }
  end

  def check
    @alerts = NotifAlert.find(:all)
    alert = NotifAlert.find(params[:id])
    if check_alert(alert) then
      flash[:notice] = "There was an alert detected!"
    else
      flash[:notice] = "No alert"
    end
    render :list
  end

  private

  def check_alert(alert)
    # logger.info "alert=#{alert}"
    return false unless alert.enabled

    has_alert, text = false, nil
    case alert.name
    when 'online_warn'
      has_alert, text = check_alert_online_warn()
    else
      raise "unknown alert name #{alert.name}!"
    end

    if has_alert then
      logger.info "[ALERT] name=#{alert.name} text=#{text}"

      now = Time.now.to_i
      last_time = @@alert_time[alert.name]
      if last_time == nil or now - last_time > 5 then
        receivers = select_receivers(alert)
        receivers.each do |receiver|
          alert_notify(alert, receiver, text)
        end
        @@alert_time[alert.name] = now
      else
        logger.info "[ALERT] name=#{alert.name} alert time too close"
      end
    end

    return has_alert
  end

  @@alert_status = {}
  @@alert_time = {}

  def check_alert_online_warn()
    alert_zones = []
    num_open_zones = DynamicAppConfig.num_open_zones
    (1..num_open_zones).each do |zone|
      max_online = QueuingDb.get_max_online(zone)
      threshold = max_online * 0.95
      num_online = SessionManager.num_online(zone)
      if num_online > threshold then
        if not @@alert_status["online-#{zone}"]
          alert_zones << zone
          @@alert_status["online-#{zone}"] = true
        end
      else
        @@alert_status["online-#{zone}"] = nil
      end
    end

    if alert_zones.length > 0 then
      return true, "#{alert_zones}区在线人数已接近满"
    else
      return false
    end
  end

  def select_receivers(alert)
    if alert.receivers == nil or alert.receivers == ''
      NotifReceiver.find(:all)
    else
      ids = alert.receivers.split(',')
        .map { |id| id.strip.to_i }
        .reject { |id| id <= 0 }
      NotifReceiver.find(ids)
    end
  end

  def alert_notify(alert, receiver, text)
    if receiver.mobile =~ /^1\d\d\d\d\d\d\d\d\d\d$/
      TencentSms.send_single(receiver.mobile, "#{alert.name}警报 - #{text}")
    end
    if receiver.email =~ /^.+@.+$/
      NotifAlertMailer.simple_alert(receiver, alert.name, text).deliver
    end
  end

end

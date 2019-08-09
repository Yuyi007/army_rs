class MaintainanceController < ApplicationController

  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :require_user, :except => [ :status ]

  access_control do
    allow :admin
    allow all, :to => [ :status ]
  end

  @@locations = [ 'cn', 'tw' ]

  def index
    status = get_maintainance_status
    @maintainance_on = status.on
    @maintainance_start_at = TimeHelper.gen_date_time(Time.at(status.start_at.to_i))
    @maintainance_end_at = TimeHelper.gen_date_time(Time.at(status.end_at.to_i))
    @enable_loadtest = (!! status.enable_loadtest)
    #if status.ip_whitelist
    #  @ip_whitelist = status.ip_whitelist.join("\n")
    #else
    #  @ip_whitelist = ''
    #end
    if status.id_whitelist
      @id_whitelist = status.id_whitelist.join("\n")
    else
      @id_whitelist = ''
    end

    @sdk_whitelist = status.sdk_whitelist.join("\n")
  end

  def update
    status = MaintainanceStatus.new
    status.on = ! params[:maintainance_on].nil?
    status.start_at = TimeHelper.parse_date_time(params[:maintainance_start_at]).to_i
    status.end_at = TimeHelper.parse_date_time(params[:maintainance_end_at]).to_i
    #status.ip_whitelist = params[:ip_whitelist].split(/\s+/)
    status.id_whitelist = params[:id_whitelist].split(/\s+/).map { |id| id.to_i }
    status.sdk_whitelist = params[:sdk_whitelist].split(/\s+/)
    status.enable_loadtest = (params[:enable_loadtest] == 'on') or (params[:enable_loadtest] == true)

    success = set_maintainance_status(status)

    current_user.site_user_records.create(
      :action => 'update_maintainance',
      :success => success,
      :param1 => status.on,
      :param2 => "#{status.start_at}, #{status.end_at}, #{status.enable_loadtest}",
      :param3 => (status.id_whitelist + status.sdk_whitelist).join("\n"),
    )

    render :json => { 'success' => success }
  end

end

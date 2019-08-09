class ClientVersionController < ApplicationController

  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2
  end

  def index
    @editorVersion = get_client_version('editor', '')
    @iosVersion = get_client_version('ios', '')
    @androidVersion = get_client_version('android', '')
    @wp8Version = get_client_version('wp8', '')
  end

  def edit
    @platform = params[:platform]
    @sdk = params[:sdk]
    @clientVersion = get_client_version(@platform, @sdk)
  end

  def publish
    platform = params[:platform]
    sdk = params[:sdk]
    version = params[:version]

    success = set_client_version(platform, sdk, version)

    current_user.site_user_records.create(
      :action => 'publish_version',
      :success => success,
      :param1 => platform,
      :param2 => sdk,
      :param3 => version,
    )

    render :json => { 'success' => success }
  end

end

class QueuingSettingsController < ApplicationController

  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2
  end

  def index
    settings = DynamicAppConfig.get_queuing_settings

    if settings.id_whitelist
      @id_whitelist = settings.id_whitelist.join("\n")
    else
      @id_whitelist = ''
    end
  end

  def save
    settings = QueuingSettings.new

    settings.id_whitelist = params[:id_whitelist].split(/\s+/).map { |id| id.to_i }

    success = set_queuing_settings(settings)

    current_user.site_user_records.create(
      :action => 'save_queuing_settings',
      :success => success,
      :param1 => settings.id_whitelist.join("\n"),
      :param2 => '',
      :param3 => '',
    )

    render :json => { 'success' => success }
  end

  def delete
    success = set_queuing_settings(nil)

    current_user.site_user_records.create(
      :action => 'delete_queuing_settings',
      :success => success,
      :param1 => '',
      :param2 => '',
      :param3 => '',
    )

    render :json => { 'success' => success }
  end

end

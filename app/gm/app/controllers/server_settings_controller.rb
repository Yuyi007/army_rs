class ServerSettingsController < ApplicationController

  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2
  end

  def index
    @temp_dev_mode = AppConfig.dev_mode?

    gate_servers = self.gate_servers
    @server_settings = DynamicAppConfig.get_gate_server_settings

    sync_server_settings gate_servers, @server_settings
    @server_settings
  end

  def sync_server_settings gate_servers, server_settings
    logger.debug "sync_server_settings: server_settings=#{server_settings}"

    gate_servers.each do |server|
      name = server['name']
      setting_idx = server_settings.settings.find_index { |setting| setting.name == name }
      if setting_idx
        setting = server_settings.settings[setting_idx]
      else
        logger.info "sync_server_settings: add server #{server}"
        setting = GateServerSetting.new
        server_settings.settings.push setting
      end
      setting.name = name
      setting.addr = server['addr']
      setting.ext_addr = server['ext_addr']
    end

    server_settings.settings.delete_if do |setting|
      name = setting.name
      idx = gate_servers.find_index { |server| server['name'] == name }
      if not idx
        logger.info "sync_server_settings: delete server idx=#{idx} name=#{name}"
      end
      (not idx)
    end

    # logger.debug "sync_server_settings: server list #{server_settings.settings}"
  end

  def fix_server_settings new_settings
    server_settings = GateServerSettings.new
    num_open_zones = DynamicAppConfig.get_num_open_zones

    # build server settings
    new_settings.each do |server|
      setting = GateServerSetting.new
      server_settings.settings.push setting

      if server.is_a? GateServerSetting then
        server_name = server.name
        server_addr = server.addr
        server_ext_addr = server.ext_addr
        main_sync_interval = server.main_sync_interval
        combat_sync_interval = server.combat_sync_interval
      else
        server_name = server['name']
        server_addr = server['addr']
        server_ext_addr = server['ext_addr']
        main_sync_interval = server['main_sync_interval']
        combat_sync_interval = server['combat_sync_interval']
      end

      setting.name = server_name
      setting.addr = server_addr
      setting.ext_addr = server_ext_addr
      setting.main_sync_interval = main_sync_interval.to_i
      setting.combat_sync_interval = combat_sync_interval.to_i
    end

    logger.info "fix_server_settings: #{server_settings.to_json}"
    server_settings
  end

  def save
    new_settings = ActiveSupport::JSON.decode(params[:settings])
    server_settings = fix_server_settings(new_settings)
    server_settings.disable_voice_chat = (params[:disable_voice_chat] == 'true' or params[:disable_voice_chat] == true)
    server_settings.disable_advt_filtering = (params[:disable_advt_filtering] == 'true' or params[:disable_advt_filtering] == true)
    success = self.set_gate_server_settings(server_settings)

    current_user.site_user_records.create(
      :action => 'save_server_settings',
      :success => success,
      :param1 => "",
      :param2 => "",
      :param3 => "",
    )

    render :json => { 'success' => success }
  end

  def delete
    success = self.set_gate_server_settings(nil)

    current_user.site_user_records.create(
      :action => 'delete_server_settings',
      :success => success,
      :param1 => "",
      :param2 => "",
      :param3 => "",
    )

    render :json => { 'success' => success }
  end

  def reload_server_list
    success = self.gm_reload_server_list

    current_user.site_user_records.create(
      :action => 'reload_server_list',
      :success => success,
      :param1 => "",
      :param2 => "",
      :param3 => "",
    )

    render :json => { 'success' => success }
  end

  def garbage_collect_all
    success = self.gm_garbage_collect_all

    current_user.site_user_records.create(
      :action => 'garbage_collect_all',
      :success => success,
      :param1 => "",
      :param2 => "",
      :param3 => "",
    )

    render :json => { 'success' => success }
  end

  def dev_mode
    dev_mode = params[:dev_mode]
    success = self.set_dev_mode(dev_mode)

    current_user.site_user_records.create(
      :action => 'set_dev_mode',
      :success => success,
      :param1 => "#{dev_mode}",
      :param2 => "",
      :param3 => "",
    )

    render :json => { 'success' => success }
  end

end
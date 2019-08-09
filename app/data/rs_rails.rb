# rs_rails.rb
# Extern helpers usable to rails applications
#

require 'rs'
require 'rbtrace'
# require 'elasticsearch/model'
require "base64"

module RsRails

  @@initialized = false unless (defined? @@initialized)
  @@rpc_thread = nil unless (defined? @@rpc_thread)

  def self.init
    if @@initialized
      # Rails.logger.info "RsRails: pid=#{Process.pid} already inited."
      # RsRails.ensure_worker_threads
      return false
    end

    @@initialized = true

    Rails.logger.info "RsRails[#{Process.pid}]: initing..."
    Rails.logger.info "RsRails[#{Process.pid}]: now=#{Time.now}"

    game_root = File.expand_path(File.join(Rails.root, '..', '..'))
    game_env = Rails.env
    game_env = ENV['USER'] if game_env == 'development'
    rails_port = Rack::Server.new.options[:Port]
    Rails.logger.info "RsRails[#{Process.pid}]: starting with env=#{game_env} Rails.env=#{Rails.env} port=#{rails_port}"

    AppConfig.preload(game_env, game_root)
    AppConfig.override({:port => rails_port, :server_id => "rails#{rails_port}@#{game_env}"})

    # Bugsnag.configure do |config|
    #   config.api_key = AppConfig.bugsnag['api_key']
    # end

    Statsable.init(AppConfig.statsd, false)
    SentinelFactory.init :within_event_loop => false, :with_channel => false
    RedisFactory.init :within_event_loop => false, :timeout => 45.0
    RedisClusterFactory.init :within_event_loop => false, :timeout => 45.0
    MysqlFactory.init :within_event_loop => false
    KyotoFactory.init :within_event_loop => false
    Pubsub.init :within_event_loop => false, :no_subscribe => true

    RedisRpc.init(RedisHelper_.get_redis) unless RedisRpc.instance
    RedisRpc.worker.refill

    #Elasticsearch::Model.client = Elasticsearch::Client.new AppConfig.elasticsearch.symbolize_keys

    if $SKIP_GAME_CONFIG
      Rails.logger.info "RsRails[#{Process.pid}]: skip game config init"
    else
      options = { :environment => game_env, :base_path => game_root }

      cfg = RsGame.new_boot_config
      cfg.server_delegate.on_server_prefork options
      cfg.server_delegate.on_server_start options

      Boot.set_config(cfg)
    end

    # RsRails.ensure_worker_threads

    Rails.logger.info "RsRails[#{Process.pid}]: init success; will be forked later if started by god"
    Rails.logger.info "RsRails[#{Process.pid}]: server_id=#{AppConfig.server_id}"

    return true
  end

  # Ensure all worker threads that RsRails needs to be started and running.
  #
  # Rails implementation are platform-dependent:
  #
  # On OSX, you can just call ensure_worker_threads() once in initialization
  # stage (application.rb, environment.rb, boot.rb, first request etc.)
  #
  # On Linux, however, Rails needs to fork at some time, and there is no reliable
  # way to decide when Rails has finished fork or not. We have to call
  # ensure_worker_threads() before processing every request, currently in
  # ApplicationController.before_filter()
  #
  # This is now disabled because it still has thread safety problem:
  # 1. deadlock on futex() on starting gm
  # 2. rpc work loop callback thread safey
  #
  def self.ensure_worker_threads
    if @@rpc_thread and @@rpc_thread.alive?
      # Rails.logger.info "RsRails[#{Process.pid}]: rpc worker thread already started."
    else
      Rails.logger.info "RsRails[#{Process.pid}]: starting rpc worker thread..."
      @@rpc_thread = Thread.new do
        begin
          Rails.logger.info "RsRails[#{Process.pid}]: running rpc worker work loop..."
          RedisRpc.work_loop
        ensure
          Rails.logger.error "RsRails[#{Process.pid}]: RedisRpc work_loop stopped!"
        end
      end
      Rails.logger.info "RsRails[#{Process.pid}]: rpc worker thread started successfully"
    end
  end

  def self.included(base)
    RsRails.init

    base.class_eval do
      include Eventable
      include Configurable
    end
  end

  class << self
    include RsRails
  end

  def user_by_id(id)
    User.read(id)
  end

  def user_by_email(email)
    User.read_by_email(email)
  end

  def user_by_mobile(mobile)
    User.read_by_mobile(mobile)
  end

  def player_by_id(id, zone)
    Player.read_by_id(id, zone)
  end

  def player_by_name(name, zone)
    pid = Player.read_id_by_name(name, zone)
    Player.read_by_id(pid, zone)
  end

  def read_by_uid(id, zone)
    Player.read_by_uid(id, zone)
  end

  def load_game_data(id, zone)
    hash = CachedGameData.ask(id, zone, ReadCachedGameDataJob)
    GameData.new_game_data_model(id, zone).from_hash! hash
  end

  def save_game_data_hash_force(id, zone, hash)
    model = GameData.new_game_data_model(id, zone).from_hash! hash
    model.chief.id = id
    model.chief.zone = zone
    save_game_data(id, zone, model)
  end

  def save_game_data(id, zone, model)
    CachedGameData.ask(id, zone, UpdateCachedGameDataJob, model.to_hash)
  end

  def delete_game_data(id, zone)
    GameData.delete(id, zone)
    # DBHelper.delete_player(id, zone, model)
  end

  def game_config
    GameConfig.config
  end

  def get_config(name)
    GameConfig.config[name]
  end

  def get_client_version(platform, sdk)
    DynamicAppConfig.get_client_version(platform, sdk)
  end

  def set_client_version(platform, sdk, version)
    res1 = DynamicAppConfig.set_client_version(platform, sdk, version)
    Channel.publish_system_invalidate_cache DynamicAppConfig, 'get_client_version'
    res2 = gm_clear_patch_client_code()
    res1 && res2
  end

  def get_app_version(platform, sdk)
    DynamicAppConfig.get_app_version(platform, sdk)
  end

  def set_app_version(platform, sdk, version)
    res = DynamicAppConfig.set_app_version(platform, sdk, version)
    Channel.publish_system_invalidate_cache DynamicAppConfig, 'get_app_version'
    res
  end

  def num_online(zone)
    SessionManager.num_online(zone)
  end

  def gate_api_base host = '127.0.0.1'
    "http://#{host}:5080/api"
  end

  def call_gate_api api_name
    url = "#{gate_api_base}/#{api_name}"
    Rails.logger.info "calling local gate api: #{api_name}..."
    res = Boot::Tools::GmApi.new.call_uri(url)
    res
  end

  def call_all_gate_apis api_name, data
    res = {}
    server_list = self.gate_servers
    server_list.each do |server|
      name = server['name']
      ext_addr = server['addr']
      ext_addr.gsub!('egg@', '')
      ext_addr.gsub!(/:\d+/, '')
      url = "#{gate_api_base(ext_addr)}/#{api_name}"
      Rails.logger.info "calling #{name} api: #{api_name}..."
      res[name] = Boot::Tools::GmApi.new.call_uri(url, data: data)
    end
    res.each do |r|
      if not r then return false end
    end
    return true
  end

  def gate_num_online(zone)
    begin
      res = call_gate_api 'onlines'
      zones = res["zones"]
      zones[zone.to_s] || 0
    rescue => er
      Rails.logger.error "gate_num_online Error: #{er.message}"
      0
    end
  end

  def gate_num_onlines
    begin
      res = call_gate_api 'onlines'
      zones = res["zones"]
    rescue => er
      Rails.logger.error "gate_num_onlines Error: #{er.message}"
      zones = {}
    end

    (1..num_open_zones).each do |zone_id|
      if not zones[zone_id.to_s] then
        zones[zone_id.to_s] = 0
      end
    end
    zones
  end

  def gate_onlines_ids
    begin
      res = call_gate_api 'online_ids'
      zones = res["zones"]
    rescue => er
      Rails.logger.error "gate_onlines_ids Error: #{er.message}"
      zones = {}
    end

    zones
  end

  def gate_servers
    AppConfig.gate_servers
  end

  def set_queuing_settings(queuing_settings)
    res = DynamicAppConfig.set_queuing_settings queuing_settings
    Channel.publish_system_invalidate_cache DynamicAppConfig, 'get_queuing_settings'
    res
  end

  def set_zone_settings(zone_settings)
    res = DynamicAppConfig.set_zone_settings zone_settings
    Channel.publish_system_invalidate_cache DynamicAppConfig, 'get_zone_settings'
    res
  end


  def num_open_zones
    DynamicAppConfig.get_num_open_zones
  end

  def set_num_open_zones(zones)
    res = DynamicAppConfig.set_num_open_zones zones
    Channel.publish_system_invalidate_cache DynamicAppConfig, 'get_num_open_zones'
    res
  end

  def set_maintainance_status(status)
    res = DynamicAppConfig.set_maintainance_status(status)
    Channel.publish_system_invalidate_cache DynamicAppConfig, 'get_maintainance_status'

    if status.on == true
      Channel.publish_system_disconnect_all_sessions
      SessionManager.reset_all_db_sessions
    else
      groups = BoothGroup.get_all_groups
      cids = []
      groups.each do |group|
        group = BoothGroup.gen_data(group[:booth_id], group[:zones])
        cid = Helper.get_booth_checker(group)
        cids << cid
      end
      cids.each do |cid|
        RedisRpc.call(BoothSearcher, cid, {:cmd => 'reload_data'})
      end
    end

    res
  end

  def get_maintainance_status
    DynamicAppConfig.get_maintainance_status
  end

  def publish_notice(text, zone)
    NoticeDb.send(zone.to_i, 0, text)
    true
  end

  def send_chat(chid, name, text, zone)
    msg_content = {
      'uid' => '000',
      'iconid' => 'PA001',
      'name' => name,
      'level' => 99,
      'text' => text,
      'time' => Time.now.to_i,
      'vip_level' => 0,
      'vip_open_ts' => 0,
      'vip_left_time' => 0,
    }
    ChannelChatDb.send_message(chid, zone, msg_content)
    Channel.publish_system_invalidate_cache ChannelChatDb, 'get_latest_messages'
    true
  end

  def reset_chat_channels(zone)
    ChannelChatDb.del_all_player(zone)
    ChannelChatDb.del_all_msg(zone)
  end

  def send_notify_give_mail(id, zone, itemId, itemNum)
    # mail = Mail.new
    # mail.type = NotifyCenter::SYS_GENERAL
    # mail.senderId = id
    # mail.message = "gmsend:#{itemId}:#{itemNum}"
    # mail.toId = id
    # NotifyCenter.notify(id, zone, mail)
  end

  def get_usable_heroes
    GameConfig.config['heroes']
  end

  def get_notice
    ActionDb.getNotice
  end

  def delete_notice(index)
    res = ActionDb.del(index)
    # Channel.publish_system_invalidate_cache klass, 'action'
    res
  end

  def update_notice(index,title,content,isNew)
    res = ActionDb.update(index,title,content,isNew)
    # Channel.publish_system_invalidate_cache klass, 'action'
    res
  end

  def add_notice(title,content,position,isNew)
    res = ActionDb.add(title,content,position,isNew)
    # Channel.publish_system_invalidate_cache klass, 'action'
    res
  end

  def is_arena_bonus_event_open(zone)
    return ArenaDb.is_bonus_event_valid(zone)
  end

  def set_arena_bonus_event_open(zone, open)
    ArenaDb.set_arena_global_bonus_enabled(zone, open)
    ArenaDb.invalidate_all_caches
  end

  def all_device_tokens
    PushDb.all_device_tokens
  end

  def set_dev_mode(dev_mode)
    dev_mode = (dev_mode == true or dev_mode == 'true')
    Rails.logger.info "set_dev_mode: dev_mode=#{dev_mode}"
    res1 = Channel.publish_system_dev_mode(dev_mode)
    res2 = call_all_gate_apis("set_dev_mode?value=#{dev_mode}")
    if res1 and res2
      AppConfig.server['dev_mode'] = dev_mode
      true
    else
      false
    end
  end

  def gm_patch_ruby_code(ruby_code_str)
    res = Channel.publish_system_patch_ruby_code(ruby_code_str)
    if res
      true
    else
      false
    end
  end

  def gm_patch_elixir_code(elixir_code_str)
    encoded_code = Base64.urlsafe_encode64(elixir_code_str)
    res = call_all_gate_apis("patch_elixir_code", encoded_code)
    if res
      true
    else
      false
    end
  end

  def gm_reload_server_config()
    res1 = Channel.publish_system_reload_server_config()
    res2 = call_all_gate_apis("reload_server_config")
    res2 = true
    if res1 && res2
      true
    else
      false
    end
  end

  def gm_patch_client_code(client_lua_code)
    ClientHotPatchDb.set_patch_code(client_lua_code)
    res = Channel.publish_system_patch_client_code(client_lua_code)
    if res
      true
    else
      false
    end
  end

  def gm_clear_patch_client_code()
    ClientHotPatchDb.clear_patch_code()
    res = Channel.publish_system_clear_patch_client_code()
    if res
      true
    else
      false
    end
  end

  def gm_reload_server_list()
    Rails.logger.info "gm_reload_server_list"
    res1 = Channel.publish_system_reload_server_list()
    res2 = call_all_gate_apis("reload_server_list")
    if res1 and res2
      AppConfig.reload_server_list(AppConfig.path)
      true
    else
      false
    end
  end

  def gm_garbage_collect_all()
    Rails.logger.info "gm_garbage_collect_all"
    res1 = Channel.publish_system_garbage_collect_all()
    res2 = call_all_gate_apis("garbage_collect_all")
    if res1 and res2
      GC.start
      true
    else
      false
    end
  end

  def add_schedule_chat(params)
    if !params[:zones] || params[:zones] == ''
      return [false, "invalid zones:#{params[:zones]}"]
    elsif params[:content].nil? or params[:content] == ''
      return [false, "empty content!!!"]
    elsif params[:start_time].nil? or params[:start_time] == ''
      return [false, "empty start_time!!!"]
    elsif params[:stop_time].nil? or params[:stop_time] == ''
      return [false, "empty stop_time!!!"]
    elsif params[:interval].nil? or params[:interval] == '' or params[:interval].to_i <= 0
      return [false, "invalid interval #{params[:interval]}"]
    end

    content = params[:content].to_s
    zones = params[:zones]
    zones = zones.split(',').map{|z| z.strip.to_i}
    zones.uniq!
    start_time = TimeHelper.parse_date_time(params[:start_time]).to_i
    stop_time = TimeHelper.parse_date_time(params[:stop_time]).to_i
    interval = params[:interval].to_i
    name = params[:chatName].to_s
    times = params[:times].to_i
    color = params[:input_color_2]
    chat = ScheduleChat.new(zones, start_time, stop_time, interval, content, name, times, color)
    success = ScheduleChatDB.add(chat)
    [success, 'count limit']
  end

  def remove_schedule_chat(params)
    index = params[:index]
    ScheduleChatDB.remove(index)
  end

  def get_schedule_chats
    ScheduleChatDB.get_all_chats
  end

  def get_combat_server_data
    CombatServerDB.get_all_server
  end

  def send_mail(zone, userId, text)
    mail = MailMessage.new()
    mail.toId = userId
    mail.type = 'system'
    mail.sub_type = 'normal'
    mail.send_type = 'all_mail'
    mail.content = { 'text' => text, 'things' => [], 'title_one' => 'gm_mail' }
    mail.time = Time.now.to_i
    mail.from_name = 'GM'
    mail.zone = zone
    mail.reason = 'gm_mail'

    NotifyCenter.notify(userId, zone, mail)

    true
  end
end

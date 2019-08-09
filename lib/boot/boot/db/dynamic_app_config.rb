# DynamicAppConfig.rb

# 从redis读取服务器配置
# 若config中有值则使用config中的值

require 'eventmachine'
require 'json'

module Boot

  class DynamicAppConfig

    include Loggable
    include Cacheable
    include RedisHelper

    gen_static_cached 600, :get_client_version, :get_app_version,
      :get_num_open_zones, :get_maintainance_status, :get_queuing_settings,
      :get_zone_settings, :get_gate_server_settings
    gen_static_invalidate_cache :get_client_version, :get_app_version,
      :get_num_open_zones, :get_maintainance_status, :get_queuing_settings,
      :get_zone_settings, :get_gate_server_settings

    #################################
    ## ClientVersion

    def self.client_version(platform, sdk)
      if AppConfig.client_version and AppConfig.client_version[platform]
        return AppConfig.client_version[platform].to_s
      else
        return get_client_version_cached(platform, sdk)
      end
    end

    def self.get_client_version(platform, sdk)
      r = redis
      if r
        return r.hget('client_version', platform)
      else
        return ''
      end
    end

    def self.set_client_version(platform, sdk, version)
      r = redis
      if r
        # this will return true if the field was **added**
        r.hset('client_version', platform, version)
        return true
      else
        return false
      end
    end

    #################################
    ## AppVersion

    def self.pkg_version(platform, sdk)
      self.app_version(platform, sdk)
    end

    def self.app_version(platform, sdk)
      if AppConfig.app_version and AppConfig.app_version[platform]
        return AppConfig.app_version[platform].to_s
      else
        return get_app_version_cached(platform, sdk)
      end
    end

    def self.get_app_version(platform, sdk)
      r = redis
      if r
        return r.hget('app_version', platform)
      else
        return ''
      end
    end

    def self.set_app_version(platform, sdk, version)
      r = redis
      if r
        # this will return true if the field was **added**
        r.hset('app_version', platform, version)
        return true
      else
        return false
      end
    end

    #################################
    ## NumOpenZones

    def self.num_open_zones
      if AppConfig.server['num_open_zones']
        return AppConfig.server['num_open_zones'].to_i
      else
        return [ get_num_open_zones_cached, 1 ].max
      end
    end

    def self.get_num_open_zones
      r = redis
      if r
        num = r.get('num_open_zones')
        return num.to_i if num
        return 1
      else
        return 1
      end
    end

    def self.set_num_open_zones(num_open_zones)
      r = redis
      if r
        r.set('num_open_zones', num_open_zones)
        return true
      else
        return false
      end
    end

    #################################
    ## maintainance status

    def self.maintainance_status
      return get_maintainance_status_cached
    end

    def self.get_maintainance_status
      r = redis
      status = MaintainanceStatus.new
      if r
        raw = r.get('maintainance_status')
        if raw
          return status.load!(raw)
        else
          return status
        end
      else
        return status
      end
    end

    def self.set_maintainance_status(status)
      r = redis
      if r
        r.set('maintainance_status', status.dump)
        return true
      else
        return false
      end
    end

    #################################
    ## queuing settings

    def self.queuing_settings
      return get_queuing_settings_cached
    end

    def self.get_queuing_settings
      r = redis
      settings = QueuingSettings.new
      if r
        raw = r.get('queuing_settings')
        if raw
          return settings.load!(raw)
        else
          return settings
        end
      else
        return settings
      end
    end

    def self.set_queuing_settings(settings)
      r = redis
      if r
        if settings
          r.set('queuing_settings', settings.dump)
        else
          r.del('queuing_settings')
        end
        return true
      else
        return false
      end
    end

    #################################
    ## zone settings

    def self.zone_settings
      return get_zone_settings_cached
    end

    def self.get_zone_settings
      r = redis
      zone_settings = ZoneSettings.new
      if r
        raw = r.get('zone_settings')
        if raw
          return zone_settings.load!(raw)
        end
      end
      return zone_settings
    end

    def self.set_zone_settings(zone_settings)
      r = redis
      if r
        if zone_settings
          r.set('zone_settings', zone_settings.dump)
        else
          r.del('zone_settings')
        end
        return true
      else
        return false
      end
    end

    #################################
    ## gate server settings

    def self.gate_server_settings
      return get_gate_server_settings_cached
    end

    def self.get_gate_server_settings
      r = redis
      gate_server_settings = GateServerSettings.new
      if r
        raw = r.get('gate_server_settings')
        if raw
          return gate_server_settings.load!(raw)
        end
      end
      return gate_server_settings
    end

    def self.set_gate_server_settings(gate_server_settings)
      r = redis
      if r
        if gate_server_settings
          r.set('gate_server_settings', gate_server_settings.dump)
        else
          r.del('gate_server_settings')
        end
        return true
      else
        return false
      end
    end

  private

    def self.redis
      return @@redis if defined? @@redis and @@redis
      return get_redis :user
    end

    def self.redis= redis
      @@redis = redis
    end

  end

  # Server maintainance status

  class MaintainanceStatus

    include Jsonable

    attr_accessor :on, :start_at, :end_at, :id_whitelist
    attr_accessor :sdk_whitelist
    attr_accessor :enable_loadtest

    gen_from_hash
    gen_to_hash

    def initialize
      self.sdk_whitelist = []
      self.id_whitelist = []
    end

    def in_id_whitelist?(id)
      return false if id_whitelist.nil?
      id_whitelist.include?(id)
    end

    def in_sdk_whitelist?(sdk)
      return false if sdk_whitelist.nil?
      sdk_whitelist.include?(sdk)
    end

  end

  # Queuing Settings

  class QueuingSettings

    include Jsonable

    attr_accessor :id_whitelist

    gen_from_hash
    gen_to_hash

    def initialize
      @id_whitelist = []
    end

    def in_id_whitelist?(id)
      return false if id_whitelist.nil?
      id_whitelist.include?(id)
    end

  end

  # Zone settings

  class ZoneSettings

    include Jsonable

    attr_accessor :settings

    json_hash :settings, :ZoneSetting

    gen_from_hash
    gen_to_hash

    def initialize
      @settings = {}
    end

  end

  class ZoneSetting

    DEFAULT_MAX_ONLINE = 2_000

    include Jsonable

    attr_accessor :zone_id, :name, :status,
      :recommend, # 推荐选择
      :max_online # 最大同时在线限制

    gen_from_hash
    gen_to_hash

    def initialize zone_id = nil
      @zone_id = zone_id
      @recommend = false
      @max_online = DEFAULT_MAX_ONLINE
    end

  end

  # Gate server zones

  class GateServerSettings

    include Jsonable

    attr_accessor :settings
    attr_accessor :disable_voice_chat
    attr_accessor :disable_advt_filtering

    json_array :settings, :GateServerSetting

    gen_from_hash
    gen_to_hash

    def initialize
      @settings = []
      @disable_voice_chat = false
    end

    def find_setting(server_name)
      @settings.each do |setting|
        return setting if setting.name == server_name
      end
      return nil
    end

  end

  class GateServerSetting

    include Jsonable

    attr_accessor :name, :addr, :ext_addr
    # net params
    attr_accessor :main_sync_interval, :combat_sync_interval
    # action validation params
    attr_accessor :main_av_level, :pve_av_level

    gen_from_hash
    gen_to_hash

  end

end

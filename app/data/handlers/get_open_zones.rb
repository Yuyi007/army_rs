# get_open_zones.rb

class GetOpenZones < Handler

  include Cacheable

  gen_static_cached 30, :get_open_zones

  def self.process(session, msg)
    self.do_process(session, msg)
  end

  # Because this needs to be accessed before login
  # It has a vulnerability that anyone can get other's last zones
  def self.do_process(session, msg)
    if session.player_id and session.player_id != '$noauth$'
      player_id = session.player_id
    elsif msg.is_a? Hash
      if msg['playerId'] then
        player_id = msg['playerId']
      else
        # raise "no player_id in hash #{msg}"
        return {}
      end
    end

    if player_id and player_id != ''
      d { "GetOpenZones: player_id=#{player_id}" }
      player_zones = PlayerZones.get(player_id)
      last_zones = player_zones.to_hash['last_zones'] if player_zones
    end

    res = {
      'num_open_zones' => DynamicAppConfig.num_open_zones,
      'open_zones' => get_open_zones_cached(),
      'last_zones' => last_zones,
      'player_id' => player_id,
    }

    res
  end

  def self.get_open_zones()
    num_open_zones = DynamicAppConfig.num_open_zones
    zone_settings = DynamicAppConfig.zone_settings.settings
    zone_config=GameConfig.config['zones']
    open_zones = {}
    (1..num_open_zones).each do |zone|
      zone_setting = zone_settings[zone]
      if zone_setting then
        max_online = zone_setting.max_online
        recommend = zone_setting.recommend
      else
        max_online = DynamicAppConfig::ZoneSetting::DEFAULT_MAX_ONLINE
        recommend = false
      end
      # zone_name = zone_config[zone-1]['name']
      open_zones[zone] = {
        'online' => SessionManager.num_online(zone),
        'max_online' => max_online,
        'recommend' => recommend,
        'zone' => zone,
      }
    end

    open_zones
  end

end

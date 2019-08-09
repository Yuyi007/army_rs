module CSRouter
	include Loggable
  include Statsable

	@@checker_mappings = {} unless defined? @@checker_mappings
  @@checker_zones = {}
  @@last_num_open_zones = nil

  # checker dispatch strategy
  # all servers get deterministic result when doing this
  # strategy [checker index => group] 
  # 	0 								=>  basic 	:deal with stats uploading
  # 												archive :deal with cold data storage
  #
  #   1~len-1 =>	zones : deal with game matching and normal buniess that associate with zone
  #note: if checker server started by cmd [rake checker] ,
  #  		 all group use checker 0
  
  def self.init_checker_groups()
  	srvs = AppConfig.checker_servers
    info "checker_servers=#{srvs}"
    len = srvs.length

    # 0
    @@checker_mappings['basic'] 		= [srvs[0]]
		@@checker_mappings['archive'] 	= [srvs[0]]

		#1～（len-1)
		@@checker_mappings['zones'] = []
		(1...len).each do |i|
			@@checker_mappings['zones'] << srvs[i]
		end
		@@checker_mappings['zones'] << srvs[0] if len == 1

    info "checker_mappings=#{@@checker_mappings}"
  end

  def self.get_checker_zones(server_id)
    num_open_zones = DynamicAppConfig.num_open_zones
    if @@last_num_open_zones != num_open_zones || @@checker_zones[server_id] == nil
      @@checker_zones[server_id] = (1..num_open_zones).select { |zone|
        get_zone_checker(zone) == server_id
      }
      @@last_num_open_zones = num_open_zones
      info "checker_zones=#{@@checker_zones}"
    end
    @@checker_zones[server_id]
  end

  def self.get_zone_checker(zone)
    get_checker_by_index('zones', zone)
  end

  def self.get_match_checker(zone)
  	get_checker_by_index('zones', zone)
  end

  def self.each_match_checker
    @@checker_mappings['zones'].each do |srv|
      yield srv['name']
    end
  end

  def self.broadcast_to_checkers(klass, msg)
    each_match_checker do |cid|
      RedisRpc.cast(klass, cid, msg)
    end
  end

  def self.get_archive_checker
    get_checker_by_index('archive', 0)
  end

  def self.get_basic_checker
    get_checker_by_index('basic', 0)
  end

  # round-robin mapping according to index and server num of checker group
  def self.get_checker_by_index(group, index)
    index = index.to_i
    mapping = @@checker_mappings[group]
    checker_num = mapping.length
    server = mapping[index.to_i % checker_num]
    server['name']
  end
end
# player.rb
# 
# 玩家简略信息，结构是hash，可通过玩家名字和id索引
# 该hash表作用是方便查询玩家数据，而不用读取完整的玩家数据

class Player
  # Keep the player entity small
  # Only put in stuff that're necessary
  #

  HUGE_NUMBER = 10_000_000_000

  attr_accessor :uid        # 主id
  attr_accessor :pid         # instance的player_id 包含 pid instandce_id
  attr_accessor :user_id    # 账号id 可能是第三方平台的
  attr_accessor :zone       # 区
  attr_accessor :icon       # 头像
  attr_accessor :icon_frame # 头像框
  attr_accessor :name       # 昵称
  attr_accessor :label      # 标签
  attr_accessor :level      # 玩家等级
  attr_accessor :vip_level  # vip 等级
  attr_accessor :online     # 玩家是否在线

  #游戏相关数据 请注意在修改游戏数据后更新
  attr_accessor :reg_time     # 建立游戏角色的时间，游戏天数根据这个时间计算
  attr_accessor :hero_count   # 车辆数量
  attr_accessor :ava_count    # avatar部件数量
  attr_accessor :dec_count    # 装饰物数量
  attr_accessor :efx_count    # 特效数量
  attr_accessor :combat_stat  # 战斗统计数据：积分（段位），各种战斗次数，胜率
  attr_accessor :gender       # 性别
  attr_accessor :last_login_time  #上次登入时间

  include Loggable
  include Jsonable
  include Cacheable
  include RedisHelper

  json_object :combat_stat, :CombatStat

  gen_to_hash
  gen_from_hash

  gen_static_cached 60 * 60 * 24 * 14, :get_all_players
  gen_static_cached 30, :get
  gen_static_cached 30, :level_count
  gen_static_invalidate_cache :get

  def initialize(pid = nil, zone = nil, name = nil, 
                 icon = nil,  icon_frame = nil, label = nil)
    @uid = ''
    @user_id = ''
    @pid = pid
    @zone = zone
    @icon = icon
    @icon_frame = icon_frame
    @name = name
    @label = label
    @level = 0
    @vip_level = 0
    @online = false
    @gender = ''
    @reg_time = Time.now.to_i
    @hero_count = 1
    @ava_count = 0  
    @dec_count = 0  
    @efx_count = 0  
    @combat_data = {}
    @last_login_time = Time.now.to_i
  end

  def save(*args)
    if block_given?
      Player.redis_hash(zone).hset_with_lock(pid) do |o|
        yield(*args, o)
        from_hash!(o.to_hash)
      end
    else
      Player.redis_hash(zone).hset(pid, self)
    end
  end

  def invalidate_cache
    self.class.get_invalidate_cache(pid)
  end

  def self.from_instance(instance)
    return nil if instance.nil?
    model = instance.model
    return nil if model.nil?
    chief = model.chief

    player                       = get_or_create(instance.player_id)
    player.uid                   = chief.id
    player.user_id               = chief.user_id
    player.zone                  = chief.zone
    player.name                  = instance.name
    player.pid                   = instance.player_id
    player.icon                  = instance.icon
    player.level                 = instance.level
    player.online                = instance.online
    player.vip_level             = chief.vip_level   
    player.reg_time              = instance.record.register_time
    player.gender                = instance.gender
    player.last_login_time       = instance.record.last_login_time
   
    player
  end
  

  def self.update(id, zone, player)
    return if player.nil?

    redis_hash(zone).hset(id, player)
    redis_index = redis_index(zone)
    redis_index.update_prefix(:name, id, player.name)

    all_keys = %W(level uid:#{player.uid})
    all_scores = [ player.level, player.uid.to_i]
    # puts ">>>all_keys:#{all_keys}"
    redis_index.update_scores(id, all_keys, all_scores)

    player.invalidate_cache
  end

  def self.get_player_by_label(label, zone)
    #to do
  end

  def self.get_players_by_cid(uid, zone)
    # puts "uid:#{uid}"
    pids = redis_index(zone).range("uid:#{uid}", 0, -1)  
    # puts "pids>>>>>:#{pids}"
    players = read_multi_player(pids, zone).to_data
    players
  end

   


  def self.update_score(score_key, pid, score)
    zone = Helper.get_zone_by_pid(pid)
    redis_index = redis_index(zone)
    redis_index.update_score(score_key, pid, score)
  end

  def self.incr_score(score_key, pid, score_incred = 1)
    zone = Helper.get_zone_by_pid(pid)
    redis_index = redis_index(zone)
    redis_index.incr_score(score_key, pid, score_incred)
  end

  def self.get_ranking_players(score_key, zone, page, num_per_page = 4)
    redis_index = redis_index(zone)
    total = redis_index.length(score_key)
    pids = redis_index.revrange(score_key, page, num_per_page)

    players = read_multi_player(pids, zone).map.with_index do |player, index|
      next nil if player.nil?
      o = player.to_data(true)
      o.rank = page * num_per_page + index + 1
      o
    end

    players = players.compact

    [players, total]
  end
  
  def self.get_range_players(pid)
    zone =  Helper.get_zone_by_pid(pid)
    ids  = get_player_ids(zone)
    ids
  end


  def self.get_rank_by_pid(score_key, pid)
    zone = Helper.get_zone_by_pid(pid)
    redis_index = redis_index(zone)
    redis_index.revrank(score_key, pid)
  end

  def self.read_multi_player(ids, zone)
    return [] if ids.nil? || zone.nil?
    ids = ids.compact
    return [] if ids.empty?

    redis_hash(zone).hmget(ids)
  end

  def self.fetch(ids, zone)
    read_multi_player(ids, zone)
  end

  def self.fetch_names(ids, zone)
    return [] if ids.nil? || zone.nil?
    ids = ids.compact
    return [] if ids.empty?

    redis_index(zone).get_multi_prefixes(:name, ids)
  end

  def self.read_by_id(id, zone)
    redis_hash(zone).hget(id)
  end

   def self.read_by_uid(uid,zone)
    redis_hash(zone).hget(player_key_by_uid(uid,zone))
  end

  def self.get(pid)
    zone = Helper.get_zone_by_pid(pid)
    redis_hash(zone).hget(pid)
  end

  def self.get_or_create(pid)
    zone = Helper.get_zone_by_pid(pid)
    redis_hash(zone).hget_or_new(pid)
  end

  def self.read_id_by_name(name, zone)
    redis_index(zone).read_by_prefix(:name, name)
  end

  # return an array of #count num matches
  def self.search_by_name(str, zone, count = 10)
    return [] if str.nil?
    str.gsub!(/:.+/, '')
    str.gsub!(/[\@\!\#\$\%\^\&\(\)\*:\s]/, '')
    return [] if str.length == 0

    redis_index(zone).search_by_prefix(:name, str, count)
  end

  def self.search_by_level(level_min, level_max, zone, count = 10, offset = 0)
    redis_index(zone).search_by_score(:level, level_min, level_max, count, offset)
  end

  def self.level_count(level_min, level_max, zone)
    redis_index(zone).count(:level, level_min.to_s, level_max.to_s)
  end

  def self.delete(id, zone)
    redis_hash(zone).hdel(id)
    redis_index(zone).delete(:name).delete(:level)
  end

  # NOTE
  # this eats a lot resources, use with caution
  # use get_all_players_cached whenever necessary
  def self.get_all_players
    zones = {}
    (1..DynamicAppConfig.num_open_zones).each do |zone|
      zones[zone] ||= []
      redis_hash = redis_hash(zone)
      keys = redis_hash.hkeys
      # puts "keys=#{keys}"
      keys.each do |key|
        match = key.match(/^.*_(\d+)_.*$/i)
        next unless match
        caps = match.captures
        if caps && caps.length > 0
          id = caps[0]
          zones[zone] << id.to_i unless id.nil? || id == ''
        end
      end
      zones[zone].uniq!
    end
    zones
  end

  def self.get_total_player_count
    get_all_players_cached.inject(0) { |num, pair| num += pair[1].length }
  end

  # Faster get all players count of all opened zones
  def self.total_player_count
    total = 0
    (1..DynamicAppConfig.num_open_zones).each do |zone|
      total += redis_hash(zone).hlen.to_i
    end
    total
  end

  def self.player_count(zone)
    redis_hash(zone).hlen.to_i
  end

  def self.get_player_ids(zone)
    get_all_players_cached[zone.to_i] || []
  end

  def self.redis_hash(zone)
    RedisHash.new(redis(zone), player_key(zone), Player)
  end

  def self.redis_index(zone)
    RedisIndex.new(redis(zone), player_key(zone))
  end

  def self.redis(zone)
    get_redis zone
  end

  def self.player_key(zone)
    "ply:#{zone}"
  end

  def self.player_key_by_uid(uid, zone)
    "#{zone}_#{uid}_i1"
  end
end

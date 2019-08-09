=begin
  ChannelChatDb
  数据库记录每个频道注册的玩家，每个频道最近25条消息
  内存存储该服务器在线频道注册的玩家
=end
class ChannelChatDb

  include Loggable
  include Cacheable
  include RedisHelper

  gen_static_cached 20, :get_latest_messages
  gen_static_invalidate_cache :get_latest_messages


  @@map_ch_players ||= {}
  @@ch_ids ||= [] #储存所有的频点id
  @@channel_player_limit = 200
  @@channel_msg_limit = 30

  #获取频道最近条消息
  def self.get_latest_messages(zone, ch_id)
    r = redis zone
    key = msg_key(zone, ch_id)
    i = -@@channel_msg_limit #最近消息条数
    r.lrange(key, i, -1).map do |raw|
      chat = Jsonable.load_hash(raw)
      if chat['text'] then
        begin
          chat['text'].gsub('a','a')
        rescue
          chat['text'] = '???'
        end
      end
      chat
    end
  end

  def self.incr_msg_no(zone, ch_id)
    r = redis zone
    key_num = num_key(zone, ch_id)
    r.incr(key_num)
  end

  def self.get_msg_no(zone, ch_id)
    r = redis zone
    key_num = num_key(zone, ch_id)
    no = r.get(key_num)
    return 0 if no.nil?
    return no.to_i
  end

  ADD_MESSAGE = %Q{
    local keyMsg, keyCh = unpack(KEYS)
    local msg, max = unpack(ARGV)
    local exist = redis.call('exists', keyCh)
    if exist == 1 then
      redis.call('rpush', keyMsg, msg)
      redis.call('ltrim', keyMsg, -max, -1)
    end
  }
  #添加某个频道刚发送过得消息 不超过x条
  #msg:
  #         { 'pid' => session.player_id,
  #           'name' => 'aaa',
  #           'level' => 1,
  #           'text' => text,
  #           'time' => x:x:x
  #         }
  def self.add_message(zone, ch_id, msg)
    r = redis zone
    msg_limit = @@channel_msg_limit
    key_msg = msg_key(zone, ch_id)
    key_ch = channel_key(zone, ch_id)
    ret = r.evalsmart(ADD_MESSAGE, :keys => [key_msg, key_ch],
                                  :argv => [Jsonable.dump_hash(msg),msg_limit])
  end
  
  ADD_PLAYER = %Q{
    local keyChOld, keyChIds = unpack(KEYS)
    local  pid, zone = unpack(ARGV)
    local field = fieldPlayer(pid, zone)


    local chIds = redis.call('lrange', keyChIds, 0, 0)
    
    --find useable channel

    for i,k in pairs(chIds) do
      if i == 1 then
        redis.call('hset', k, field, pid)
        return i
      end  
    end

    --generate new channel
    local chIndex =  1 
    -- the key is tagged, so it will always be on the same server as keyChOld
    local keyCh, _ = string.gsub(keyChOld, '%d+$', chIndex)
    redis.call('rpush', keyChIds, keyCh)
    redis.call('hset', keyCh, field, pid)
    return chIndex
  }
  #添加一个玩家, 返回自动分配的世界频道id
  def self.add_player(ch_id, zone, pid)
    r = redis zone
    player_limit = @@channel_player_limit
    channel_limit = @@channel_msg_limit
    script = lua_common_func + ADD_PLAYER
    real_id = r.evalsmart(script,
      :keys => [ channel_key(zone, ch_id), channel_ids_key(zone)],
      :argv => [ pid, zone])
    @@ch_ids << real_id if not @@ch_ids.include?(real_id)
    return real_id.to_i
  end
  
  #ch_id = 0 为自动分配新频道 其他为找到创建好的频道并加入
  ADD_PLAYER_TWO = %Q{
    local keyChOld, keyChIds = unpack(KEYS)
    local chId, pid, zone, ch_ids = unpack(ARGV)
    local field = fieldPlayer(pid, zone)

    local chIds = redis.call('lrange', keyChIds, 0, -1)

    if tonumber(chId) ~= 0 then
      --check already exist
      local existKey = 0
      for i,k in pairs(chIds) do
        if k == keyChOld then
          existKey = 1
          break
        end
      end
      if existKey == 1 then
        local existField = redis.call('hexists', keyChOld, field)
        if existField == 1 then
          return chId
        end

        --not exist and not full
        redis.call('hset', keyChOld, field, pid)
        return chId
      end
    end
    
    --find useable channel 
    for i,k in pairs(chIds) do
      if i ~= 1 then
        local count = redis.call('hlen', k)
        if count == 0 then
          redis.call('hset', k, field, pid)
          return i
        end 
      end   
    end 

    --generate new channel
    local chIndex = #chIds + 1 
    -- the key is tagged, so it will always be on the same server as keyChOld
    local keyCh, _ = string.gsub(keyChOld, '%d+$', chIndex)
    redis.call('rpush', keyChIds, keyCh)
    redis.call('hset', keyCh, field, pid)
    return chIndex
  }
  #添加一个玩家, 返回自动分配的频道id(组队,俱乐部)
  def self.add_player2(ch_id, zone, pid)
    r = redis zone
    player_limit = @@channel_player_limit
    channel_limit = @@channel_msg_limit
    script = lua_common_func + ADD_PLAYER_TWO
    real_id = r.evalsmart(script,
      :keys => [ channel_key(zone, ch_id), channel_ids_key(zone)],
      :argv => [ ch_id, pid, zone, @@ch_ids])
    @@ch_ids << real_id if not @@ch_ids.include?(real_id)
    return real_id.to_i
  end  

  
  def self.player_exist(ch_id, pid, zone)
  end  

  CHANNEL_COUNT = %Q{
    local keyChIds= unpack(KEYS)
    local chIds = redis.call('lrange', keyChIds, 0, -1)
    local counts = 0
    for i,k in pairs(chIds) do
      local count = redis.call('hlen', k)
      counts = count
    end 
    return counts
  }
  def self.channel_counts(zone)
    r = redis zone
    r.evalsmart(CHANNEL_COUNT,
      :keys => [ channel_ids_key(zone)],
      :argv => [])
  end

  DEL_ALLPLAYER = %Q{
    local keyChIds= unpack(KEYS)
    local chIds = redis.call('lrange', keyChIds, 0, -1)
    for i,k in pairs(chIds) do
      redis.call('del', k)
    end
    redis.call('del', keyChIds)
  }
  def self.del_all_player(zone)
    r = redis zone
    r.evalsmart(DEL_ALLPLAYER,
      :keys => [ channel_ids_key(zone)],
      :argv => [])
  end
  
  #清除内存里面的聊天频道
  def self.del_mey_channel_id(ch_id)
    @@ch_ids.delete(ch_id) if @@ch_ids.include?(ch_id)
  end  

  GET_PLAYERS_COUNT = %Q{
    local keyChOld  = unpack(KEYS)
    return redis.call('hlen', keyChOld)
  }
  #获得非世界聊天频道人数的数量
  def self.get_channel_players_count(ch_id, zone)
    r = redis zone
    count = r.evalsmart(GET_PLAYERS_COUNT,
      :keys => [ channel_key(zone, ch_id)],
      :argv => [])
    return count
  end  

  #获得所有频道Id
  def self.get_all_chids(zone)
    return @@ch_ids
  end  

  def self.del_all_msg(zone)
    r = redis zone
    keyChIds = channel_ids_key(zone)
    len = r.llen(keyChIds)  #, 0, -1
    1.upto(len) do |ch_id|
      r.del(msg_key(zone, ch_id))
    end
  end
  
  #删除其他聊天频道的信息
  def self.del_channel_msgs(ch_id, zone)
    r = redis zone
    r.del(msg_key(zone, ch_id))
  end
  
  DEL_CH_ID = %Q{
    local keyChOld, keyChIds = unpack(KEYS)
    local chIds = redis.call('lrange', keyChIds, 0, -1)
    for i,k in pairs(chIds) do
      if k == keyChOld then
        redis.call('lrem', keyChIds, 0, k)
      end  
    end
    redis.call('del', keyChOld)
  }
  #删除聊天频道
  def self.del_channel_id(ch_id, zone)
    r = redis zone
    r.evalsmart(DEL_CH_ID,
      :keys => [ channel_key(zone, ch_id), channel_ids_key(zone)],
      :argv => [])
  end  

  
  #删除所有频道
  def self.del_all_channel
    (1..DynamicAppConfig.num_open_zones).each do |zone|
      del_all_player(zone)
    end
  end

  DEL_PLAYER = %Q{
    local keyCh = unpack(KEYS)
    local pid, zone  = unpack(ARGV)
    local field = fieldPlayer(pid, zone)
    redis.call('hdel', keyCh, field)

    --if empty should clean and del channel 
    local exist = redis.call('exists', keyCh)
    if exist == 0 then
    end
  }
  #移除一个玩家
  def self.del_player(ch_id, zone, pid)
    puts "---chat channel del_player:ch_id:#{ch_id} zone:#{zone} pid:#{pid}"
    script = lua_common_func + DEL_PLAYER
    r = redis zone
    r.evalsmart(script, :keys => [channel_key(zone, ch_id)], 
      :argv => [pid, zone])
  end
  

  MOVE_PLAYER = %Q{
    local keyChOld, keyChNew, keyChIds = unpack(KEYS)
    local chIdOld, chIdNew, pid, zone, playerLimit = unpack(ARGV)
    local field = fieldPlayer(pid, zone)
    playerLimit = tonumber(playerLimit)

    --check exist
    local exist = 0
    local chIds = redis.call('lrange', keyChIds, 0, -1)
    for i,k in pairs(chIds) do
      if keyChNew == k then
        exist = 1
        break
      end
    end
    if exist == 0 then
      return -1 
    end

    --check full
    local count = redis.call('hlen', keyChNew)
    if count >= playerLimit then
      return -2
    end

    --move
    redis.call('hdel', keyChOld, field)
    redis.call('hset', keyChNew, field, pid)

    return 0
  }
  #移动一个玩家 0: success -1:new ch_id not exist -2:new channel full
  def self.move_player(ch_id_old, ch_id_new, zone, pid)
    r = redis zone
    player_limit = @@channel_player_limit
    script = lua_common_func + MOVE_PLAYER
    real_id = r.evalsmart(script,
      :keys => [ channel_key(zone, ch_id_old), channel_key(zone, ch_id_new), channel_ids_key(zone)],
      :argv => [ ch_id_old, ch_id_new, pid, zone, player_limit ])
    return real_id.to_i
  end

  #添加在线玩家
  def self.add_online_player(ch_id, zone, pid)
    # d{">>>>>>[ch_id111]:#{ch_id}"} 
    # d{">>>>>>[zone111]:#{zone}"} 
    # d{">>>>>>[addpid]:#{pid}"} 
    key = key_mem_chs(ch_id, zone)
    players = @@map_ch_players[key]
    players ||= []
    # d{">>>>>>[players111]:#{players}"} 
    players << pid if not players.include?(pid)
    # d{">>>>>>[players222]:#{players}"}
    # players[pid] = {'pid' => pid, 'zone' => zone}
    @@map_ch_players[key] = players
  end

  #删除在线的玩家
  def self.del_online_player(ch_id, zone, pid)
    key = key_mem_chs(ch_id, zone)
    players = @@map_ch_players[key]
    # d{">>>>>>[ch_id333]:#{ch_id}"} 
    # d{">>>>>>[zone333]:#{zone}"} 
    # d{">>>>>>[players333]:#{players}"} 
    players.delete(pid) if not players.nil?
  end

  #移动一个玩家到另外一个频道
  def self.move_online_player(ch_id_old, ch_id_new, zone, pid)
    del_online_player(ch_id_old, zone, pid)
    add_online_player(ch_id_new, zone, pid)
  end

  #获取某个频道的在线玩家
  def self.get_players(ch_id, zone)
    key = key_mem_chs(ch_id, zone)
    @@map_ch_players[key]
  end

  #发送消息
  def self.send_message(ch_id, zone, msg)
    hs = {'chid'  => ch_id,
          'msg'   => msg
         }
    Channel.publish('channel_chat', zone, hs)
    add_message(zone, ch_id, msg)
  end

private

  def self.redis(zone)
    get_redis zone
  end

  def self.lua_common_func
    %Q{
      --玩家field
      local function fieldPlayer(pid, zone)
         return pid..zone
      end
    }
  end

  def self.chat_tag key
    # the same tag guarantees the keys are in the same redis instance
    # so that lua scripts can operate on these keys
    redis_key_by_tag key, 'chat'
  end

   # 存储聊天消息的自增序号
  def self.num_key(zone, ch_id)
    key_with_tag(zone)['num_key'][zone][ch_id]
  end

  # 存储频道用户, hash
  def self.channel_key(zone, ch_id)
    key_with_tag(zone)['channel_key'][zone][ch_id]
  end

  # 存储频道id, list
  def self.channel_ids_key(zone)
    key_with_tag(zone)['channel_ids_key'][zone] 
  end
  
  #  # 存储非世界频道用户, hash(组队，俱乐部)
  # def self.channel_key2(zone, ch_id)
  #   key_with_tag(zone)['channel_key2'][zone][ch_id]
  # end
  
  # #存储非世界频道id,list(组队，俱乐部)
  # def self.channel_ids_key2(zone)
  #   key_with_tag(zone)['channel_ids_key2'][zone] 
  # end  

  # 存储频道最近消息, list
  def self.msg_key(zone, ch_id)
    key_with_tag(zone)['msg_key'][zone][ch_id]
  end

  # 内存频道里的玩家, list
  def self.key_mem_chs(ch_id, zone)
    "ch:#{ch_id}:#{zone}"
  end

  def self.key_with_tag(zone)
    @booth ||= Nest.new(redis_key_by_tag('channel'), redis(zone))
  end
end
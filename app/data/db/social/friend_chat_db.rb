class FriendChatDb

  include Loggable
  include Cacheable
  include RedisHelper

  LIMIT_CONTENT = 20 unless const_defined? :LIMIT_CONTENT  #文本最多二十条
  LIMIT_CONVERSATION = 10 unless const_defined? :LIMIT_CONVERSATION #list好友最多10个
  
  #获得好友列表
  def self.get_list(zone, pid)
    r = redis zone
    clist = r.zrevrange(list_key(zone, pid), 0, -1)
    clist = clist.map do |x|
      player = Player.read_by_id(x, zone)
      next if player.nil?
      { 'pid' => x, 
        'name' => player.name,
        'icon' => player.icon,
        'icon_frame' => player.icon_frame,
        'level' => player.level,
        'vip_level' => player.vip_level}
    end
    clist
  end
  
  #得到好友的所有聊天信息
  def self.get_contents(zone, pid, fid)
    r = redis zone
    r.lrange(content_key(zone, pid, fid), 0, -1)
  end
  #得到好友的未读信息数量
  def self.get_unread(zone, pid)
    r = redis zone
    r.hgetall(unread_key(zone, pid))
  end

  ADD_MESSAGE = %Q{
    local lKeyMy, cKeyMy, lKeyFrd, cKeyFrd, uKeyFrd = unpack(KEYS)
    local pid, fid, msg, tm, limitL, limitC = unpack(ARGV)

    --operate self
    redis.call('zadd', lKeyMy, tm, fid)
    redis.call('zremrangebyrank', lKeyMy, 0, -(limitL+1))

    redis.call('rpush', cKeyMy, msg)
    redis.call('ltrim', cKeyMy, -limitC, -1)

    --operate friend
    redis.call('zadd', lKeyFrd, tm, pid)

    redis.call('rpush', cKeyFrd, msg)
    redis.call('ltrim', cKeyFrd, -limitC, -1)

    redis.call('hincrby', uKeyFrd, pid, 1)

    return 0
  }
  #添加一条来消息 给自己的数据库存储一条 同时给好友增加一条 并添加未读，好友在查看消息的时候 再设置已读
  def self.add_message(zone, pid, fid, msg)
    tm = Time.now.to_i
    lkeyMy = list_key(zone, pid)
    ckeyMy = content_key(zone, pid, fid)

    lkeyFrd = list_key(zone, fid)
    ckeyFrd = content_key(zone, fid, pid)
    ukeyFrd = unread_key(zone, fid)

    r = redis zone
    r.evalsmart(ADD_MESSAGE,
      :keys => [lkeyMy, ckeyMy, lkeyFrd, ckeyFrd, ukeyFrd],
      :argv => [pid, fid, msg, tm, LIMIT_CONVERSATION, LIMIT_CONTENT])
  end

  DEL_CONVERSATION =%Q{
    local lKey, cKey, uKey = unpack(KEYS)
    local fid = unpack(ARGV)
    redis.call('zrem', lKey, fid)
    redis.call('del', cKey)
    redis.call('hdel', uKey, fid)
    return 0
  }
  
  #删除好友(包括聊天信息、好友、未读信息)
  def self.del_conversation(zone, pid, fid)
    lKey = list_key(zone, pid)
    cKey = content_key(zone, pid, fid)
    uKey = unread_key(zone, pid)
    r = redis zone
    r.evalsmart(DEL_CONVERSATION, 
      :keys => [lKey, cKey, uKey],
      :argv => [fid])
  end

  DEL_UNREAD = %Q{
    local uKey = unpack(KEYS)
    local fid = unpack(ARGV)
    redis.call('hdel', uKey, fid)
    local all = redis.call('hgetall', uKey)
    return all
  }
  #删除好友的未读消息
  def self.del_unread(zone, pid, fid)
    uKey = unread_key(zone, pid)
    r = redis zone
    r.evalsmart(DEL_UNREAD, 
      :keys => [uKey],
      :argv => [fid])
  end

  private

  def self.redis zone
    get_redis zone
  end

  def self.tag key
    redis_key_by_tag key, 'friend_chat'
  end
  
  def self.key_with_tag(zone)
    @booth ||= Nest.new(redis_key_by_tag('friend_chat'), redis(zone))
  end

  #sorted set member 是 zone_pid_fid, score是最近更新的时间
  # def self.list_key(zone, pid)
  #   return tag "frd_chat_list:z:#{zone}:u:#{pid}"
  # end

  # #list msgs
  # def self.content_key(zone, pid, fid)
  #   return tag "frd_chat_content:z:#{zone}:u:#{pid}:f:#{fid}"
  # end

  # #hash fid => unread count
  # def self.unread_key(zone, pid)
  #   return tag "frd_chat_unread:z:#{zone}:u:#{pid}"
  # end

  #sorted set member 是 zone_pid_fid, score是最近更新的时间
  def self.list_key(zone, pid)
    key_with_tag(zone)['list_key'][zone][pid]
  end

  #list msgs
  def self.content_key(zone, pid, fid)
    key_with_tag(zone)['content_key'][zone][pid][fid]
  end

  #hash fid => unread count
  def self.unread_key(zone, pid)
    key_with_tag(zone)['unread_key'][zone][pid]
  end
end
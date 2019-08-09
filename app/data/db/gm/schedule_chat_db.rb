class ScheduleChatDB

	include RedisHelper
  include Loggable
  include Cacheable

  gen_static_cached 60 * 60 * 24 * 2, :get_all_chats
  gen_static_invalidate_cache :get_all_chats

  ADD_CHAT = %{
  	local key = unpack(KEYS)
  	local chat = unpack(ARGV)
  	local len = redis.call('llen', key)
  	if len >= 10 then
  		return false
  	end

    redis.call('lpush', key, chat)
    return true
  }
  def self.add(chat)
  	chat = chat.to_json
  	suc = redis.evalsmart(ADD_CHAT, keys: [key], argv: [chat])
  	if suc 
	  	Channel.publish_system_invalidate_cache(ScheduleChatDB, 'get_all_chats')
	  end
	  suc
  end

  REMOVE_CHAT = %{
  	local key = unpack(KEYS)
  	local index = unpack(ARGV)
  	local chat = redis.call('lindex', key, tonumber(index))
  	if chat then
	  	redis.call('lrem', key, 0, chat)
	  end
  }
  def self.remove(index)
  	redis.evalsmart(REMOVE_CHAT, keys: [key], argv: [index])
  	Channel.publish_system_invalidate_cache(ScheduleChatDB, 'get_all_chats')
  end

  def self.get_all_chats
  	js_chats = redis.lrange(key, 0, -1)
  	return [] if js_chats.nil?
  	js_chats.map { |js| ScheduleChat.new().from_json!(js)}
  end

  def self.update zones
  	chats = get_all_chats_cached
		chats.each do |chat|
			chat.check_send_msg(zones)
		end
  end

  private

  def self.redis
    get_redis(:action)
  end

  def self.key
    @chat ||= Nest.new(redis_key_by_tag('schedulechat'), redis)
  end
end
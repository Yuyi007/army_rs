class MatchingPoolsDB
	include RedisHelper
  include Loggable
  include Cacheable

  gen_static_cached 60, :get_all_pools
  gen_static_invalidate_cache :get_all_pools

  def self.get_all_pools
  	data = redis.call('hvals', pools_key)
  	data.map do |js_pool|
  		PoolProfile.new.from_json!( js_pool )
  	end
  end

  def self.gen_pool_id
  	ids = redis.call( 'hkeys', pools_key )
  	i = 0
  	while(true) do 
  		break if(! ids.include?(i.to_s))
  		i += 1
  	end
  	return i.to_s
  end

  def self.set_pool(pool)
  	id = pool.id
		id = gen_pool_id if id.nil?
		js_pool = pool.to_json
		redis.call( 'hset', pools_key, id.to_s, js_pool)
		
		notifyPoolsChange()
  end

  def self.notifyPoolsChange
  	Channel.publish_system_invalidate_cache(MatchingPoolsDB, 'get_all_pools')
		CSRouter.broadcast_to_checkers(MatchManager, {:cmd => "reload_pools"})
  end

  def self.get_pool(id)
  	js_pool = redis.call( 'hget', pools_key, id.to_s)
  	PoolProfile.new.from_json!(js_pool)
  end

  def self.del_pool(id)
  	redis.call( 'hdel', pools_key, id.to_s)
  	notifyPoolsChange
  end

 private

  def self.redis
    get_redis()
  end

  def self.matching
    @matching ||= Nest.new(redis_key_by_tag('matching'), redis)
  end

  def self.pools_key
    matching['pools_set']
  end
end
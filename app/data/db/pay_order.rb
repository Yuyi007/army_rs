class PayOrder
  ID_RANGE = 1_000_000_000

  attr_accessor :id
  attr_accessor :cid
  attr_accessor :pid
  attr_accessor :zone
  attr_accessor :trans_id
  attr_accessor :goods_id
  attr_accessor :time
  attr_accessor :platform
  attr_accessor :sdk
  attr_accessor :market
  attr_accessor :location
  attr_accessor :dispatched
  attr_accessor :credits
  attr_accessor :price

  include Loggable
  include Jsonable
  include Cacheable
  include RedisHelper

  gen_to_hash
  gen_from_hash

  def initialize(id = nil)
    self.id = id
    self.dispatched = false
  end

  def self.gen_id
    uuid = SecureRandom.uuid
    "#{AppConfig.server_env}.#{uuid}"
  end

  def self.key
    @key = Nido.new('payorder')
  end

  def self.redis
    get_redis(:user)
  end

  def self.redis_hash
    RedisHash.new(redis, key, PayOrder)
  end

  def self.get(id)
    redis_hash.hget(id)
  end

  def redis_hash
    self.class.redis_hash
  end

  def save
    redis_hash.hset(id, self)
  end

  def delete!
    redis_hash.hdel(id)
  end

end
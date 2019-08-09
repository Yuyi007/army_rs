class PayDb
  include Loggable
  include RedisHelper

  def self.redis
    get_redis(:user)
  end

  def self.key
    @key ||= Nido.new('pay:record')
  end

  def self.incr_pay(user_id, cid, pid, value)
    redis.hincrby(key[:user], user_id, value) if user_id
    redis.hincrby(key[:cid], cid, value) if cid
    redis.hincrby(key[:pid], pid, value) if pid
  end

  def self.get_record_by_user_id(user_id)
    redis.hget(key[:user], user_id) || 0
  end

  def self.get_record_by_cid(cid)
    redis.hget(key[:cid], cid) || 0
  end

  def self.get_record_by_pid(pid)
    redis.hget(key[:pid], pid) || 0
  end

  def self.dump_json
    hash = {
      'user' => {},
      'cid' => {},
      'pid' => {},
    }
    redis.hgetall(key[:user]).each do |k, v|
      hash['user'][k] = v
    end
    redis.hgetall(key[:cid]).each do |k, v|
      hash['cid'][k] = v
    end
    redis.hgetall(key[:pid]).each do |k, v|
      hash['pid'][k] = v
    end
    File.open('/tmp/pay_record.json', 'w+') do |f|
      f.write(JSON.generate(hash))
    end
  end

  def self.dump_json2
    hash = {}
    redis.hgetall(key[:user]).each do |k, v|
      hash[k] = v.to_i
    end
    hash
  end

end

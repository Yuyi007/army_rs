#UploadGameLog gen from template by command rake handler_add

class UploadGameLog < Handler

  include RedisHelper

  DEFAULT_AUTO_LOG_EXPIRE = 30 * 24 * 3600

  def self.process(session, msg, model)
    is_auto_log = msg['isAutoLog']
    logs_arr = msg['allLogs']
    if msg['errLogs']
      logs_arr << '----------------------- error logs start ----------------------'
      logs_arr += msg['errLogs']
    end

    log_str = logs_arr.join("\n\n")
    if is_auto_log
      redis.set(auto_key(model.chief.id), log_str, :ex => DEFAULT_AUTO_LOG_EXPIRE)
    else
      redis.lpush(key(model.chief.id), log_str)
    end
    res = {"success" => true}
    res
  end

  def self.key(cid)
    "uploaded:game:log:list:#{cid}"
  end

  def self.auto_key(cid)
    "auto:uploaded:game:log:list:#{cid}"
  end

  def self.redis
    return @@redis if defined? @@redis and @@redis
    return get_redis :user
  end

  def self.get_auto_log(cid)
    dkey = auto_key(cid)
    res = redis.get(dkey)
    return res
  end

  def self.blpop(cid)
    dkey = key(cid)
    res = redis.blpop(dkey, 10)
    redis.del(dkey)
    return res
  end

end
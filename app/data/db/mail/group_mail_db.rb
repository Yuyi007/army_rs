class GroupMailDb
  include RedisHelper

  TYPE_PERMANENT = 'permanent_mail' unless const_defined? :TYPE_PERMANENT
  TYPE_GROUP = 'all_mail' unless const_defined? :TYPE_GROUP

  CLEAN_INTERVAL = 60 unless const_defined? :CLEAN_INTERVAL

  def self.get_all_mails()
    redis().hgetall(mail_key()).map do |id, raw|
      Oj.load(raw)
    end
  end

  def self.get_mail(id)
    raw = redis().hget(mail_key(), id.to_s)
    return Oj.load(raw)
  end

  def self.add_mail(options)
    value = {}
    value['id'] = gen_id().to_s
    value['type'] = options.type
    value['start_time'] = options.start_time
    value['end_time'] = options.end_time
    value['min_lv'] = options.min_lv
    value['max_lv'] = options.max_lv
    value['zones'] = options.zones
    value['to_pid'] = options.to_pid
    value['mail'] = options.mail
    redis.hset(mail_key(), value['id'], Oj.dump(value))
  end

  def self.del_mail(id)
    redis.hdel(mail_key(), id.to_s)
  end

  def self.update_mail(options)
    value = {}
    value['id'] = options.id.to_s
    value['type'] = options.type
    value['start_time'] = options.start_time
    value['end_time'] = options.end_time
    value['min_lv'] = options.min_lv
    value['max_lv'] = options.max_lv
    value['zones'] = options.zones
    value['to_pid'] = options.to_pid
    value['published'] = options.published
    value['mail'] = options.mail
    redis.hset(mail_key(), value['id'], Oj.dump(value))
  end

  def self.clean_expired_mails()
    mails = get_all_mails()
    now = Time.now().to_i
    mails.each do|data|
      if data.mail.send_type != TYPE_PERMANENT and ((not data.end_time) or data.end_time.to_i < now)
        del_mail(data.id)
      end
    end
  end
private
  def self.redis()
    get_redis :user
  end

  def self.id_key()
    "group_mail_id"
  end

  def self.mail_key()
    'group_mail_mail'
  end

  def self.gen_id()
    redis().incr(id_key())
  end
end
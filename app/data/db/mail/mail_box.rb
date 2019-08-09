class MailBox
  include RedisHelper
  LIMIT = 30 unless const_defined? :LIMIT
  EXPIRED_TIME = 30 unless const_defined? :EXPIRED_TIME
  RESTORE_LIMIT = 500 unless const_defined? :RESTORE_LIMIT

  TYPE_PERMANENT = 'system_permanent' unless const_defined? :TYPE_PERMANENT
  TYPE_SYSTEM = 'system' unless const_defined? :TYPE_SYSTEM
  TYPE_MSG = 'message' unless const_defined? :TYPE_MSG
  TYPE_INFO = 'social' unless const_defined? :TYPE_INFO

  def self.all_types()
    # ['system', 'message', 'social', 'arena']
    ['system', 'message', 'social']
  end

  ADD_MAIL = %Q{
    local mail_key = KEYS[1]
    local read_key = KEYS[2]
    local redeem_key = KEYS[3]
    local sub_type_count_key = KEYS[4]
    local id = ARGV[1]
    local zone = ARGV[2]
    local mail_id = ARGV[3]
    local mail = ARGV[4]
    local limit = tonumber(ARGV[5])

    redis.call('lpush', mail_key, mail)
    redis.call('hset', read_key, mail_id, 1)
    redis.call('hset', redeem_key, mail_id, 1)
    redis.call('incr', sub_type_count_key)
    while tonumber(redis.call('llen', mail_key)) > limit do
      local m = redis.call('rpop', mail_key)
      if m  then
        local m_hash = cjson.decode(m)
        redis.call('hdel', read_key, m_hash.id)
        redis.call('hdel', redeem_key, m_hash.id)
        redis.call('decr', sub_type_count_key)
      end
    end
  }

  def self.deliver(id, zone, mail, given_time = nil)
    # if not check_mail_count_restrict(id, zone, mail.sub_type) then
    #   return
    # end

    # inc_mail_count(id, zone, mail.sub_type)
    #因为常驻邮件不能被其他邮件顶掉，所以必须赋予另外的type，但这个type只在服务端使用，对客户端它的type还是system
    if mail.send_type == GroupMailDb::TYPE_PERMANENT
      mail.type = 'system_permanent'
    end

    mail.send_type = 'specify_mail' if mail.send_type.nil?

    mail.time = Time.now.to_i
    mail.time = given_time.to_i if given_time
    type = mail.type
    mail.id = gen_id(id, zone)
    mail.toId = id
    sub_type = mail.sub_type
    sub_type = 'normal' if sub_type.nil?

    ActionDb.log_action(id, zone, 'deliver_mail', mail.to_json)

    redis(zone).evalsmart(ADD_MAIL,
      :keys => [
        mail_key(id, zone, type),
        mail_read_key(id, zone, type),
        mail_redeem_key(id, zone, type),
        mail_sub_type_total_count_key(id, zone, sub_type)
      ],
      :argv => [
        id,
        zone,
        mail.id,
        mail.to_json,
        LIMIT
      ])
  end

  def self.deliver_self(model, mail, given_time = nil)
    # if not check_mail_count_restrict(model.chief.id, model.chief.zone, mail.sub_type) then
    #   return
    # end

    inc_mail_count(model.chief.id, model.chief.zone, mail.sub_type)
    #因为常驻邮件不能被其他邮件顶掉，所以必须赋予另外的type，但这个type只在服务端使用，对客户端它的type还是system
    if mail.send_type == GroupMailDb::TYPE_PERMANENT
      mail.type = 'system_permanent'
    end

    mail.send_type = 'specify_mail' if mail.send_type.nil?

    mail.time = Time.now.to_i
    mail.time = given_time.to_i if given_time
    type = mail.type
    mail.id = gen_id(model.chief.id, model.chief.zone)
    mail.toId = model.chief.id

    ActionDb.log_action(model.chief.id, 
                        model.chief.zone, 
                        'deliver_self_mail', mail.to_json)

    if mail.sub_type then
      redis(model.chief.zone).incr(mail_sub_type_total_count_key(model.chief.id, model.chief.zone, mail.sub_type))
    end
    # model.deliver_self_mail(mail)
  end

  def self.check_mail_count_restrict(id, zone, sub_type)
    count = redis(zone).get(mail_sub_type_count_key(id, zone, sub_type))
    if count then count = count.to_i end
    daily_count = redis(zone).get(mail_sub_type_daily_count_key(id, zone, sub_type))
    if daily_count then daily_count = daily_count.to_i end
    daily_time = redis(zone).get(mail_sub_type_daily_time_key(id, zone, sub_type))
    if daily_time then daily_time = daily_time.to_i end

    total_count = redis(zone).get(mail_sub_type_total_count_key(id, zone, sub_type))
    if total_count then total_count = total_count.to_i end


    reset_time = Helper.reset_time().to_i

    if count.nil? and daily_count.nil? and total_count.nil? then return true end
    if count then
      if GameConfig.mails[sub_type] and count >= GameConfig.mails[sub_type]['recv_count'].to_i and GameConfig.mails[sub_type]['recv_count'].to_i >= 0 then
        return false, 1
      end
    end

    if total_count
      return false, 3 if (GameConfig.mails[sub_type] and GameConfig.mails[sub_type]['recv_total_count'] and total_count >= GameConfig.mails[sub_type]['recv_total_count'].to_i and GameConfig.mails[sub_type]['recv_total_count'].to_i >= 0)
    end

    if daily_count
      if daily_time.nil? then return false, 2 end
      if daily_time >= reset_time then
        return false, 2 if (GameConfig.mails[sub_type] and  daily_count >= GameConfig.mails[sub_type]['recv_count_daily'].to_i and GameConfig.mails[sub_type]['recv_count_daily'].to_i >= 0)
      end
    end
    return true
  end

  def self.inc_mail_count(id, zone, sub_type)
    redis(zone).incr(mail_sub_type_count_key(id, zone, sub_type))
    daily_time = redis(zone).get(mail_sub_type_daily_time_key(id, zone, sub_type))
    reset_time = Helper.reset_time().to_i
    if daily_time.nil?
      redis(zone).set(mail_sub_type_daily_time_key(id, zone, sub_type), Time.now().to_i)
    else
      if daily_time.to_i >= reset_time then
        redis(zone).set(mail_sub_type_daily_time_key(id, zone, sub_type), Time.now().to_i)
      end
    end
    redis(zone).incr(mail_sub_type_daily_count_key(id, zone, sub_type))
  end

  #测试工具强行更改发送数量时间戳，慎用
  def self.clear_send_count_timestamp(id, zone, sub_type)
    return false if id.nil? or zone.nil? or sub_type.nil?
    daily_time = redis(zone).get(mail_sub_type_daily_time_key(id, zone, sub_type))
    return false if daily_time.nil?
    daily_time = daily_time.to_i - 86400
    redis(zone).set(mail_sub_type_daily_time_key(id, zone, sub_type), daily_time)
    return true
  end

  def self.remove(id, zone, mail_id, mail_type, send_type, model)
    type = mail_type
    if send_type == GroupMailDb::TYPE_PERMANENT
      type = 'system_permanent'
    end

    redis = redis(zone)
    key = mail_key(id, zone, type)
    mails = read_mails(id, zone, type, model)
    del_num = 0
    mails.each do|m|
      if m.id == mail_id then
        del_num = redis.lrem(key, 1, JSON.generate(m))
        if m.sub_type then
          redis(zone).decr(mail_sub_type_total_count_key(id, zone, m.sub_type))
        end
        redis.hdel(mail_read_key(id, zone, type), mail_id)
        redis.hdel(mail_redeem_key(id, zone, type), mail_id)
        break
      end
    end
    return del_num
  end

  def self.clear_infos(mails, read_infos, redeem_infos, id, zone, type)
    read_infos.each do|k, v|
      mid = nil
      mails.each do|mail|
        if mail.id.to_i == k.to_i
          mid = k
        end
      end
      if not mid
        redis(zone).hdel(mail_read_key(id, zone, type), k)
        if type == 'system'
          redis(zone).hdel(mail_read_key(id, zone, 'system_permanent'), k)
        end
      end
    end

    redeem_infos.each do|k, v|
      mid = nil
      mails.each do|mail|
        if mail.id.to_i == k.to_i
          mid = k
        end
      end
      if not mid
        redis(zone).hdel(mail_redeem_key(id, zone, type), k)
        if type == 'system'
          redis(zone).hdel(mail_redeem_key(id, zone, 'system_permanent'), k)
        end
      end
    end
  end

  def self.set_read(id, zone, mail_id, mail_type, send_type)
    if send_type == GroupMailDb::TYPE_PERMANENT
      mail_type = 'system_permanent'
    end

    redis(zone).hset(mail_read_key(id, zone, mail_type), mail_id, 0)
  end

  def self.set_redeem(id, zone, mail_id, mail_type, send_type)
    if send_type == GroupMailDb::TYPE_PERMANENT
      mail_type = 'system_permanent'
    end

    redis(zone).hset(mail_read_key(id, zone, mail_type), mail_id, 0)
    redis(zone).hset(mail_redeem_key(id, zone, mail_type), mail_id, 0)
  end

  def self.read_mails(id, zone, type, model)
    if type == 'system' then
      system_mails = redis(zone).lrange(mail_key(id, zone, type), 0, LIMIT).map do |mail|
                      Oj.load(mail)
                    end

      permanent_mails = redis(zone).lrange(mail_key(id, zone, 'system_permanent'), 0, LIMIT).map do |mail|
                          Oj.load(mail)
                        end
      permanent_mails.each{|mail| mail.type = 'system'}
      # self_mails = model.get_self_mails(type)
      # return system_mails + permanent_mails + self_mails
      return system_mails + permanent_mails
    else
      mails = redis(zone).lrange(mail_key(id, zone, type), 0, LIMIT).map do |mail|
        Oj.load(mail)
      end
      # self_mails = model.get_self_mails(type)
      # return mails + self_mails
      return mails
    end
  end

  def self.read_mail(id, zone, mail_id, mail_type, send_type, model)
    if send_type == GroupMailDb::TYPE_PERMANENT
      mail_type = 'system_permanent'
    end
    mail = nil
    mails = read_mails(id, zone, mail_type, model)
    #self_mails = model.get_self_mails(mail_type)
    #mails += self_mails
    mails.each do|m|
      if m.id == mail_id
        mail = m
      end
    end
    return mail
  end

  def self.read_infos(id, zone, type)
    if type == 'system'
      infos = {}
      rs1 = redis(zone).hgetall(mail_read_key(id, zone, type))
      rs2 = redis(zone).hgetall(mail_read_key(id, zone, 'system_permanent'))
      rs = rs1.merge(rs2)
      rs.each do|r|
        infos[r[0]] = r[1] if(r and r[0] and r[1])
      end
      return infos
    else
      infos = {}
      rs = redis(zone).hgetall(mail_read_key(id, zone, type))
      rs.each do|r|
        infos[r[0]] = r[1] if(r and r[0] and r[1])
      end
      return infos
    end
  end

  def self.redeem_infos(id, zone, type)
    if type == 'system'
      infos = {}
      rs1 = redis(zone).hgetall(mail_redeem_key(id, zone, type))
      rs2 = redis(zone).hgetall(mail_redeem_key(id, zone, 'system_permanent'))
      rs = rs1.merge(rs2)
      rs.each do|r|
        infos[r[0]] = r[1] if(r and r[0] and r[1])
      end
      return infos
    else
      infos = {}
      rs = redis(zone).hgetall(mail_redeem_key(id, zone, type))
      rs.each do|r|
        infos[r[0]] = r[1] if(r and r[0] and r[1])
      end
      return infos
    end
  end

  def self.get_already_acquired_ids(id, zone)
    ids = redis(zone).hgetall(mail_group_mail_get_key(id, zone))
    return ids
  end

  def self.add_already_acquired_ids(id, zone, mid)
    redis(zone).hset(mail_group_mail_get_key(id, zone), mid.to_s, mid.to_s)
  end

  def self.del_already_acquired_ids(id, zone, mid)
    redis(zone).hdel(mail_group_mail_get_key(id, zone), mid.to_s)
  end


  #update group mails and permanent mails
  #return deliver mail num
  def self.update_group_mails(model)
    deliver_num = 0
    deliver_mails = []

    lv = model.instance.level
    now = Time.now().to_i
    zone = model.chief.zone
    user_id = model.chief.id
    pid = model.instance.player_id

    ids = get_already_acquired_ids(user_id, zone)
    mails = GroupMailDb.get_all_mails()

    #mail_ids = []
    #mails.each do |data|
    #  mail_ids << data.id.to_s
    #end

    #不发送不满足条件的，过期的以及已经发送过的邮件
    mails.delete_if{|x| x.published.nil? or x.published.to_i == 0 or lv < x.min_lv.to_i or lv > x.max_lv.to_i or 
      (x.mail.send_type != GroupMailDb::TYPE_PERMANENT and (now < x.start_time.to_i or now > x.end_time.to_i)) or 
      (x.zones and ((x.zones != 'all') and (not x.zones.include?(zone)))) or ids[x.id.to_s] or 
      (x.to_pid and ((x.to_pid != 'all') and (not x.to_pid.include?(pid))))}

    mails.sort!{|a, b| a.id <=> b.id}   # 先取旧的

    mails.each do |m|
      m.mail['zone'] = zone
      #发送邮件
      # model.send_mail(m.mail)
      #MailBox.deliver(user_id, zone, m.mail)

      # 达到邮件上限不再发送
      break if mail_box_full(user_id, zone, m.mail['type'])

      deliver(user_id, zone, m.mail)
      add_already_acquired_ids(user_id, zone, m.id.to_s)

      deliver_num += 1
      deliver_mails << m.mail
    end

    #清除已发送记录中已经被清除的邮件的记录，防止该记录过长
    #ids.each do|k, v|
    #  if not mail_ids.include?(k.to_s)
    #    del_already_acquired_ids(user_id, zone, k.to_s)
    #  end
    #end
    return deliver_num, deliver_mails
  end

  def self.mail_box_full(user_id, zone, type)
    redis(zone).llen(mail_key(user_id, zone, type)) >= LIMIT
  end

  def self.expired(id, zone, mail_type, model)
    mails = read_mails(id, zone, mail_type, model)
    mails.each do |m|
      if m.time + 60 * 60 * 24 * EXPIRED_TIME < Time.now.to_i
        MailBox.remove(id, zone, m.id, mail_type, 'all_mail', model)
      end
    end
  end

  def self.mail_expired(id, zone, mail_type, model, mail_id)
    mails = read_mails(id, zone, mail_type, model)
    mails.each do |m|
      if m.id == mail_id
        if m.time + 60 * 60 * 24 * EXPIRED_TIME < Time.now.to_i
          return true
        end
      end
    end
    return false
  end

  def self.on_fetch_mail(mail)
    if mail.type == 'system_permanent'
      mail.type = 'system'
    end
    return mail
  end

private
  def self.redis(zone)
    get_redis zone
  end

  def self.mail_box(zone)
    @booth ||= Nest.new(redis_key_by_tag('mail_box'), redis(zone))
  end

  def self.mail_tag(key, id, zone)
    # the same tag guarantees the keys are in the same redis instance
    # so that lua scripts can operate on the keys
    redis_key_by_tag key, "mail:#{id}:#{zone}"
  end

  def self.mail_key(id, zone, type)
    mail_box(zone)["mail"][type][id][zone]
  end

  def self.mail_read_key(id, zone, type)       #   {mail_box}:mail_read:system:10000016:1
    mail_box(zone)["mail_read"][type][id][zone]
  end

  def self.mail_redeem_key(id, zone, type)
    mail_box(zone)["mail_redeem"][type][id][zone]
  end

  def self.mail_id_key(id, zone)
    mail_box(zone)["mail_id"][id][zone]
  end

  def self.mail_restore_key(id, zone, type)
    mail_box(zone)["mail_restore"][type][id][zone]
  end

  def self.mail_group_mail_get_key(id, zone)
    mail_box(zone)["mail_group_mail_get"][id][zone]
  end

  def self.mail_sub_type_count_key(id, zone, sub_type)
    mail_box(zone)["mail_sub_type_count"][id][zone][sub_type]
  end

  def self.mail_sub_type_daily_count_key(id, zone, sub_type)
    mail_box(zone)["mail_sub_type_daily_count"][id][zone][sub_type]
  end

  def self.mail_sub_type_daily_time_key(id, zone, sub_type)
    mail_box(zone)["mail_sub_type_daily_time"][id][zone][sub_type]
  end

  def self.mail_sub_type_total_count_key(id, zone, sub_type)
    mail_box(zone)["mail_sub_type_total_count"][id][zone][sub_type]
  end

  def self.gen_id(id, zone)
    redis(zone).incr(mail_id_key(id, zone))
  end
end
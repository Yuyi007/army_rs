class NotifyCenter
  include Loggable

  def self.notify(id, zone, message, given_time = nil)
    res = {}
    case message.class.to_s
    when 'MailMessage'
      # if message.sub_type and (not MailBox.check_mail_count_restrict(id, zone, message.sub_type)) then
      #   return
      # end
      # if message.sub_type == 'arena_combat_message'
      #   PvpHistory.add_arena_fight(id, zone, message.content)
      # elsif message.sub_type == 'rob_res'
      #   PvpHistory.add_rob_fight(id, zone, message.content.fight_info)
      # end
      # 必须保证邮箱未达到上限，否则不发送邮件
      if message.type and MailBox.mail_box_full(id, zone, message.type)
        return
      end
      MailBox.deliver(id, zone, message, given_time)
      #因为要notify到客户端，所以这里的type需要变更成system，这里的变更不会影响到数据库
      if message.send_type == GroupMailDb::TYPE_PERMANENT
        message.type = 'system'
      end
      # res['count'] = MailBox.no_read_count(id, zone, message.type)
      res['type'] = message.type
      res['message'] = message.to_hash
    when 'FriendRequest'
      res['type'] = 'friend_request'
      res['message'] = message.player_info.to_hash
    when 'FriendNew'
      res['type'] = 'friend_new'
      res['message'] = message.player_info.to_hash
    when 'FriendRemove'
      res['type'] = 'friend_remove'
      res['message'] = message.player_id
    when 'Receipt' # for notify payment success
      res['type'] = 'receipt'
      res['message'] = message.to_hash
    when 'FightInfo'
      case message.type
      when 'arena'
        message.time = Time.now.to_i
        res['message'] = Helper.deep_copy(message.to_hash)
        res['count']   = PvpHistory.add_arena_fight(id, zone, message)
        res['type'] = 'arena'
      end
    when 'RobResult'
      res['type'] = 'rob_res'
      res['message'] = message.to_hash
    end

    unless res.empty?
      d{ "message sent  : #{JSON.generate(res)}" }
      player_info = Player.read_by_uid(id, zone)
      if player_info.online
        d{"-- notify: #{id} #{zone}"}
        Channel.publish("u:#{id}", zone, res)
      else
        d{ "-- to notify: #{id} #{zone} not online" }
      end
    end

  end
private

  def self.redis(zone)
    get_redis zone
  end
end
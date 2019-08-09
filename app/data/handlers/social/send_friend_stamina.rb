class SendFriendStamina < Handler
  def self.process(session, msg, model)
    uid = msg.uid
    return ng('Invalid param') if uid.nil?
    zone = session.zone

    return ng('limit') if not model.social.stamina_sendable?(uid, zone)

    return ng('notfriend') if not SocialDb.is_friend?(model.chief.id, uid, model.chief.zone)

    res = {'success' => true}
    #send mail 
    stamina = GameConfig.chief_init_attrs['social_stamina_num']
    mail = MailMessage.new()
    mail.senderId = model.chief.id
    mail.toId = uid
    mail.type = 'social'
    mail.sub_type = 'social_stamina'
    mail.title = 'str_mail_frd_back_spirit_title'
    mail.content = 'str_mail_frd_back_spirit_content'
    mail.sender_info = {'name'=>model.chief.name, 'icon_id'=>model.chief.icon_id}
    mail.effect = 'bonus'
    mail.add_attachment('stamina', stamina)

    model.send_mail(mail, uid, zone, nil, true, false)

    next_send_time = model.social.send_stamina(uid, zone)

    #notify task proc
    model.task_fire('send_stamina', {})
    model.gen_task_res(res)

    res['id'] = uid
    res['last_reset_time'] = model.social.last_reset_time
    res['left_times'] = model.social.left_times
    res['stamina_send_time'] = next_send_time
    res
  end
end
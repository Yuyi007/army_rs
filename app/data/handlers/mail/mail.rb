class GetMails < Handler

  def self.process(session, msg, model)
    do_process(session, msg, model)
  end

  def self.do_process(session, msg, model)
    type = msg['type']
    res = {'success' => false}
    return ng('type_is_nil') if type.nil?
    return ng('mail_type_error') if ((not MailBox.all_types.include?(type)) and type != 'all')
    if type == 'all'
      res['mails'] = {}
      res['read_infos'] = {}
      res['redeem_infos'] = {}
      MailBox.all_types.each do |t|
        ms = MailBox.read_mails(session.player_id, session.zone, t, model)
        is = MailBox.read_infos(session.player_id, session.zone, t)
        rs = MailBox.redeem_infos(session.player_id, session.zone, t)

        #清除无用的read_infos信息
        MailBox.clear_infos(ms, is, rs, session.player_id, session.zone, t)
        res['mails'][t] = ms
        res['read_infos'][t] = is
        res['redeem_infos'][t] = rs
      end
      res['success'] = true
    else
      mails = MailBox.read_mails(session.player_id, session.zone, type, model)
      res['success'] = true
      res['mails'] = {}
      res['read_infos'] = {}
      res['redeem_infos'] = {}
      res['mails'][type] = mails
      #res['mails'] = mails.to_hash
      res['read_infos'][type] = MailBox.read_infos(session.player_id, session.zone, type)
      res['redeem_infos'][type] = MailBox.redeem_infos(session.player_id, session.zone, type)
    end
    res
  end
end


class SetRead < Handler

  def self.process(session, msg, model)
    do_process(session, msg, model)
  end

  def self.do_process(session, msg, model)
    res = {'success' => false}
    res['read_infos'] = {}
    res['removed'] = {}
    mail_id = msg['mail_id']
    mail_type = msg['mail_type']
    send_type = msg['send_type']
    del = msg['del']
    if del
      del_num = MailBox.remove(session.player_id, session.zone, mail_id, mail_type, send_type, model)
      return ng('error_mail') if del_num < 1
      res['removed'] = {'id' => mail_id, 'type' => mail_type}
    else
      MailBox.set_read(session.player_id, session.zone, mail_id, mail_type, send_type)
    end
    res['success'] = true
    res['read_infos'][mail_type] = MailBox.read_infos(session.player_id, session.zone, mail_type)
    return res
  end
end

class SetMailsRead < Handler
  
  def self.process(session, msg, model)
    do_process(session, msg, model)
  end

  def self.do_process(session, msg, model)
    res = {'success' => false}
    res['read_infos'] = {}
    res['removed'] = {}
    mail_ids = msg['mail_ids']

    del = msg['del']

    set_types = {}
    mails = {}

    mail_ids.each do |info|
      mail_id = info.mail_id
      if not mails[info.mail_type]
        mails[info.mail_type] = {}
        ms = MailBox.read_mails(session.player_id, session.zone, info.mail_type, model)
        ms.each do |m|
          mails[info.mail_type][m.id] = m
        end
      end
      if mails[info.mail_type][mail_id]
        if del
          MailBox.remove(session.player_id, session.zone, mail_id, info.mail_type, info.send_type, model)
          res['removed'] = {'id' => mail_id, 'type' => info.mail_type}
        else
          MailBox.set_read(session.player_id, session.zone, mail_id, info.mail_type, info.send_type)
        end
      end
      set_types[info.mail_type] = info.mail_type
    end
    res['success'] = true
    set_types.each do |k, v|
      res['read_infos'][k]   = MailBox.read_infos(session.player_id, session.zone, k)
    end
    return res
  end
end
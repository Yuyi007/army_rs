class RedeemItems < Handler

  def self.process(session, msg, model)
    do_process(session, msg, model)
  end

  def self.do_process(session, msg, model)
    res = {'success' => false, 'reason' => 'mails'}

    res['redeem_infos'] = {}
    res['read_infos'] = {}
    res['bonuses'] = []

    reason = 'mail_bonus'
    mail_ids = msg['mail_ids']
    instance = model.instance
    chief     = model.chief

    set_types = {}
    mails = {}
    b = {}

    redeemList = MailBox.redeem_infos(session.player_id, session.zone, 'system')

    mail_ids.each do|info|
      mail_id = info.mail_id
      if not mails[info.mail_type]
        mails[info.mail_type] = {}
        ms = MailBox.read_mails(session.player_id, session.zone, info.mail_type, model)
        ms.each do|m|
          mails[info.mail_type][m.id] = m
        end
      end
      if mails[info.mail_type][mail_id]
        if redeemList[mail_id.to_s] != '0'
        	next if MailBox.mail_expired(session.player_id, session.zone, info.mail_type, model, mail_id)

          ms2 = MailBox.read_mail(session.player_id, session.zone, mail_id, info.mail_type, info.send_type, model)
          things = ms2.content.things
          return ng('donot_have_bonus') if !(things.size > 0)

          MailBox.set_redeem(session.player_id, session.zone, mail_id, info.mail_type, info.send_type)
          reason = ms2.reason if ms2.reason
          ms2.content.things.each do|thing|
            bonus = instance.add_bonus(thing.params1, thing.params2.to_i, reason)

            if bonus.tid
              b[bonus.tid] = {} if !b[bonus.tid]
              b[bonus.tid] = bonus.to_hash
            elsif bonus[:tid]
              if !b[bonus[:tid]]
                b[bonus[:tid]] = {}
                b[bonus[:tid]]['tid'] = bonus[:tid]
                b[bonus[:tid]]['count'] = 0
              end
              b[bonus[:tid]]['count'] += thing.params2.to_i
            end
          end
        else
          return ng('have_redeem_yet')
        end
      end
      set_types[info.mail_type] = info.mail_type
    end

    return ng('mail_expired') if !(b.size > 0)
    b.each do |tid, value|
      res['bonuses'] << value
    end

    set_types.each do|k, v|
      res['redeem_infos'][k] = MailBox.redeem_infos(session.player_id, session.zone, k)
      res['read_infos'][k]    = MailBox.read_infos(session.player_id, session.zone, k)
    end

    res['success'] = true
    res
  end
end
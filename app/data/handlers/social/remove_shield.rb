class RemoveShield < Handler
  def self.process(session, msg, model)
    uid = msg.uid
    zone = session.zone

    return ng('invalidparam') if uid.nil?

    res = {'success' => true}
    if model.social.shield?(uid, zone)
      model.social.del_shield_frd(uid, zone)
      res['unshield'] = uid
    else
      return ng('notshield')
    end
    res
  end
end
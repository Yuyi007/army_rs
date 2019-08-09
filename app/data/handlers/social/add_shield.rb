class AddShield < Handler
  def self.process(session, msg, model)
    uid = msg.uid
    zone = session.zone

    return ng('invalidparam') if uid.nil?

    res = {'success' => true}
    if not model.social.shield?(uid, zone)
      success = model.social.add_shield_frd(uid, zone)
      return ng('overload') if not success
      res['shield'] = uid
    else
      return ng('alreadyshield')
    end

    res
  end
end
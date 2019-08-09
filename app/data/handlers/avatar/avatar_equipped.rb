class AvatarEquipped < Handler

  def self.process(session, msg, model)
    instance   = model.instance
    hid        = msg['hid']
    schemeNum  = msg['schemeNum']
    equipped   = msg['equipped']

    suc, data = instance.avatar_data.change_equipped(hid, schemeNum, equipped)
    if suc
      res = {'success' => true}
      res['hid']      = hid
      res['scheme']   = schemeNum
      res['equipped'] = data.to_hash
      # puts "res:#{res}"
      return res
    else
      return {'success' => false,  'reason' => data}
    end
  end

end
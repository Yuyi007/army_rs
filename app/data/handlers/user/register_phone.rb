class RegisterPhone < Handler

  def self.process(session, msg)
    phone = msg['phone']
    vcode = msg['vcode']
    password = msg['pass']

    ret = AccountMan.register_phone(phone, vcode)
    return ng("verification code invalid") if ret == false

    id = UserHelper.generate_id

    if msg['pass']
      pass = msg['pass'] 
    else
      pass = UserHelper.hash_pass(UserHelper.random_pass)
    end

    stat("-- register, #{id}, #{session.zone}, #{session.platform}, #{session.device_id}, #{session.sdk}")

    { 'success' => User.create_by_phone(id, pass, phone, phone), 'id' => id, 'pass' => pass }
  end

end

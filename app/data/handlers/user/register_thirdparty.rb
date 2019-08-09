class RegisterThirdparty < Handler

  def self.process(session, msg)
    userid = msg['userid']
    platform = msg['platform']
    id = UserHelper.generate_id
    email = "guest#{id}@yousi.com"
    pass = UserHelper.hash_pass(UserHelper.random_pass)
    stat("-- register guest, #{id}, #{session.zone}, #{session.platform}, #{session.device_id}, #{session.sdk}")
    { 'success' => User.create(id, pass, email), 'id' => id, 'pass' => pass, 'email' => email}
  end

end

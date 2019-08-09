# register.rb

class Register < Handler

  def self.process(session, msg)
    id = UserHelper.generate_id
    puts ">>>>>email:#{msg['email']}"
    puts ">>>>>pass:#{msg['pass']}"
    if msg['pass']
      pass = msg['pass'] # should be hashed in client already
    else
      pass = UserHelper.hash_pass(UserHelper.random_pass)
    end
    email = msg['email']
    
    
    
    stat("-- register, #{id}, #{session.zone}, #{session.platform}, #{session.device_id}, #{session.sdk}")
    { 'success' => User.create(id, pass, email), 'id' => id, 'pass' => pass }
  end

end

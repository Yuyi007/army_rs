# update_user.rb

class UpdateUser < Handler

  def self.process(session, msg)
    user = User.read(msg['id'])

    if user and user.pass == msg['pass']
      if user.email == nil and msg['email']
        # email can't be set twice
        user.email = msg['email']
      end
      if msg['new_pass']
        user.pass = msg['new_pass']
      end
      success = User.update(user)
    end

    { 'success' => success }
  end

end

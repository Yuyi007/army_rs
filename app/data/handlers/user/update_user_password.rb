# update_user_password.rb

class UpdateUserPassword < Handler

  def self.process(session, msg)
    phone = msg['phone']
    vcode = msg['vcode'] 
    user = User.read_by_email(phone)
    ret = AccountMan.register_phone(phone, vcode)
    return ng("verification code invalid") if ret == false
    if user == nil then
      success = false
    else
      user.pass = msg['new_pass']
      success = User.update(user)
    end
    { 'success' => success }
  end

end

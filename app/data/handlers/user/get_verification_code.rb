class GetVerificationCode < Handler

  def self.process(session, msg)
    phoneno = msg['phoneno']

    vcode = AccountMan.getVerificationCode(phoneno)
    res = {'code' => vcode, 'success' => true }

    res
  end

end

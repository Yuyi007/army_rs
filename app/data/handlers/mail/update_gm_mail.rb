class UpdateGmMail < Handler
  def self.process(session, msg, model)
    instance = model.instance
    num, mails = MailBox.update_group_mails(model)
    res = {"success" => true}
    res.num = num
    res
  end
end
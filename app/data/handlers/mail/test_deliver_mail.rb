class TestDeliverMail < Handler

  def self.process(session, msg, model)
    res = {'success' => false}
    mail = MailMessage.new()
    mail.toId = session.player_id
    mail.type = 'system'
    mail.sub_type = 'normal'
    mail.send_type = 'all_mail'
    mail.content = { 'text' => 'TestDeliverMail', 'things' => [], 'title_one' => 'test_test' }
    mail.time = Time.now.to_i
    mail.from_name = 'test_system'
    mail.zone = session.zone
    mail.reason = 'task_award'

    mail.add_attachment('ite1000002', 10)
    NotifyCenter.notify(session.player_id, session.zone, mail)

    res['success'] = true
    res
  end
end
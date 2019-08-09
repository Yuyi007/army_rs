class NotifAlertMailer < ActionMailer::Base

  default :from => "gm-tools@firevale.com"

  def simple_alert(receiver, title, text)
    @text = text

    mail(to: "#{receiver.name} <#{receiver.email}>",
      subject: "GM Tools Alert - #{title}")
  end

end

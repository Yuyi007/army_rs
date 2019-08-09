class SiteUserMailer < ActionMailer::Base
  
  default :from => "gm-tools@firevale.com"

  def verification_instructions(user)
    @verification_url = site_user_verification_url(user.perishable_token)

    mail(to: "#{user.username} <#{user.email}>", 
      subject: 'GM Tools Registration Email Verification')
  end

  def edit_user_warning(user, target_user, record)
    @user = user
    @target_user = target_user
    @record = record
    @detail_url = site_user_records_search_url + 
      "?site_user_name=#{user.username}&a=#{record.action}"

    mail(to: "#{user.username} <#{user.email}>",
      subject: 'GM Tools Edit User Warning')
  end

  def give_item_warning(user, record)
    @user = user
    @record = record
    @detail_url = site_user_records_search_url + 
      "?site_user_name=#{user.username}&a=#{record.action}"

    mail(to: "#{user.username} <#{user.email}>",
      subject: 'GM Tools Give Item Warning')
  end

end

# app/models/user_session.rb

class UserSession < Authlogic::Session::Base

  authenticate_with SiteUser

  find_by_login_method :find_by_username_or_email

  logout_on_timeout true
  remember_me_for 7.days

  consecutive_failed_logins_limit 50
  failed_login_ban_for 24.hours

  allow_http_basic_auth false

  validate :check_if_verified

  before_create :reset_persistence_token

  def reset_persistence_token
    record.reset_persistence_token
  end

private

  def check_if_verified
    errors.add(:base, "You have not yet verified your account") unless attempted_record
  end

end
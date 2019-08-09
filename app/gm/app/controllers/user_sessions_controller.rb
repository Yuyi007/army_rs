
class UserSessionsController < ApplicationController

  include RsRails

  include Statsable

  layout 'main'

  protect_from_forgery

  before_filter :require_no_user, :only => [ :new, :create ]
  before_filter :require_user,  :only => :destroy

  access_control do
    default :allow
  end

  def new
    @user_session = UserSession.new
    @needs_captcha = needs_captcha? request
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    @needs_captcha = needs_captcha? request

    if @needs_captcha
      unless verify_recaptcha(:model => @user_session, :message => 'Incorrect Captcha')
        render :action => :new
        return
      end
    end
    
    success = @user_session.save

    current_user = @user_session.site_user
    if current_user
      current_user.site_user_records.create(
        :action => 'login',
        :success => success,
        :param1 => current_user.current_login_ip,
      )
    end

    if success
      flash[:notice] = "Login successful!"
      stats_increment_global 'gm.user.login.success'
      redirect_back_or_default root_url
    else
      stats_increment_global 'gm.user.login.failure'
      render :action => :new
    end
  end

  def destroy
    current_user.site_user_records.create(
      :action => 'logout',
      :success => true,
      :param1 => current_user.current_login_ip,
    )

    current_user_session.destroy

    flash[:notice] = "Logout successful!"
    stats_increment_global 'gm.user.logout.success'
    redirect_back_or_default new_user_session_url
  end

private

  def needs_captcha? request
    time = (Time.now.to_i / 300).to_i
    ip_logins = Rack::Attack.cache.read("#{time}:logins/ip:#{request.ip}").to_i
    # puts "ip_logins=#{ip_logins}"
    (ip_logins > 15)
  end

end

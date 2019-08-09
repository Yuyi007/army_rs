
class ApplicationController < ActionController::Base

  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :set_locale, :set_default_url_options

  rescue_from 'Acl9::AccessDenied', :with => :access_denied

  helper_method :current_user_session, :current_user

  def index
  end

  def i18n
    cookies[:lang] = params[:lang]
    set_locale
    render :text => 'ok'
  end

  def access_denied
    if current_user
      flash[:error] = "Security problem!"
      respond_to do |format|
        format.html { render :denied }
        format.js {
          render :update do |page|
            page.render :denied
        end
        }
      end
    else
      flash[:notice] = "You have to be logged in to see this page"
      respond_to do |format|
        format.html {redirect_to new_user_session_url}
        format.js {
          render :update do |page|
            page.redirect_to new_user_session_url
          end
        }
      end
    end
  end

  def set_locale
    if cookies[:lang]
      I18n.locale = cookies[:lang]
    else
      logger.debug "* Accept-Language: #{request.env['HTTP_ACCEPT_LANGUAGE']}"
      I18n.locale = extract_locale_from_accept_language_header
      cookies[:lang] = I18n.locale
    end
    logger.debug "* Locale set to '#{I18n.locale}'"
  end

  def set_default_url_options
    SiteUserMailer.default_url_options[:host] = request.host_with_port
    NotifAlertMailer.default_url_options[:host] = request.host_with_port
  end

  # def ensure_worker_threads
  #   RsRails.ensure_worker_threads
  # end

  def curAuth
    current_user.role_ids[0]
  end

  def curUserInfo
    userInfo = {}
    userInfo['name'] = current_user.username
    userInfo['auth'] = curAuth
    userInfo
  end

  alias_method :cur_user, :curUserInfo

private

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.site_user
  end

  def require_user
    logger.debug "ApplicationController::require_user"
    unless current_user
      store_location
      flash[:notice] = "You must be logged in to access this page"
      redirect_to new_user_session_url
      return false
    end
  end

  def require_no_user
    logger.debug "ApplicationController::require_no_user"
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      # redirect_to home_index_path
      return false
    end
  end

  def store_location
    #session[:return_to] = request.request_uri
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def extract_locale_from_accept_language_header
    lang = request.env['HTTP_ACCEPT_LANGUAGE'] || 'zh-cn'
    lang.scan(/^[a-z]{2}/).first
  end

end

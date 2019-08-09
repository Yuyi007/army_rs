
class ConfigViewController < ApplicationController

  layout 'config'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0
  end

  set_tab :view_config



  def index
    @active = "view_link"
  end

  def load
    render :json => RsRails.loadGameConfig
  end

  def load_raw
    render :json => RsRails.loadRawGameConfig
  end

end
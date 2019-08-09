
class ConfigMarketController < ApplicationController

  layout 'config'

  protect_from_forgery

  before_filter :require_user
  
  access_control do 
    allow :admin, :p0
  end
  
  set_tab :market

  def index
  end

end
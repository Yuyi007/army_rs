
class ConfigItemsController < ApplicationController

  layout 'config'

  protect_from_forgery

  before_filter :require_user
  
  access_control do 
    allow :admin, :p0
  end
  
  set_tab :items

  def index
  end

end
# check_gmarket_controller.rb

class CheckGmarketController < ApplicationController
  layout 'check'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2, :p3
  end

  set_tab :check_gmarket



  def index
  	@configs = RsRails.getGmarketConfig
    @active = "gmarket_link"
  end

end
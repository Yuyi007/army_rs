# check_creditrankbonus_controller.rb

class CheckCreditrankbonusController < ApplicationController
  layout 'check'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2, :p3
  end

  set_tab :check_creditrankbonus



  def index
    @configs = RsRails.getCreditEventRankBonus
  end

end
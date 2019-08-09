# check_creditrankbonus_controller.rb

class CheckCreditRankBonusController < ApplicationController

  include RsRails

  layout 'check'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2, :p3
  end

  set_tab :check_credit_rank_bonus



  def index
    @configs = RsRails.getCreditEventRankBonus
    @active = "credit_link"
  end

end
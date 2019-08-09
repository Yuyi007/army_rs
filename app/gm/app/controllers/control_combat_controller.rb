class ControlCombatController < ApplicationController

  include RsRails

   layout 'main'

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2
  end

  protect_from_forgery

  def index
    @num=RsRails.num_online(1)
  end

  def list
    data=RsRails.get_combat_server_data
    if data then
      render :json => data
    else
      render :json => {}
    end
  end

  def get_zone_online_num
    zone= params[:zone]
    num=RsRails.num_online(zone)
    render :json => {:num_online => num}
  end
end
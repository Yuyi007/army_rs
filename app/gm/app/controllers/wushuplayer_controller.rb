
class WushuplayerController < EventsController

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2, :p3, :p4, :p5
  end

  include RsRails
  include ApplicationHelper

  def raw
    id = params[:id].to_i
    zone = params[:zone].to_i
    @allow_edit = (current_user.role_name == 'admin')
  end

  def load
    id = params[:id].to_i
    zone = params[:zone].to_i
    pids = []
    1.upto(3) do |i|
      pids << "#{zone}_#{id}_i#{i}"
    end
    wushuplayers = WushuPlayer.fetch(pids, zone, '1standard')
    res = {}
    wushuplayers.each do |wp|
      res["1v1_#{wp.pid}"] = wp if wp
    end
    wushuplayers = WushuPlayer.fetch(pids, zone, '2standard')
    wushuplayers.each do |wp|
      res["2v2_#{wp.pid}"] = wp if wp
    end
    render :json => res
  end
end

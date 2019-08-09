class ControlMatchingPoolsController < ApplicationController

  include RsRails

   layout 'main'

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2
  end

  protect_from_forgery

  @@timeout = 5*2

  def index
    @pools = {}
    all = MatchingPoolsDB.get_all_pools
    all.each do |v|
    	@pools[v.map_type] = @pools[v.map_type] || {}
    	mapts = @pools[v.map_type]
    	mapts[v.combat_type] = mapts[v.combat_type] || []
    	mapts[v.combat_type] << v
    end

    @pools.each do |_, mapts|
    	mapts.each do |_, pools|
    		pools.sort! {|a, b| a.score_min <=> b.score_min}
    	end
    end
    @matching_status=MatchManager.read_by_matching_closeflag()
    @room_status=CombatRoomStatusDB.read_room_close_flag()
  end

  def list
    mpList=[]
    now = Time.now.to_i
    zone=params[:zone].to_i
    tickList=MatchManager.read_by_matchpool_tick(zone)
    teamList=MatchManager.read_by_matchpool_team(zone)
    tickList.each do |key,value|  
      mp={}
      mp['pool_id']=key
      mp['tick']=value
      if now-value.to_i > @@timeout then
        mp['team_num']=0
        mp['status']=0
      else
        mp['team_num']=teamList[key]
        mp['status']=1
      end
      mpList << mp
    end
    if mpList then
      render :json => mpList
    else
      render :json => {}
    end
  end

  def set_matching_close_status
    status= params[:status].to_i
    MatchManager.save_by_matching_closeflag(status)
  	render :json => { 'success' => true }
  end

  def set_create_room_status
  	status= params[:status].to_i
  	CombatRoomStatusDB.save_room_close_flag(status)
  	render :json => { 'success' => true }
  end
end
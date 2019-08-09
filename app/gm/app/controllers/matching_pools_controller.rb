class MatchingPoolsController < ApplicationController
	include RsRails

  layout 'main'

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2
  end

  protect_from_forgery

	def list
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
  end

  def edit
  	id = params[:id]
  	@pool = MatchingPoolsDB.get_pool(id)
  end

  def new
  	id = MatchingPoolsDB.gen_pool_id
  	@pool = PoolProfile.new(id, MatchMapType::MT_COMPETITIVE, MatchCombatType::CT_3V3)
  end

  def save
  	id = params[:id]
  	score_min = params[:score_min].to_i
  	score_max = params[:score_max].to_i

  	map_type = params[:map_type].to_i
  	combat_type = params[:combat_type].to_i

  	name = params[:name]

  	pool = PoolProfile.new(id, map_type, combat_type, score_min, score_max)
  	MatchingPoolsDB.set_pool(pool)
  	render :json => { 'success' => true }
  end

  def delete
  	id = params[:id]
  	MatchingPoolsDB.del_pool(id)
  	render :json => { 'success' => true }
  end
end
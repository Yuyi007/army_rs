
class DataController < ApplicationController

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin
    allow :p0, :to => [ :batch_edit ]
    allow :p1, :p2, :p3, :p4, :to => [:query_guild, :guild_search ]    
    allow :p1, :p2, :p3, :p4, :p5, :to => [ :view, :history, :permission, :load, :export ]
  end

  include RsRails
  include ApplicationHelper

  def view
    id = params[:id].to_i
    zone = params[:zone].to_i

    if id and id.to_s.length > 0 and zone > 0
      @model = load_game_data(id, zone)
    else
      @model = nil
    end
  end

  def history
    player_id = params[:id].to_i
    zone = params[:zone].to_i
    time_s = TimeHelper.gen_date_time(Time.now - 3600 * ((player_id == 0 and zone.blank?) ? 1 : 72))
    time_e = TimeHelper.gen_date_time(Time.now)

    params[:player_id] = player_id; params[:id] = nil
    @logs = ElasticActionLog.search_by(params)
  end

  def raw
    id = params[:id].to_i
    zone = params[:zone].to_i
    @allow_edit = (current_user.role_name == 'admin')
  end

  def load
    id = params[:id].to_i
    zone = params[:zone].to_i
    model = load_game_data(id, zone)
    render :json => model.to_hash
  end

  def save
    id = params[:id].to_i
    zone = params[:zone].to_i
    object = ActiveSupport::JSON.decode(params[:model])

    success = save_game_data_hash_force(id, zone, object)
    notify_gm_edit(id, zone, success)

    current_user.site_user_records.create(
      :action => 'save_data',
      :success => success,
      :target => id,
      :zone => zone,
    )

    render :json => { 'success' => success }
  end

  def delete
    id = params[:id].to_i
    zone = params[:zone].to_i

    success = delete_game_data(id, zone)
    notify_gm_edit(id, zone, success)

    current_user.site_user_records.create(
      :action => 'delete_data',
      :success => success,
      :target => id,
      :zone => zone,
    )

    render :json => { 'success' => success }
  end

  def export
    id = params[:id].to_i
    zone = params[:zone].to_i
    model = load_game_data(id, zone)
    render :json => ActiveSupport::JSON.encode(model.to_hash)
  end

  def import
  end

  def query_guild
  end

  def guild_search
    guild_id = params[:guild_id]
    zone = params[:zone].to_i
    guild_name = params[:guild_name]
    if guild_name != ""
      gids = Guild.search_by_name(guild_name, zone, 1)
      guild_id = gids[0] if gids.size > 0
    end

    logger.info "guild_id=#{guild_id} guild_name=#{guild_name} zone=#{zone}"
    if guild_id != ""
      guild = Guild.get_cached(guild_id)
      logger.info "guild_id id search: #{guild_id}, #{guild}"
      if guild 
        render :json => {:success => true, :guild => guild}      
      else 
        render :json => {:success => false, :reason => "guild input not exist" }              
      end
    else 
      logger.info "guild_id info error"
      render :json => { :success => false, :reason => "no input data" }       
    end
  end

end

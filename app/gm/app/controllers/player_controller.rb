# player_controller.rb

class PlayerController < ApplicationController

  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0
    allow :p1, :p2, :p3, :p4 => [:index, :byName, :permission_list, :set_permission, :get_block_detail, :unlock_block]
  end

  def index
  end

  def byName
    name = params[:name]
    zone = params[:zone].to_i
    player = RsRails.player_by_name(name, zone)
    if player
      hash = player.to_hash
      hash['id'] = hash['cid']
      render :json => hash
    else
      render :json => {}
    end
  end

  def set_permission
    ids = params[:user_ids].split(",")
    logger.info ("set_permission ids:#{ids}")
    permission_type = params[:permission_type]
    ids.each do |sub_id|
      logger.info ("set_permission subid:#{sub_id}")
      PermissionDb.set_permission(sub_id, permission_type)
    end
    render :index
  end

  def permission_list
    res = PermissionDb.permission_list
    logger.info ("permission_list ids:#{res}")    
    if res
      render :json => res
    else
      render :json => {}
    end
  end

  def get_permission
    id = params[:id]
    logger.info ("get player permission:#{id}")        
    permission = PermissionDb.get_player_permission(id) 
    render :json => {:permission => permission}
  end

  def get_block_detail
    id = params[:id]
    return render :json => {:detail => []}     if id.nil? || id == ""
    id = id.split(",")[0]
    # logger.info ("get player get_block_detail :#{id}")        
    detail = AntiManipulationDb.get_block_detail(id) 
    return render :json => {:detail => []}     if detail.nil?
    logger.info ("get player get_block_detail :#{id}:#{detail}")        
    render :json => {:detail => detail}    
  end

  def unlock_block
    id = params[:id]
    return render :json => {:success => true}     if id.nil? || id == ""
    ids = id.split(",")
    ids.each do |sub_id|
      AntiManipulationDb.remove_block_user(sub_id) 
    end
    logger.info ("get player unlock :#{id}")        
    render :json => {:success => true}        
  end

  def set_player_permission
    id = params[:id]
    zone = params[:zone]    
    permission_type = params[:permission_type]
    permission = PermissionDb.set_permission(id, permission_type) 
    Channel.publish_system_disconnect_session(id.to_i, zone.to_i)
    render :json => {}
  end

  def kick
    id = params[:id].to_i
    zone = params[:zone].to_i
    Channel.publish_system_disconnect_session(id, zone)
    success = true
    render :json => {"success" => success}
  end

end
class UserLevelController < ApplicationController



  include RsRails

  def index
    render :json => { 'success' => true }
  end

  def query
    id = params[:id]
    zone = params[:zone].to_i

    player = RsRails.player_by_id(id, zone)

    if player
      render :json => { 'success' => true,
                        'level' => player.level,
                        'name' => player.name,
                        'vip_level' => player.vipLevel }
    else
      render :json => { 'success' => false, 'reason' => 'player doesn\'t exists' }
    end
  end

  def query2
    id = params[:uid]
    zone = params[:sid].to_i
    name = params[:uname]
    logger.info "id #{id} zone #{zone}"

    player = RsRails.player_by_id(id, zone)
    player ||= RsRails.player_by_name(name, zone)

    if player
      render :json => { 'retcode' => 0,
                        'retmsg' => player.to_s}
    else
      render :json => { 'retcode' => 1, 'retmsg' => 'fail' }
    end
  end

end
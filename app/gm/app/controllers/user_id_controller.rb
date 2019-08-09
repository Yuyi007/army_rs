class UserIdController < ApplicationController



  include RsRails

  def index
    render :json => { 'success' => true }
  end

  def query
    name = params[:name]
    zone = params[:zone].to_i

    player = RsRails.player_by_name(name, zone)

    if player
      render :text => "#{player.id}"
    else
      render :text => "unknown"
    end
  end

end
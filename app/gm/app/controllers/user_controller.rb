class UserController < ApplicationController

  include RsRails

   layout 'main'

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2
  end

  protect_from_forgery

  def index
    
  end

  def query
    type= params[:type]
    param= params[:param]
    if type == 'ids' then
      user = RsRails.user_by_id(param)
    elsif type == 'email'  then
      user = RsRails.user_by_email(param)
    elsif type == 'mobile' then
      user = RsRails.user_by_mobile(param)
    end
    if user
      render :json => user.to_hash
    else
      render :json => {}
    end
  end

  def query_player
    zone= params[:zone].to_i
    uid= params[:uid].to_i
    model = RsRails.load_game_data(uid, zone)
    if model
      render :json => model.to_hash
    else
      render :json => {}
    end
  end
end
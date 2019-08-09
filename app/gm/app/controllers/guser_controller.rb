# guser_controller.rb
# Game User controller

class GuserController < ApplicationController

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2, :p3
  end

  include RsRails

  def index
  end

  def by_id(id)
    user = User.read(id)
    if user
      render :json => user.to_hash
    else
      render :json => { 'id' => 0 }
    end
  end

  def by_email
    email = params[:email]
    user = User.read_by_email(email)
    if user
      render :json => user.to_hash
    else
      render :json => { 'id' => 0 }
    end
  end

end

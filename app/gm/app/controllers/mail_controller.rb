# push_controller.rb

class MailController < ApplicationController

  include RsRails

  layout 'main'

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2
  end

  protect_from_forgery



  def index
  end

  def send_mail
    text = params[:mailText]
    zone = params[:zone].to_i
    userId = params[:userId]
    success = RsRails.send_mail(zone, userId, text)

    render :json => { 'success' => success }
  end

end
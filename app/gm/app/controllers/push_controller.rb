# push_controller.rb

class PushController < ApplicationController

  include RsRails

  layout 'main'

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2
  end

  protect_from_forgery

  def index
  end

  def apple
    apToken = params[:apToken]
    apText = params[:apText]
    apBadge = params[:apBadge] or 0
    apSound = params[:apSound] or ''
    apSandbox = params[:apSandbox] or false


    success, count = PushHelper.pushApple(apToken.downcase,
      :alert => apText,
      :badge => apBadge,
      :sound => apSound,
      :sandbox => apSandbox)

    current_user.site_user_records.create(
      :action => 'apple_push',
      :success => success,
      :param1 => "sandbox=#{apSandbox}",
      :param2 => "token=#{apToken.to_s.empty? ? 'all' : apToken}, count=#{count}",
      :param3 => "message=#{apText}",
    )

    render :json => { 'success' => success, 'count' => count }
  end

end
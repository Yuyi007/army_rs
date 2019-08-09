class NoticeController < ApplicationController

  include RsRails
  include Cacheable
  include Configurable

  gen_proxy_config :notice

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2, :p3, :p4
  end

  def list
    @notices = get_notice_configs
  end

  def new
    @notice = {'tid' => 0}
  end

  def delete
    id = params[:id].to_i
    delete_notice_config(id)
    redirect_to notice_list_url
  end

  def deleteAll
    @notices = get_notice_configs
    # puts "=1111=#{@notices.class}=="
    @notices.each do |n|
      delete_notice_config(n.id)
    end
    redirect_to notice_list_url
  end

  def edit
    id = params[:id]
    @notice = get_notice_config(id)
  end

  def update
    o = params[:notice]
    logger.error(o)
    save_notice_config(o)
    redirect_to notice_list_url
  end

  def create
    o = params[:notice]
    create_notice_config(o)
    redirect_to notice_list_url
  end

  def mailNotice
    sendMailNotice
    render :json => { 'success' => true }
  end

end

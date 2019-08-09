# The new action log using elasticsearch

class ElasticActionLogController < ApplicationController

  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2, :p3, :p4
    # allow :admin, :p0, :p1, :p2, :p3, :p4 => [ :index, :search ]
  end

  def index
    params[:per_page] ||= cookies[:action_log_per_page]
    params[:time_s] ||= TimeHelper.gen_date_time(Time.now - 3600 * 1)
    params[:time_e] ||= TimeHelper.gen_date_time(Time.now)

    @logs = ElasticActionLog.search_by(params)

    render :search
  end

  def search
    if params[:per_page]
      cookies[:action_log_per_page] = params[:per_page]
    else
      params[:per_page] = cookies[:action_log_per_page]
    end

    @logs = ElasticActionLog.search_by(params)
  end

end

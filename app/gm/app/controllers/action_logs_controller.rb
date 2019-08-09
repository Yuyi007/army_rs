
class ActionLogsController < ApplicationController

  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin
    allow :admin, :p0, :p1, :p2, :p3 => [ :index, :search ]
  end

  def index
    sort = params[:sort]
    direction = params[:direction]
    sort = (not sort.nil? or ActionLog.column_names.include? sort) ? sort : 'created_at'
    direction = (direction.nil? or direction.downcase == 'desc') ? 'desc' : 'asc'

    params[:created_at_s] ||= TimeHelper.gen_date_time(Time.now - 3600 * 1)
    params[:created_at_e] ||= TimeHelper.gen_date_time(Time.now)
    params[:per_page] ||= ActionLog.per_page

    @logs = ActionLog.where('created_at >= :created_at_s AND created_at <= :created_at_e',
      { :created_at_s => params[:created_at_s], :created_at_e => params[:created_at_e] })
      .order("#{sort} #{direction}")
      .paginate(:page => params[:page], :per_page => params[:per_page])

    render :search
  end

  def search
    if params[:created_at_s].blank? and params[:created_at_e].blank?
      params[:created_at_s] = TimeHelper.gen_date_time(Time.now - 3600 * 1)
      params[:created_at_e] = TimeHelper.gen_date_time(Time.now)
    end

    @logs = ActionLog.search(
      params[:player_id],
      params[:zone],
      params[:t],
      params[:created_at_s],
      params[:created_at_e],
      params[:param1],
      params[:param2],
      params[:param3],
      params[:param4],
      params[:param5],
      params[:param6],
      params[:sort],
      params[:direction],
      params[:page],
      params[:per_page],
      )
  end

  def manage
    @remain_log_count = ActionDb.remain_log_count
  end

  def process_remain_logs
    processed = ActionLog.process_remain_logs

    current_user.site_user_records.create(
      :action => 'process_remain_logs',
      :success => true,
      :param1 => processed
    )

    flash[:notice] = 'Succeed!'

    render :manage
  end

  def delete_old
    days = params[:days]

    if days.to_i > 7
      deleted = ActionLog.delete_old days

      current_user.site_user_records.create(
        :action => 'delete_old_action_logs',
        :success => true,
        :param1 => days,
        :param2 => deleted ? deleted.length : 0
      )

      flash[:notice] = 'Succeed!'
    else
      flash[:error] = 'Days must be larger than 7!'
    end

    render :manage
  end

end
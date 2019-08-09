class SiteUserRecordsController < ApplicationController

  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin
    allow :p0, :p1 => [:index, :search]
  end

  def index
    sort = params[:sort]
    direction = params[:direction]
    sort = (not sort.nil? or SiteUserRecord.column_names.include? sort) ? sort : 'created_at'
    direction = (direction.nil? or direction.downcase == 'desc') ? 'desc' : 'asc'

    @records = SiteUserRecord.order("#{sort} #{direction}")
      .paginate(:page => params[:page], :per_page => params[:per_page])

    render :search
  end

  def new
    @record = SiteUserRecord.new
  end

  def create
    @record = SiteUserRecord.new(params[:record])
    @record.save
  end

  def show
    @record = SiteUserRecord.find(params[:id])
  end

  def edit
    @record = SiteUserRecord.find(params[:id])
  end

  def update
    @record = SiteUserRecord.find(params[:id])
    if @record.update_attributes(params[:record])
      flash[:notice] = "SiteUserRecord updated!"
      redirect_to edit_record_url(@user)
    else
      flash[:error] = "SiteUserRecord updated failed!"
      render :action => :edit
    end
  end

  def search
    if params[:site_user_name]
      params[:site_user_id] = SiteUser.find_by_username_or_email(params[:site_user_name])
    end

    @records = SiteUserRecord.search(
      params[:site_user_id],
      params[:a],
      params[:target],
      params[:zone],
      params[:tid],
      params[:created_at_s],
      params[:created_at_e],
      params[:sort],
      params[:direction],
      params[:page],
      params[:per_page],
      )
  end

end

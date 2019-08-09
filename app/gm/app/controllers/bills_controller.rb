class BillsController < ApplicationController

  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :require_user

   http_basic_authenticate_with :name => "firevale", :password => 'fire$8899#vale', :only => :total

  access_control do
    allow :admin, :p0, :p1, :p2  # :p3, :p4, :p5
    allow :p3, :p4, :to => [ :low_search ]
  end

  def index
    sort = params[:sort]
    direction = params[:direction]
    sort = (not sort.nil? or Bill.column_names.include? sort) ? sort : 'created_at'
    direction = (direction.nil? or direction.downcase == 'desc') ? 'desc' : 'asc'

    @bills = Bill.order("#{sort} #{direction}")
      .paginate(:page => params[:page], :per_page => params[:per_page])
    render :search
  end


  def low_search
    if params[:transId].blank? && params[:playerId].blank?
      @bills = Bill.empty_ret
      # render :json => { 'success' => false, 'reason' => 'Both player id and transId empty' } 
    elsif !params[:playerId].blank? && params[:zone].blank?
      @bills = Bill.empty_ret
      # render :json => { 'success' => false, 'reason' => 'Zone must not empty' } 
    else
      sort = params[:sort]
      direction = params[:direction]
      sort = (not sort.nil? or Bill.column_names.include? sort) ? sort : 'created_at'
      direction = (direction.nil? or direction.downcase == 'desc') ? 'desc' : 'asc'

      @bills = Bill.search(
        '',
        '',
        params[:playerId],
        params[:zone],
        '',
        params[:transId],
        params[:created_at_s],
        params[:created_at_e],
        'created_at',
        'desc',
        params[:page],
        params[:per_page],
        )
    end
  end

  def search
    @bills = Bill.search(
      params[:sdk],
      params[:platform],
      params[:playerId],
      params[:zone],
      params[:goodsId],
      params[:transId],
      params[:created_at_s],
      params[:created_at_e],
      params[:sort],
      params[:direction],
      params[:page],
      params[:per_page],
      )
  end

  def total
    @bills = Bill.search(
      params[:sdk],
      params[:platform],
      params[:playerId],
      params[:zone],
      params[:goodsId],
      params[:transId],
      params[:created_at_s],
      params[:created_at_e],
      params[:sort],
      params[:direction],
      params[:page],
      params[:per_page],
      )

    render :total
  end


end

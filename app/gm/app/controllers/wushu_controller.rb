class WushuController < ApplicationController
  include RsRails
  include Cacheable
  include Configurable

  layout 'main'

  protect_from_forgery
  include Eventable

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1 #, :p2, :p3
  end

  def list
    @wushu_list = WushuPvp.all.to_a.to_data
    @wushu_list.each do |o|
      o.prepare_time = parse_time_simple(o.prepare_time)
      o.end_time = parse_time_simple(o.end_time)
      o.start_time = parse_time_simple(o.start_time)
      o.types.delete_if{|x| x == '1train' || x == '2train'}
      o.types = o.types.map { |x| n = CampaignHelper.wushu_type_to_num(x); n == 1 ? '单人' : '双人' }
    end
  end

  def new
    @wushu = WushuPvp.new.to_data
    now = Time.now.to_i
    @wushu.prepare_time = now
    @wushu.start_time = now
    @wushu.end_time = now
    parse_to_display(@wushu)
  end

  def delete
    id = params[:id].to_s
    WushuPvp.delete_wushu(id)
    redirect_to wushu_list_url
  end

  def to_array(s)
    s.strip.split(/[,;]/)
  end

  def to_int_array(s)
    list = to_array(s)
    list.map(&:to_i)
  end

  def edit
    id = params[:id].to_s
    @wushu = WushuPvp[id].to_data
    parse_to_display(@wushu)
  end

  def update
    o = params[:wushu]
    parse_to_data(o)

    suc, reason = WushuPvp.validate_update?(o)

    if suc
      flash[:success] = 'saved'
      WushuPvp.update_wushu(o)
      redirect_to wushu_list_url
    else
      flash[:error] = reason
      redirect_to :back
    end
  end

  def parse_to_display(o)
    o.single = '1' if o.types.include?('1standard')
    o.double = '1' if o.types.include?('2standard')

    o.prepare_time = parse_time_simple(o.prepare_time)
    o.end_time = parse_time_simple(o.end_time)
    o.start_time = parse_time_simple(o.start_time)
    o
  end

  def parse_to_data(o)
    o.types = []
    o.prepare_time = parse_time_simple(o.prepare_time)
    o.end_time = parse_time_simple(o.end_time)
    o.start_time = parse_time_simple(o.start_time)

    o.types << '1standard' if o.single == '1'

    o.types << '2standard' if o.double == '1'

    o
  end

  def create
    o = params[:wushu]
    parse_to_data(o)

    suc, reason = WushuPvp.validate_opts?(o)

    if suc
      flash[:success] = 'saved'
      WushuPvp.create_wushu(o)
      redirect_to wushu_list_url
    else
      flash[:error] = reason
      redirect_to :back
    end
  end
end

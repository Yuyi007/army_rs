
class CdkeysController < ApplicationController

  include RsRails
  include Cacheable
  include Configurable

  layout 'main'

  protect_from_forgery
  include Eventable

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1 #, :p2, :p3
    # allow  => [:index, :search, :process_redeemed_cdkeys, :manage]
  end



  def index
    sort = params[:sort]
    direction = params[:direction]
    sort = (not sort.nil? or Cdkey.column_names.include? sort) ? sort : 'created_at'
    direction = (direction.nil? or direction.downcase == 'desc') ? 'desc' : 'asc'

    params[:per_page] ||= Cdkey.per_page

    @cdkeys = Cdkey.order("#{sort} #{direction}")
      .paginate(:page => params[:page], :per_page => params[:per_page])

    render :search
  end

  def export_all
    res = ""
    # CdkeyDb.redis.del("newcdkeys").delete_all()
    # CdkeyDb.cdkeys.delete("all") #[:all] = nil
    all_cdkey = CdkeyDb.cdkeys[:all].hgetall 

    # logger.info ("export start111: #{all_cdkey}")
    all_cdkey.each do |key, value|
      res += "#{key}\t#{value}\n"
    end
    # logger.info ("export start333")
    send_data res, :filename => "cdkeys-all.csv"
  end

  def export(params)
    if params[:tid].blank?
      flash[:error] = 'No tid specified!'
      redirect_to(:action => :index)
      return
    end

    # if params[:created_at_s].blank? and params[:created_at_e].blank?
    #   params[:created_at_s] = TimeHelper.gen_date_time(Time.now - 3600 * 1)
    #   params[:created_at_e] = TimeHelper.gen_date_time(Time.now)
    # end

    @cdkeys = Cdkey.search(params)

    tid = params[:tid]
    name = GameConfig.strings["str_#{tid}_name"]

    keys = @cdkeys.map { |x| x.key }

    flash[:notice] = 'Succeed!'

    logger.info ("export called")
    send_data keys.join("\n"), :filename => "cdkeys-#{tid}-#{name}-#{params[:created_at_s]}.csv"
  end

  def search
    if params[:export]
      export(params)
      return
    end

    # if params[:created_at_s].blank? and params[:created_at_e].blank?
    #   params[:created_at_s] = TimeHelper.gen_date_time(Time.now - 3600 * 1)
    #   params[:created_at_e] = TimeHelper.gen_date_time(Time.now)
    # end

    @cdkeys = Cdkey.search(params)
  end

  def generate
    tid = params[:tid].to_s.strip
    num = params[:num].to_i
    end_time = params[:end_time]
    bonus_id = params[:item_id].to_s.strip
    if tid == "" or num == 0 or bonus_id == "" or end_time == ""
      flash[:error] = "Invalid input tid:#{tid}, num:#{num}, end_time:#{end_time}, bonus_id: #{bonus_id}"
      render :manage
      return
    end
    sdks = params[:sdks].to_s.strip
    if sdks == ""
      flash[:error] = "Invalid sdk info:#{sdks}"
      render :manage
      return
    end
    end_time = TimeHelper.parse_date_time(end_time).to_i
    sdks = sdks.split(",")
    keys = Cdkey.generate(sdks, tid, num, end_time, bonus_id, params[:generate_repeatable], params[:generate_special])


    current_user.site_user_records.create(
      :action => 'generate_cdkeys',
      :success => true,
      :param1 => tid,
      :param2 => num,
      :param3 => "#{bonus_id},#{end_time}",
    )

    flash[:notice] = 'Succeed!'

    logger.info ("generate called: #{bonus_id}")
    bonuses = bonus_id.split("|")
    first_bonus = bonuses[0].split("*")
    item_name = GameConfig.get_type(first_bonus[0])["name"]
    send_data keys.join("\n"), :filename => "cdkeys-#{tid}-#{item_name}-#{Time.now.strftime("%F")}.csv"
  end


  def manage
    # @redeemed_count = CdkeyDb.new_redeemed_count
  end


  def import_from_local
    Cdkey.import_from_local(logger)
    render :manage
  end


  def import  
    Cdkey.import_from_file(params[:file], logger)
    render :manage
  end  

  def process_redeemed_cdkeys
    processed = Cdkey.process_redeemed_cdkeys

    current_user.site_user_records.create(
      :action => 'process_redeemed_cdkeys',
      :success => true,
      :param1 => processed
    )

    flash[:notice] = 'Succeed!'

    render :manage
  end

  def queryKey
    key = params[:key]
    res = RsRails.queryCdkey(key)

    render :json => res
  end

  def queryPack
    tid = params[:tid]
    res = RsRails.queryCdkeyPack(tid)
    render :json => res
  end

  def migrate
    res = @@proxy.migrateUsedCdkeyToActionRedis
    render :json => res
  end
end

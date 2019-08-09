class BoothController < EventsController
  layout 'main'
  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0 #,  #:p1, :p2, :p3
    # allow :p1, :p2, :p3, :p4, :p5 => [:list, :search_page_by_booth, :save_group, :delete_group, :group_list, :edit_group]
  end

  include RsRails

  def list
    @cur_booth_id = params[:bid]
    @cur_cid = params[:cid]

    pagei = params[:page]
    @cur_page = 1

    @cur_frozen = params[:frozen]
    @cur_frozen = 0 if @cur_frozen.nil?
    @cur_frozen = @cur_frozen.to_i

    @cur_pid = params[:pid]
    @cur_pid = '' if @cur_pid.nil?

    @cur_gid = params[:gid]
    @cur_gid = '' if @cur_gid.nil?

    if @cur_booth_id.nil?
      group = BoothGroup.get_group(1)
      if group.nil?
        @cur_booth_id, @cur_cid = ["booth1", 'checker0']
      else
        @cur_booth_id, @cur_cid = BoothGroup.get_booth_id_cid(group)
      end
    end
    @cur_page = pagei.to_i  if !pagei.nil?

    # puts ">>>>@cur_cid:#{@cur_cid} @cur_booth_id:#{@cur_booth_id}"
    @page_count = 50
    params = {
      :cur_cid => @cur_cid,
      :cur_booth_id => @cur_booth_id,
      :cur_page => @cur_page,
      :cur_frozen => @cur_frozen,
      :cur_pid => @cur_pid,
      :cur_gid => @cur_gid
    }
    @goods, total_count = search_page_by_booth(params)
    @goods ||= [] 
    @goods.each do |x|
      it = Goods.new.from_hash!(x)
      profile = it.get_cfg
      x['label_tid'] = it.get_label
      x['name'] = profile['name']
      if it.category == 'item'
        x['count'] = it.item.count
      else
        x['count'] = 1
      end
    end
    args = {"dataSource" => @goods,
      "pageNum" => ((total_count.to_f / @page_count.to_f ).to_f).ceil,
      "sort" => 'timeout',
      "direction" => 'DESC',
      "dataType" => 'table',
      "perPage" => @page_count,
      "curPage" => @cur_page,
      "pageUrl" => "list"}
    @page = PageGen.genPage(args)
    # puts ">>>>page:#{@page}"

    @groups = BoothGroup.get_all_groups
    @groups = @groups.map do |group|
      zones = group[:zones]
      group = BoothGroup.gen_data(group[:booth_id], zones)
      booth_id, cid = BoothGroup.get_booth_id_cid(group)
      {:booth_id => booth_id, :cid => cid, :zones => zones}
    end
  end

  def search_page_by_booth(params)
    # puts ">>>>params:#{params}"
    status = GoodsStatus::ALL
    status = GoodsStatus::FROZEN if params[:cur_frozen] == 1
    args = {:cmd => 'search_goods',
            :booth_id => params[:cur_booth_id],
            :label_tid => 'auc0000001',
            :status => status,
            :match_pid => params[:cur_pid],
            :match_gid => params[:cur_gid],
            :page => params[:cur_page],
            :page_count => @page_count,
            :calall => true}
    ret = RedisRpc.call(BoothSearcher, params[:cur_cid], args)
    [ret['records'], ret['count']]
  end

  def group_list
    ret = BoothGroup.get_all_groups
    @groups = ret || []
  end

  def edit_group
    zones = []
    @zones = params[:zones]
    @id = params[:id]
    num_open_zones = DynamicAppConfig.num_open_zones
    (1..num_open_zones).each do |z|
      zones << z
    end

    groups = BoothGroup.get_all_groups
    groups.each do |arr|
      arr[:zones].each do |z|
        zones.delete_if { |x| x.to_i == z.to_i }
      end
    end

    cfg_zones = GameConfig.zones
    @group_zones = []
    if !@zones.nil?
      @group_zones = @zones.split(',').map{|x| {:zone=> x.strip.to_i, :sel => true, :name => cfg_zones[x.strip.to_i - 1]['name']}}
    end

    unsel_zones = zones.map{|z| {:zone => z, :sel => false, :name => cfg_zones[z - 1]['name']}}

    @edit_zones = @group_zones.concat(unsel_zones)
  end

  def save_group
    old_group = params[:old_group]
    new_group = params[:new_group]
    id = params[:id]
    success = true
    if new_group.nil? || new_group == ''
      success = false
    end

    if success
      new_zones = new_group.split(',').map{|x| x.strip}
      if id == '' || id.nil?
        BoothGroup.add_group(new_zones)
      else
        old_zones = old_group.split(',').map{|x| x.strip}
        BoothGroup.update_group(id, old_zones, new_zones)
      end
    end

    render json: { 'success' => success }
  end

  def delete_group
    status = DynamicAppConfig.get_maintainance_status()
    # puts ">>>>status:#{status}"
    success = true
    success = false if !status.on

    zones = params[:zones]
    id = params[:id]
    success = false if id.nil? || id == '' || zones.nil? || zones == ''

    if success
      zones = zones.split(',').map{|x| x.strip}
      BoothGroup.del_group(id, zones)
    end
    render json: { 'success' => success }
  end

  def remove_goods
    zone_id = params[:zone_id]
    player_id = params[:player_id]
    goods_id = params[:goods_id]
    label_tid = params[:label_tid]
    success = true
    success = false if goods_id.nil? || zone_id.nil? || player_id.nil? || label_tid.nil?

    if success
      BoothDB.force_remove_goods(zone_id, player_id, goods_id, label_tid)
    end
    render json: { 'success' => success }
  end

  def frozen_goods
    zone_id = params[:zone_id]
    player_id = params[:player_id]
    goods_id = params[:goods_id]
    success = true
    success = false if goods_id.nil? || zone_id.nil? || player_id.nil?

    if success
      BoothDB.change_goods_status(zone_id, player_id, goods_id, GoodsStatus::FROZEN)
    end
    render json: { 'success' => success }
  end

  def unfrozen_goods
    zone_id = params[:zone_id]
    player_id = params[:player_id]
    goods_id = params[:goods_id]
    success = true
    success = false if goods_id.nil? || zone_id.nil? || player_id.nil?

    if success
      BoothDB.change_goods_status(zone_id, player_id, goods_id, GoodsStatus::NORMAL)
    end
    render json: { 'success' => success }
  end
end
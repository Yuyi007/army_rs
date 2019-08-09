class MysteryshopController < EventsController
  layout 'main'
  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin
    allow :p0, :to => [ :start, :remove ]
    allow :p1, :p2, :p3, :to => [ :create, :edit]
  end

  include RsRails

  def shoplist
    
  end

  def getshoplist
    zone = params.zone.to_i
    shops = MysteryShopDb.get_all_shops(zone)
    render :json => {"shops" => shops}
  end

  def edit
    zone = params.zone.to_i
    npc = params.npc
    if zone != 0 
      shop = MysteryShopDb.get_shop(zone, npc)
      @edit_shop = shop 
    else
      @edit_shop = nil
    end
  end

  def check_save(shop, res)
    cfgNpc = GameConfig.npcs[shop.npc]
    if not cfgNpc 
      res.success = false
      res.reason = "npc do not exist!"
      return
    end

    if cfgNpc.type != 'independent' 
      res.success = false
      res.reason = "npc type must be 'independent'!"
      return
    end

    if cfgNpc.direct_func.nil? then
      res.success = false
      res.reason = "npc direct function must not null!"
      return
    end

    if cfgNpc.direct_func['tid'] != "shop" then
      res.success = false
      res.reason = "npc direct function tid must be 'shop'!"
      return
    end

    if cfgNpc.direct_func['param'].nil? then
      res.success = false
      res.reason = "npc direct function param must be shop tid!"
      return
    end

    shop_id = cfgNpc.direct_func['param']
    cfgShop = GameConfig.shops[shop_id]
    if cfgShop.nil? then
      res.success = false
      res.reason = "shop:#{shop_id} not exist!"
      return
    end
  end

  def save
    zone = params.zone.to_i
    scene = params.scene
    npc = params.npc
    posX = params.posX.to_i
    posY = params.posY.to_i
    posZ = params.posZ.to_i
    dir = params.dir.to_i
    duration = params.duration.to_i
    note = params.note
    shop = MysteryShop.new
    shop.init(zone, scene, {'x' => posX, 'y' => posY, 'z' => posZ}, npc, dir, duration, note)
    res = {'success' => true}
    check_save(shop, res)
    
    if res.success
      MysteryShopDb.save_shop(zone, shop)
      render json: { 'success' => true } 
    else
      render json: { 'success' => false , 'reason' => res.reason} 
    end
  end

  def start
    zone = params.zone.to_i
    npc = params.npc
    suc = MysteryShopDb.start_shops(zone, [npc])
    render json: { 'success' => suc }
  end

  def remove
    zone = params.zone.to_i
    npc = params.npc
    suc = MysteryShopDb.force_del_shop(zone, npc)
    render json: { 'success' => suc }
  end
end


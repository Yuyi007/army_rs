class AvatarData
  attr_accessor :selected_car   #当前首发车辆的tid
  attr_accessor :scheme_car     #当前首发车辆的方案
  attr_accessor :bag            #avtar部件背包
  attr_accessor :equipped_data  #所有anvatar方案数据


  include Jsonable
  include Loggable

  json_hash :bag, :AvatarItem
  json_hash :equipped_data, :EquippedData

  gen_from_hash
  gen_to_hash

  def initialize
    @bag ||= {}
    @equipped_data ||= {}
  end

  def refresh
    @bag ||= {}
    @equipped_data ||= {}
    return if !@equipped_data.empty?
    init_equipped
  end

  def init_equipped
    @scheme_car ||= 1
    
    # GameConfig.config['heroes'].each do |tid, value|
	   #  # tid = 'car001'
	   #  @selected_car ||= tid
	   #  purchase_car(tid, nil)
    # end

    tid = 'car001'
    @selected_car ||= tid
    purchase_car(tid, nil)
  end

  def purchase_car(tid, day)
    purchase_item(tid, day)

    if !equipped_data[tid] 
      @equipped_data[tid] = EquippedData.new
    end    

    # bodyTid = GameConfig.config['heroes'][tid]['body_id']
    # wheelTid = GameConfig.config['heroes'][tid]['wheel_id']

    # tail_id = GameConfig.config['heroes'][tid]['tail_id'] 
    # tailTid = tail_id if !tail_id.nil?
    bodyTid, wheelTid, tailTid, dustTid, notrigenTid = check_default_avatar(tid)
    
    eqs = @equipped_data[tid].schemes
    eqs.each_with_index do |info, index|
      info.body  =  bodyTid
      info.wheel =  wheelTid
      info.dust  =  dustTid
      info.notrigen = notrigenTid
      info.tail  =  tailTid if !tailTid.nil? 
    end

    (0..1).each do | i |
      purchase_item(bodyTid, day)
      purchase_item(wheelTid, day)
      purchase_item(dustTid, day)
      purchase_item(notrigenTid, day)
      purchase_item(tailTid, day) if !tailTid.nil? 
    end
    items = [bodyTid, wheelTid, tailTid, dustTid, notrigenTid, tid]
    [eqs, items]
  end  

  def change_equipped(hid, schemeNum, equipped)
    if @selected_car != hid
      if @bag[hid].nil? or @bag[hid].count < 0
        return [false, "not_exist_car"]
      end
    end
    

    cur_equipped = @equipped_data[hid].schemes[schemeNum]
    return true, cur_equipped if equipped.nil?
    #change selected_scheme
 

    schemeName = equipped["scheme_name"]
    @equipped_data[hid].selected_scheme = schemeNum if !schemeName

    
    #change equipped
    equipped.each do |key, value|
      sym = "#{key}=".to_sym
      if cur_equipped.respond_to? sym
        cur_equipped.send sym, value 
      else
        return [false, 'not_exist_item']
      end
    end

    [true, cur_equipped]
  end

  def device_save_scheme(hid, scheme)
    @selected_car = hid
    @scheme_car   = scheme
  end  

  def get_curr_equipped(s_car = nil, s_scheme = nil)
    s_car ||= @selected_car
    s_scheme ||= @equipped_data[s_car].selected_scheme

    return @equipped_data[s_car].schemes[s_scheme]
  end

  def purchase_item(tid, day)
    if day
      @bag[tid] = AvatarItem.new(tid, day) if @bag[tid].nil?
    else
      @bag[tid] = AvatarItem.new(tid) if @bag[tid].nil?
      @bag[tid].buy if @bag[tid].end_time >= 0 and @bag[tid].count != 1
      # @bag[tid].count = 1
    end
  end

  def redeem_item(tid, day, count)
  	item = @bag[tid]
  	i = 1
  	ed = false
  	# if item and item.expired?
  	# 	refresh_avatar
  	# 	item = @bag[tid]
  	# end
    while i <= count
	    if item and item.end_time >= 0
	    	item.add_end_time(day)
	    	if tid.match(/^car/)
          bt, wt, tt = check_default_avatar(tid)

          @bag[bt].add_end_time(day)
          @bag[wt].add_end_time(day)
          @bag[tt].add_end_time(day) if !tt.nil?
	      end
	    elsif item
	    	return false
	    else
	    	if tid.match(/^car/)
	    		purchase_car(tid, day)
          ed = @equipped_data[tid]
	      else
          purchase_item(tid, day)
	      end
	      item = @bag[tid]
	    end
	    i += 1
	  end
    return true, @bag[tid], ed
  end

  def check_default_avatar(tid)
    bodyTid  = GameConfig.config['heroes'][tid]['body_id']
    wheelTid = GameConfig.config['heroes'][tid]['wheel_id']
    dustTid  = GameConfig.config['heroes'][tid]['dust_id']
    notrigenTid = GameConfig.config['heroes'][tid]['notrigen_id']

    tail_id = GameConfig.config['heroes'][tid]['tail_id'] 
    tailTid = tail_id if !tail_id.nil?

    return bodyTid, wheelTid, tailTid, dustTid, notrigenTid
  end

  def refresh_avatar
    @bag.each do |item_id, avatar|
      if avatar.expired?
      	if item_id.match(/^car/)
          @equipped_data.delete(item_id)
      	else
	      	@equipped_data.each do |car_id, equip|
	          equip.schemes.each_with_index do |ss, i|
	          	h = ss.change_to_hash
	            h.each do |key, value|
	              if value == item_id
	                return_default_avatar(value, car_id, key, i)
	              end
	            end
	          end
	        end
	      end
        @bag.delete(item_id)
      end
    end
  end

  def return_default_avatar(value, car_id, key, i)
    if value.match(/^ava/)
	    eqs = @equipped_data[car_id].schemes[i]
      if key.match(/^body/)
        bodyTid = GameConfig.config['heroes'][car_id]['body_id']
        eqs.body = bodyTid
      elsif key.match(/^wheel/)
	      wheelTid = GameConfig.config['heroes'][car_id]['wheel_id']
        eqs.wheel = wheelTid
      elsif key.match(/^dust/)
        dustTid = GameConfig.config['heroes'][car_id]['dust_id']
        eqs.dust = dustTid
      elsif key.match(/^notrigen/)
        notrigenTid = GameConfig.config['heroes'][car_id]['notrigen_id']
        eqs.notrigen = notrigenTid
      elsif key.match(/^tail/)
	      tailTid = GameConfig.config['heroes'][car_id]['tail_id'] 
	      if tailTid
	      	eqs.tail = tailTid
	      else
	      	eqs.tail = ''
	      end
	    else
	    	value = ''
	    end
    elsif value.match(/^dec/)
      value = ''
    elsif value.match(/^pai/)
      value = ''
    end
  end

  def bag_items_count
    hero_count = 0 
    ava_count = 0 
    dec_count = 0
    @bag.each do |tid, info|
    hero_count += 1 if info.tid.match(/^car/)
    ava_count  += 1 if info.tid.match(/^avatar/)  
    dec_count  += 1 if info.tid.match(/^deco/)
    end
    [hero_count, ava_count, dec_count]  
  end

  def ava_count
    @bag.count {|x| x.tid.match(/^avatar/) }
  end

  def dec_count
    @bag.count {|x| x.tid.match(/^deco/) }
  end

  def efx_count
    0
  end

end
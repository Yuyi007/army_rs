class ShopBuyItem < Handler
  def self.process(session, msg, model)
    instance = model.instance
    id = msg['id']
    type = msg['type']
    cata = msg['cata']
    return ng('error_good_id') if id.nil?
    return ng('error_currency') if type.nil? or type > 3 or type < 1
    return ng('error_cata') if cata.nil?

    bag = instance.avatar_data.bag
    bag.each do|tid, avatar|
      return ng('have_good_yet') if tid == id and avatar.count == 1
    end

    c = GameConfig.shop[cata]
    return ng('error_cata') if c.nil?
    good = c[id]
    return ng('error_good_id') if good.nil?

    end_time = good.end_time
    if end_time
      return ng('expired_good') if end_time < Time.now.to_i
    end

    bonuses = []
    it = {}
    reason = 'shop_buy_item'
    str = "   " + id + "   " + Time.now.to_s
    reason  << str
    case type
    when 1
      return ng('coins_cannot_buy') if good.coins.nil?
      return ng('coins_not_enough') if instance.coins < good.coins
      it = instance.add_item('ite1000002', -good.coins, reason)
    when 2
      return ng('fragments_cannot_buy') if good.fragments.nil?
      return ng('fragments_not_enough') if instance.fragments < good.fragments
      it = instance.add_item('ite1000003', -good.fragments, reason)
    when 3
    	credits  = model.chief.credits
      return ng('credits_cannot_buy') if good.credits.nil?
      return ng('credits_not_enough') if credits < good.credits
      it = instance.add_item('ite1000001', -good.credits, reason)
    end
    bonuses << it
    equips = []
    items = {}
    time = {}
    if cata == 'items'
      item = instance.add_item(id, count)
      bonuses << item
    elsif cata == "car" then
      eqs, itemTids = instance.avatar_data.purchase_car(id, nil)
      equips << eqs
      itemTids.each do |item_id|
      	items[item_id] = 1 if !item_id.nil?
      	time[item_id] = -1 if !item_id.nil?
      end	
    else
    	instance.avatar_data.purchase_item(id, nil)
    	items[id] = 1
    	time[id] = -1
    end

    res = {'success' => true}
    res.items = items
    res.time = time
    res.eqs = equips
    res.bonuses = bonuses
    res
  end
end
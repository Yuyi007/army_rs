class UseItem < Handler
  def self.process(session, msg, model)
    instance = model.instance
    count = msg['count']
    id = msg['id']
    return ng('error_id') if id.nil?
    return ng('error_count') if count.nil? or count <= 0
    item = instance.items[id]
    return ng('error_item') if item.nil?

    can_use = false
    reason = ''

    if item.expired?
      can_use = false
      reason = 'use_expired_item'
      return ng('expired_item')
    else
    	can_use = true
    	reason = 'use_item'
    	profile = GameConfig.items[id]
    	if profile.add_attr
        bag = instance.avatar_data.bag
        bag.each do|tid, avatar|
		      return ng('have_yet') if tid == profile.add_attr and avatar.count == 1
		    end
    	end
    end
    res = {"success" => false}
    res.can_use = can_use
    res.gift = instance.use_items(id, count)
    it = instance.items[id]
    res.item = {}
    if it
      res.item = instance.items[id].to_hash
    else
      res.item.tid = id
      res.item.count = 0
    end
    res.success = true
    res
  end
end
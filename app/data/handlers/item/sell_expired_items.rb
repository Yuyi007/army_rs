class SellExpiredItems < Handler
  def self.process(session, msg, model)
    instance = model.instance
    res = {"success" => false}
    items = instance.items
    its = msg["items"]

    res.items = {}
    res.gain = []
    
    its.each do |value|
    	id = value["itemID"]
    	count = value["count"]
    	item = items[id]
    	if item
			  reason = "auto_sell_expired_item   time : #{Time.now.to_s},    tid : #{id},   count : #{count.to_s}"

        profit = instance.sell_items(id, count, reason)
        res.gain << profit
        res.items[id] = 0
      end
    end
    res.success = true
    res
  end
end
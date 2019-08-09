class SellItem < Handler
  def self.process(session, msg, model)
    instance = model.instance
    count = msg['count']
    id = msg['id']
    return ng('error_id') if id.nil?
    return ng('error_count') if count.nil? or count <= 0
    item = instance.items[id]
    return ng('error_item') if item.nil?

    res = {"success" => false}
    res.gain = []
		reason = "sell_item   time : #{Time.now.to_s},    tid : #{id},   count : #{count.to_s}"


    gain = instance.sell_items(id, count, reason)
    res.gain << gain
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
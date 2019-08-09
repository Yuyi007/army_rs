class GetItems < Handler
  def self.process(session, msg, model)
    instance = model.instance
    res = {"success" => false}
    items = instance.items

    res.expired_items = {}
    res.new_items = {}
    items.each do|id, item|
      res.expired_items[item.tid] = item.to_hash  if item.expired?
      res.new_items[item.tid] = item.to_hash if item.new_get?
    end
    res.success = true
    res
  end
end
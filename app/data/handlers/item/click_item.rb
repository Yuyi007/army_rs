class ClickItem < Handler
  def self.process(session, msg, model)
    instance = model.instance
    id = msg["id"]
    items = instance.items

    res = {"success" => false}
    return ng('error_id') if id.nil?
    item = items[id]
    return ng('error_item') if item.nil?

    items[id].click
    # res.items = items
    res.success = true
    res
  end
end
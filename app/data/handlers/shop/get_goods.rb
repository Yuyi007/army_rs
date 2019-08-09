class GetGoods < Handler
  def self.process(session, msg, model)
    instance = model.instance

    res = {'success' => false}
    goods = GameConfig.config['shop']

    deco = GameConfig.config['decoration']
    images = {}

    expired_items = {}
    goods.each do |cata, items|
    	expired_items[cata] = []
      items.each do |tid, value|
        # items.delete(tid) << if value.end_time and Time.now.to_i > value.end_time
        expired_items[cata] << tid if value.end_time and Time.now.to_i > value.end_time
      end
    end

    expired_items.each do |cata, items|
      if items.size > 0 then
        items.each_with_index do |tid, i|
          goods[cata].delete(tid)
        end
      end
    end

    deco.each do |tid, value|
      images[value.icon_res] = value
    end

    goods['home'] = {}
    goods['home'].images = images

    res.success = true
    res.goods = goods
    res
  end
end
class AvatarPurchase < Handler
  def self.process(session, msg, model)
  	instance  = model.instance
    credits   = model.chief.credits
    tid = msg['tid']
    type = msg['type']
    tag = msg['tag']
    coin_money = msg['itemMoneyCount']
    reason = ""
    strCoin = coin_money.to_s
    reason = reason << tid << "-" << tag << "-" << strCoin << " "<< Time.now.to_s
    return ng('invalid_args') if tid.nil?
    if tag == "coins" 
      return ng('coins_not_enough') if instance.coins < coin_money
      instance.alter_coins(-coin_money, reason)
    elsif tag == "credits" 
      return ng('credits_not_enough') if credits < coin_money
      instance.alter_credits(-coin_money, reason)
    else
      return ng('fragments_not_enough') if instance.fragments < coin_money
      instance.alter_fragments(-coin_money, reason)
    end
    equips = []
    items = {}
    time = {}
    # puts ">>>>>type:#{type}"
    if type == "car" then
      eqs, itemTids = instance.avatar_data.purchase_car(tid, nil)
      equips << eqs
      itemTids.each do |id|
      	items[id] = 1 if !id.nil?
      	time[id] = -1 if !id.nil?
      end	
    else
    	instance.avatar_data.purchase_item(tid, nil)
    	items[tid] = 1
    	time[tid] = -1
    end

    
    
    # puts ">>>>>equips:#{equips}"
    # puts ">>>>>>items:#{items}"
    res ={ 
    	'success' => true, 
  		'tid' 	  => tid, 
  		'items'   => items,
  		'time'    => time,
  		'eqs'     => equips,
      'tag'     => tag,
      'count'   => coin_money,
  	}	
  	res
  end
end
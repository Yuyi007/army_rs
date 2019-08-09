class ChangeNameRequest < Handler
  def self.process(session, msg, model)
    instance  = model.instance
    zone      = session.zone
    myname    = msg['name']
    ids =  Player.search_by_name(myname, zone)
    if ids.empty? 
    	instance.name = myname 
    else
      ids.each do |pid|
    	  player_info = Player.get(pid)
        # puts ">>>player_info:#{player_info}"
    	  return ng('name_used') if player_info.name == myname
      end 	
      instance.name = myname
    end
    # Player.update(instance.player_id, zone, Player.from_instance(instance))   
    res = {
      'success' => true,
      'name' => myname
      }
    res
  end
end
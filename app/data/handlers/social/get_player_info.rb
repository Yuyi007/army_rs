class GetPlayerInfo < Handler
  def self.process(session, msg, model)
    instance  = model.instance
    pid       = msg['pid']
    player_info =  Player.get(pid)
    return ng('contacts_21') if player_info.nil? 
    puts "player_info:#{player_info}"   
    res = {
      'success' => true,
      'requests' => player_info
    }
  end
end
class UpdatePlayerIcon < Handler
  def self.process(session, msg, model)
    instance   = model.instance
    icon       = msg['icon']
    icon_frame = msg['icon_frame'] 
    return ng('invalidparam') if icon.nil? && icon_frame.nil?
    instance.icon = icon
    instance.icon_frame = icon_frame
    # Player.update(instance.player_id, zone, Player.from_instance(instance))   
    res = {
      'success' => true,
      'icon' => icon,
      'icon_frame' => icon_frame,
      }
    res
  end
end
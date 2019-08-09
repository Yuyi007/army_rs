module ChannelHelper
  def self.send_system_message(instance, content, args = []) # args  拼接字符串的 args 交给前端 loc
    time = 1
    color = "#ffc500"
    send_system_message_with_zone(instance.player_id, instance.zone, content, time, color, args)
  end

  def self.send_system_message_with_zone(player_id, zone, content, time, color, args = []) # args  拼接字符串的 args 交给前端 loc
    hash = {}

    hash.uid = player_id if player_id
    hash.text = content
    hash.args = args
    hash.cid  = 'system'
    hash.time = time if time
    hash.color = color if color
    # logger.debug "check zone #{zone}"
    if zone == 0
        num_open_zones = DynamicAppConfig.num_open_zones
        # logger.debug "check final open zones: #{num_open_zones}"
        (1..num_open_zones).each do |z|
          Channel.publish('system_message', z, hash)
        end
    else
      # logger.debug "check final open zones222: #{zone}"
      Channel.publish('system_message', zone, hash)
    end
  end
end

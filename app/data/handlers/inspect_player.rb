class InspectPlayer < Handler

  ###############################################
  # you have to avoid the case that
  # cid == session.id from outside caller
  # USE THIS FUNCTION ONLY IF YOU KNOW
  # WHAT YOU ARE DOING !!
  ###############################################
  def self.get_instance_data(pid, zone)
    zone1, cid, iid = Helper.decode_player_id(pid)
    # return nil if cid == session_id
    # d {"InspectPlayer cid:#{cid}, session_id:#{session_id}"}
    inspect_data = CachedGameData.take_or_ask(cid, zone, GetInspectDataJob, iid)
    return inspect_data
  end

  def self.process(session, msg, model)
    if msg.zone
      zone = msg.zone.to_i
    else
      zone = session.zone
    end

    cid = msg['cid'].to_i
    iid = msg['iid']

    pid = "#{zone}_#{cid}_#{iid}"
    # return ng("cannot inspect self") if pid == model.instance.player_id

    res = {
      'success' => true,
      'instance' => {},
    }

    if cid == session.player_id then
      instance = model.instances[iid]
      inspect_data = instance.inspect_player_data
    else
      inspect_data = CachedGameData.take_or_ask(cid, zone, GetInspectDataJobFull, iid)
    end

    return ng("player not found for #{cid} #{zone} #{iid}") unless inspect_data
    res['instance'] = inspect_data

    return res

    # Cannot use this because
    # GameData.read may get obsolete data due to cached game data
    # player_model = GameData.read(cid, zone)

    # return ng("player not found for #{cid} #{zone}") unless player_model
    # instance = player_model.instances[iid]
    # res = { 'instance' => instance.to_inspect_data }
    # res

    ###########################################
    ### Example usage of GetInspectDataJob

    # Reading self data in take_or_ask results a deadlock
    # So check this first
    # return ng("cannot inspect self") if cid == session.id

    # Use CachedGameData.take_or_ask:
    # inspect_data = CachedGameData.take_or_ask(cid, zone, GetInspectDataJob, iid)

    # Three possibilities:
    # 1. a take happens, GetInspectDataJob executed locally and return immediately.
    # 2. an ask happens, GetInspectDataJob executed remotely and return result in RedisRpc queue,
    #    local server waits and scans the queue and return result once received.
    # 3. a unlikely error happens, an error will be thrown
    #
    # Either case, inspect_data will be the return value of GetInspectDataJob

    # return ng("player not found for #{cid} #{zone} #{iid}") unless inspect_data
    # { 'instance' => inspect_data }
  end
end

class GetInspectDataJob < CachedGameDataJob

  include Loggable

  def self.perform(_id, _zone, model, iid)
    # this result will be returned to take_or_ask caller
    instance = model.get_instance_by_id(iid)
    if instance
      instance.to_inspect_data
    else
      nil
    end
  end
end

class GetInspectDataJobFull < CachedGameDataJob

  include Loggable

  def self.perform(_id, _zone, model, iid)
    # this result will be returned to take_or_ask caller
    instance = model.get_instance_by_id(iid)
    if instance
      instance.inspect_player_data
    else
      nil
    end
  end
end


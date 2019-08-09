
# BatchEditDataJob
#
# NOTE calls and running:
#
# call to BatchEditDataJob is always initiated from GM tools (@see data_batch_controller.rb)
# when a data server is caching player's data, the job is run from data server.
# otherwise, it's run from GM tools server.
#
# @see CachedGameData#ask
#
class BatchEditDataJob < CachedGameDataJob
  def self.perform(id, zone, model, iid, info_hash)
    Log_.info "BatchEditDataJob: #{id} #{zone} #{info_hash}"

    info = BatchEditDataInfo.new(nil, nil, nil, nil, nil).from_hash! info_hash
    method = '_edit_' + info.type.to_s

    begin
      success = info.send(method, id, zone, model, iid)
    rescue => er
      Log_.error("BatchEditDataJob: #{method} Error", er)
      success = false
    end

    success
  end
end

class BatchSendItemJob < CachedGameDataJob
  def self.perform(id, zone, model, iid, tid, count)
    Log_.info("check send item job data:#{id} #{zone} #{iid} #{tid}, #{count}")
    instance = model.get_instance_by_id(iid)
    if instance
      instance.safe_add_bonuses([{'tid' => tid, 'num' => count}])
    end
    true
  end
end

class BatchSendEquipJob < CachedGameDataJob
  def self.perform(id, zone, model, iid, tid, count)
    Log_.info("check send equip job data:#{id} #{zone} #{iid} #{tid}, #{count}")
    instance = model.get_instance_by_id(iid)
    instance.safe_add_bonuses([{'tid' => tid, 'num' => count}]) if instance
    true
  end
end

class BatchSendGarmentJob < CachedGameDataJob
  def self.perform(id, zone, model, iid, tid, count)
    Log_.info("check send garment job data:#{id} #{zone} #{iid} #{tid}, #{count}")
    instance = model.get_instance_by_id(iid)
    if instance
      instance.safe_add_bonuses([{'tid' => tid, 'num' => count}])
    end
    true
  end
end

# BatchEditDataInfo
# Detailed edit info to change a player's model
class BatchEditDataInfo
  include Jsonable

  attr_accessor :type, :param1, :param2, :param3, :reason

  def initialize(type, param1, param2, param3, reason)
    self.type = type
    self.param1 = param1
    self.param2 = param2
    self.param3 = param3
    self.reason = reason
  end

  ##############################################################
  ## Edit data primitives

  def _edit_give_item(id, zone, model, iid)
    tid = param1
    count = param2.to_i
    BatchSendItemJob.perform(id, zone, model, iid, tid, count)
  end

  def _edit_give_equip(id, zone, model, iid)
    tid = param1
    count = param2.to_i
    BatchSendEquipJob.perform(id, zone, model, iid, tid, count)
  end

  def _edit_give_garment(id, zone, model, iid)
    tid = param1
    count = param2.to_i
    BatchSendGarmentJob.perform(id, zone, model, iid, tid, count)
  end

end

module ModuleBatchAdd
	def split_str ids
    ids.split(',').map { |id| id.strip } rescue []
  end

  def do_grant grecord
    fail_ids = []

    zone = grecord.target_zone
    reason = grecord.reason
    ids = split_str( grecord.target_id)
    tids = split_str( grecord.item_id)
    categories = split_str( grecord.action)
    counts = split_str( grecord.item_amount)
    
    records = []
    tids.each_with_index do |tid, i|
      records << {'category' => categories[i], 'tid' => tids[i], 'count' => counts[i].to_i, 'reason' => reason}
    end

    do_batch_edit(zone, ids, records, fail_ids)
    if fail_ids.length == 0
      flash[:notice] = t(:success)
     else
      flash[:error] = t(:save_num) + "#{ids.length}" + ' ' + t(:save_fail_list) + ': ' + fail_ids.join(', ')
    end 
  end

  def do_batch_edit zone, ids, records, fail_ids
    ids.each do |id|
      records.each do |rc|
        info = BatchEditDataInfo.new rc["category"], rc["tid"], rc["count"].to_i, rc["name"], rc['reason']
        success = do_edit id, zone.to_i, info
        fail_ids << id unless success
      end
    end
  end

  def do_edit id, zone, info
    begin
      ids = id.split(':')
      id = ids[0].to_i
      if ids.length > 1
        iid = ids[1]
      else
        iid = nil
      end
      result = CachedGameData.ask(id, zone, BatchEditDataJob, iid, info.to_hash)
      success = (!! result)

      notify_gm_edit(id, zone, success)
    rescue => er
      Rails.logger.error("DataBatchController: do_edit Error #{er.message}")
      success = false
    end

    current_user.site_user_records.create(
      :action => info.type,
      :success => success,
      :target => id,
      :zone => zone,
      :tid => nil,
      :count => nil,
      :param1 => info.param1,
      :param2 => info.param2,
      :param3 => info.param3,
    )
    success
  end
end
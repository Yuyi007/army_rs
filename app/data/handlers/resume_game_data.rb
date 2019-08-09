# resume_game_data.rb

class ResumeGameData < Handler

  def self.process(session, msg, model)
    version = msg['version']

    info "ResumeGameData: session=#{session} version=#{version} model.version=#{model.version}"
    instance = model.cur_instance
    if instance
      session.pid = instance.player_id
      stat("-- login, #{instance.player_id}, #{session.zone}, #{session.device_id}, #{session.platform}, #{session.sdk}, #{session.device_model}, #{session.device_mem}, #{session.gpu_model}")
    end
    StatsDB.inc_active(session.zone, session.player_id)

    # Note because several handler has to be called after player disconnects,
    # Client version (before player disconnects) will never equal to latest version here.
    if version == model.version then
      return { 'success' => true, 'same' => true }
    else
      return GetGameData.do_process(session, msg, model)
    end
  end

end

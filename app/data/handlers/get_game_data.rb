# get_game_data.rb

require 'json'

class GetGameData < Handler
  def self.process(session, msg, model)
    do_process(session, msg, model)
  end

  def self.do_process(session, msg, model, creating = false)
    model.refresh

    unless UserValidator.validate_id(session.player_id)
      fail 'player id should be an integer in valid range!'
    end

    model.chief.id = session.player_id
    model.chief.user_id = session.user_id
    model.chief.zone = session.zone
    model.chief.device_id = session.device_id
    model.chief.sdk = session.sdk
    model.chief.platform = session.platform

    # model.chief.cur_inst_id = 'i1'
    # model.instances.delete('i3')
    instance = model.cur_instance
    if instance

      session.pid = instance.player_id
      stat("-- login, #{instance.player_id}, #{session.zone}, #{session.device_id}, #{session.platform}, #{session.sdk}, #{session.device_model}, #{session.device_mem}, #{session.gpu_model}")
      StatsDB.inc_active(session.zone, session.player_id)

      instance.refresh
      # instance.sync_combat_data
      # instance.record_last_login

      # MailBox.update_group_mails(model)
      # MailBox.all_types.each do |t|
      #   MailBox.expired(session.player_id, session.zone, t, model)
      # end
      
      res = model.to_using_hash
    end

    res ||= model.to_using_hash
    

    res.total_paid = PayDb.get_record_by_cid(model.chief.id)


    # res.total_credit_event = NormalEventDb.get_current_event("credit", session.zone)
    # info "check total login event: #{res.total_login_event}"
    if PermissionDb.deny_talk?(session.player_id) || AntiManipulationDb.is_block_user?(session.player_id)
      res.deny_talk = true
    end

    if instance 
      ActionDb.log_action(session.player_id, session.zone, 'GetGameData', instance.id)
    end

    res
  end

end

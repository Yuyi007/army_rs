class CreateInstance < Handler
  def self.process(session, msg, model)
    name           = msg.name

    if model.chief.nil?
      return ng('chief is nil')
    end

    if model.instances.length >= 3
      return ng('cannot create more than 3 instances')
    end

    instance_id = Helper.gen_instance_id(model.instances)
    pid = "#{model.chief.zone}_#{model.chief.id}_#{instance_id}"

    valid, reason = NameValidator.new(pid, session.zone, name).valid?
    return ng(reason) unless valid

    player=Player.read_id_by_name(name,session.zone)
    if player then
        return ng('str_username_exist')
    end
    instance  = model.add_instance
    instance.name = name
    if msg.gender then
        instance.gender=msg.gender
    end
    if msg.icon then
        instance.icon=msg.icon
    end
    model.set_cur_instance(instance.id)
    session.cur_inst_id = instance.id

    res = GetGameData.do_process(session, msg, model, true)

    StatsDB.inc_new_user(session.zone)

    res
  end

end

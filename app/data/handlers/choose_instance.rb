class ChooseInstance < Handler
  def self.process(session, msg, model)
    id = msg['id']
    return ng('no such instance') unless model.instances[id]
    model.set_cur_instance(id)
    session.cur_inst_id = id
    res = GetGameData.process(session, msg, model)
    res
  end
end

# CheatGame.rb

class CheatGame < Handler
  def self.process(session, msg, model)
    return ng('') unless AppConfig.dev_mode?

    code = msg.code
    return ng('error, no orde type') if code.nil?

    res = {}
    func_sym = "do_#{code}".to_sym
    if respond_to?(func_sym) 
      res = send(func_sym, session, msg, model)
    else
      res = { 'success' => false }
    end

    res
  end

  def self.do_give(session, msg, model)
    tid = msg['tid']
    return ng('invalid_args') if tid.nil?

    count = msg['count']
    count = 1 if count.nil?
    count = count.to_i

    instance = model.cur_instance
    b = instance.add_bonus(tid, count, 'cheat_code')
    puts ">>>b:#{b}"
    bonuses = []
    if b.is_a?(::Hash)
      bonuses << b
    else
      bonuses << b.to_hash
    end

    suc({'bonuses' => bonuses})
  end
end

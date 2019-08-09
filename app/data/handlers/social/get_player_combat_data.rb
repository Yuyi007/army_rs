class GetPlayerCombatData < Handler
  def self.process(session, msg, model)
    pid = msg['pid']
    return ng('Invalid param') if pid.nil?
    jsdata = CombatDataDB.read_combat_data(pid)
    cdata = CombatData.new(pid)
    cdata.from_json!(jsdata) if !jsdata.nil?
    # puts ">>>>cdata:#{cdata}"
    res = {
    	'success' => true,
    	'data'    => cdata.to_hash,
    }
  end
end
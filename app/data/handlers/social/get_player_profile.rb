class GetPlayerProfile < Handler
  def self.process(session, msg, model)
    uid = msg.uid
    return ng('Invalid param') if uid.nil?

    zone = session.zone
    player = GameData.read(uid, zone)
    return ng('notexist') if player.nil?

    res = {'success' => true}
    
    md  = { 'heroes'    => {},
            'codexes'   => {},
            'equips'    => {},
            'slots'     => []}
    heroes  = md.heroes
    codexes = md.codexes
    equips  = md.equips

    slots   = player.slots
    slots.each do |hid|
        md['slots'] << hid
        if hid != '' then
            hero = player.heroes[hid]
            heroes[hid] = hero.to_hash if hid != '' and not hid.nil? 
            hero.eids.each do |eid|
                equip = player.equips[eid]
                equips[eid] = equip.to_hash
            end
            hero.cids.each do |i, cid|
                if cid != 'lock' and cid != 'unlock'
                    codex = player.codexes[cid]
                    codexes[cid] = codex.to_hash
                end
            end
        end
    end
    res['model'] = md
    res
  end
end
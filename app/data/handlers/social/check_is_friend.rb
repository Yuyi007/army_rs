class CheckIsFriend < Handler
  def self.process(session, msg, model)
    fid = msg['fid']
    return ng('invalidparam') if fid.nil? or fid.empty?

    my_id, zone = session.player_id, session.zone
    ids  = SocialDb.friends(my_id, zone)
    isfriend = false
    isfriend = ids.include?(fid)
    if not isfriend 
      return {'success'=>true,
              'isfriend'=>false}  
    else
      info = Player.read_by_id(fid, zone)
      return ng('error') if info.nil?

      return {'success'=>true,
              'info' => info.to_hash,
              'isfriend'=>true}
    end
  end
end
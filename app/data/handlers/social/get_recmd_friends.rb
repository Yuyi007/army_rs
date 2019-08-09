class GetRecmdFriends < Handler
  def self.process(session, msg, model)
    level = model.chief.level
    my_id = session.player_id
    my_zone = session.zone
    lmin = [1, level - 5].max
    lmax = [GameConfig.max_chief_levels, level + 5].min
    ids = search_by_level_range(lmin, lmax, my_id, my_zone)
    players = []
    ids.each do |id|
      player = Player.read_by_id(id, my_zone)
      md = GameData.read(id, my_zone)
      player ||= Player.from_model()
      if player and md
        #检查是否通过创建流程（有英雄上阵）
        fit = false
        md.slots.each do |x|
          if x != nil and x != '' then
            fit = true
          end
        end
        if fit 
          res = player.to_hash
          is_friend = SocialDb.is_friend?(my_id, id, my_zone)
          is_requested = SocialDb.is_following?(my_id, id, my_zone)
          is_rejected = SocialDb.is_abandon(my_id, my_zone, id)
          players << res if not is_friend and not is_requested and not is_rejected
        end
      end
    end

    { 'success' => true,
      'players' => players}
  end

  def self.search_by_level_range(min, max, my_id, my_zone)
    ids = PlayerList.range('play', my_zone, min, max, 0, 30)
    ids.reject! {|id| id == 'default' or id == my_id} if ids
    if ids.size > 6
      ids.shuffle.slice(0, 6)
    else
      ids
    end
  end
end
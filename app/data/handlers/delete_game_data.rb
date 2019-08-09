# delete_game_data.rb

class DeleteGameData < Handler

  def self.process(session, msg, model)
    return ng('') unless AppConfig.dev_mode?

    info "DeleteGameData: #{session.player_id} #{session.zone} model.version=#{model.version}"

    Player.delete(session.player_id, session.zone)
    GameData.delete(session.player_id, session.zone)
    CachedGameData.delete_cache(session.player_id, session.zone, true)

    {'success' => true}
  end

end

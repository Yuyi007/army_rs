# logout.rb

class Logout < Handler

  def self.process(session, msg)
    # zone_res = GetOpenZones.do_process(session, msg)

    delegate = $boot_config.connection_delegate
    _bi = delegate.unbind(nil, session)

    session.user_id = nil
    session.user_name = nil
    session.player_id = nil
    session.zone = nil

    res = { 'success' => true }
    # res.merge!(zone_res)

    res
  end

end

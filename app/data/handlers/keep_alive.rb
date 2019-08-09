# the keepalive handler

class KeepAlive < Handler

  @@result = {"success" => true}

  def self.process(session, msg)
    @@result
  end

end
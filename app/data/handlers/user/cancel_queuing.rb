# cancel_queuing.rb

class CancelQueuing < Handler

  def self.process(session, msg)
    session.queue_rank = nil
    QueuingDb.remove(session.player_id, session.zone)
    return { 'success' => true }
  end

end

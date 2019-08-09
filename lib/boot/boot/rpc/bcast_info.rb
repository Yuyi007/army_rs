
module Boot

  # Broadcast info
  class BcastInfo

    include Jsonable

    attr_accessor :session_ids, :msg, :type

    def self.create session_ids, msg, type
      bcast_info = BcastInfo.new
      bcast_info.session_ids = session_ids
      bcast_info.msg = msg
      bcast_info.type = type
      bcast_info
    end

    def self.to_hash *args
      self.create(*args).to_hash
    end

  end

end

# game_config.rb

# Some global variables
RNDN ||= 1_000_000
# Global variables end

class GameConfig
  include Loggable

  def self.preload(path = nil)
    reload(path) unless defined? @@raw_config
  end

  def self.strings
    @@strings
  end

  def self.loc(str_id, *args)
    str = strings[str_id]
    if str
      str = str % args unless args.empty?
      return str
    end
    str_id
  end

  def self.stringsLoc
    @@stringsLoc
  end

  def self.getFilePath(filename)
    "#{@@path}/game-config/#{filename}"
  end

  def self.decrypt(data)
    # not encrypting game config at the moment
    # ServerEncoding.decrypt_rc4 data
    data
  end

  def self.t1_user?(user_id)
    # puts "check t1 #{user_id}   userids: #{t1_user_ids}"
    t1_user_ids[user_id]
  end

  def self.t2_user?(user_id)
    t2_user_ids[user_id]
  end

  def self.get_award_bonus_id(award_id)
    if award_id == "t1"
      return self.test_reward.ter001.reward_id
    elsif award_id == "t2"
      return self.test_reward.ter002.reward_id
    end
  end


  def self.t2_chongzhi_value(user_id)
    t2_chongzhi_ids[user_id] || 0
  end

  def self.t3_chongzhi_value(user_id)
    t3_chongzhi_ids[user_id] || 0
  end

  def self.reload(path = nil)
    path ||= '.'

    @@path = path

    info "loading game config from #{path}"

    inflated = IO.read(getFilePath('config.json'))
    @@raw_config = Helper.to_hash(inflated)
    @@config = @@raw_config

    strings = IO.read(getFilePath('strings.json'))
    strings.encode('UTF-8')

    @@strings = Helper.to_hash(strings)
    @@stringsLoc = @@strings

    @@levels = nil

  end

  def self.method_missing(sym, *_args, &_block)
    @@config[sym.to_s]
  end

  def self.raw_config
    @@raw_config
  end

  def self.config
    @@config
  end

  def self.get_type(tid)
    case tid
    when /^ite/
      items[tid]
    when /^pro/
      props[tid]
    when /^avatar/
      avatar[tid]
    when /^deco/
      decoration[tid]
    when /^paint/
      paint[tid]
    else
      info "unknown tid #{tid}"
      nil
    end
  end

  def self.max_level
    if @@levels.nil?
      @@levels = 0
      levelup.each do|_k, v|
        @@levels += 1 if v
      end
    end
    @@levels
  end


end

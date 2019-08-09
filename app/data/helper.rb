# helper.rb
require 'uri'
require 'chronic'

module Helper

  include Loggable
  include Statsable

  def self.push_message(session, msg, type)
    session.server.push_message(session, msg, type) if session
  end

  def self.push_message_with_pid(pid, msg, type)
    zone, cid, iid = Helper.decode_player_id(pid)
    cid = cid.to_i
    zone = zone.to_i

    session = SessionManager.get(cid, zone) if cid
    puts "push message get session", session
    if session && session.pid == pid then
      session.server.push_message(session, msg, type)
      d{ "push_message_player: pid=#{pid} cid=#{cid} zone=#{zone} session=#{session}" }
    end
  end

  def self.push_message_player(player_id, zone, msg, type)
    player_id = player_id.to_i
    session = SessionManager.get(player_id, zone) if player_id 
    session.server.push_message(session, msg, type) if session
    d{ "push_message_player: player_id=#{player_id} zone=#{zone} session=#{session}" if session }
  end

  def self.to_json(hash)
    Oj.dump(hash, mode: :compat, bigdecimal_as_decimal: true)
  end

  def self.to_hash(json)
    Oj.load(json, bigdecimal_load: :float)
  end

  def self.to_hash?(json)
    to_hash(json)
  rescue Oj::ParseError => e
    json
  end

  def self.reset_time
    t = Time.now
    Time.new(t.year, t.month, t.day).to_i
  end

  def self.reset_time_in_hour(hour, cur_time = nil)
    t = hour * 3600
    rt = reset_time
    now = cur_time || Time.now.to_i
    time = get_time_in_hour(hour)
    if now - rt < t
      time -= 86_400
    end
    time
  end

  def self.hour_time
    t = Time.now
    Time.new(t.year, t.month, t.day, t.hour).to_i
  end

  def self.noon_time
    t = Time.now
    Time.new(t.year, t.month, t.day, 12).to_i
  end

  def self.manual_reset_time(diff_seconds)
    t = Time.at(Time.now.to_i - diff_seconds)
    Time.new(t.year, t.month, t.day).to_i
  end

  def self.calculate_reset_time(t)
    t = Time.at(t)
    Time.new(t.year, t.month, t.day).to_i
  end

  def self.manual_reset_time_passed?(manual_secs, record_time, cur_time)
    rt = Helper.calculate_reset_time(record_time) + manual_secs
    cur_time = cur_time || Time.now.to_i
    if record_time > rt then rt = rt + 24 * 3600 end
    return cur_time > rt
  end

  def self.weekly_reset_time
    t = Time.now
    Time.new(t.year, t.month, t.day).to_i - t.wday * 86_400 # 24*60*60
  end

  def self.get_time_in_hour(t)
    reset_time + t * 3600
  end

  def self.yesterday
    reset_time - 24 * 60 * 60
  end

  def self.days_since(time)
    secs = Time.now.to_i - time
    secs / (24 * 60 * 60)
  end

  def self.end_of_week(time)
    t = Time.at(time)
    Time.new(t.year, t.month, t.day).to_i + (7 - t.wday + 1) * 24 * 60 * 60 - 1
  end

  def self.beginning_of_week(time)
    t = Time.at(time)
    Time.new(t.year, t.month, t.day).to_i - (t.wday - 1) * 24 * 60 * 60
  end

  def self.wday
    t = Time.new
    t.wday
  end

  def self.day(time)
    if time
      t = Time.at(time)
    else
      t = Time.new
    end
    t.day
  end

  def self.hour
    t = Time.new
    t.hour
  end

  def self.find_wday(time)
    t = Time.at(time)
    t.wday
  end

  def self.get_current_month
    Time.now.month
  end

  def self.beginning_of_current_month
    t = Time.now
    Time.new(t.year, t.month, 1).to_i
  end

  def self.get_next_month_start_time
    t = Time.now
    current_month = t.month
    month = t.month + 1
    year = t.year
    if current_month == 12
      month = 1
      year = t.year + 1
    end
    Time.new(year, month, 1).to_i
  end

  def self.get_current_month_days
    month_duration = get_next_month_start_time - beginning_of_current_month
    days = month_duration / (24 * 60 * 60)
    days
  end

  def self.end_of_current_month
  end

  def self.get_current_time
    Time.now.to_i
  end

  def self.get_cid_by_pid(pid)
    zone, cid, iid = decode_player_id(pid)
    cid
  end

  def self.get_zone_by_pid(pid)
    zone, cid, iid = decode_player_id(pid)
    zone.to_i
  end

  def self.decode_player_id(pid)
    colon_parts = pid.split(':')

    if colon_parts.length == 3
      if colon_parts[2] == 'fakemate' then
        return decode_player_id((colon_parts[0]))
      end

      zone = colon_parts[2].to_i
      npc_id = colon_parts[0]
      iid = nil
      return [zone, npc_id, iid]
    else
      parts = pid.split('_')
      if parts.length == 3
        zone = parts[0].to_i
        cid = parts[1].to_i
        iid = parts[2]
        return [zone, cid, iid]
      elsif parts.length == 2
        if pid =~ /^npc/ || pid =~ /^rob/
          cid = parts[0]
          zone = parts[1].to_i
          iid = nil
        else
          cid = parts[0].to_i
          iid = parts[1]
          zone = nil
        end
        return [zone, cid, iid]
      elsif parts.length == 1
        cid = parts[0].to_i
        return [nil, cid, nil]
      end
    end
  end

  def self.middle_night_zeroes
    zero = reset_time
    last_zero = zero - 24 * 60 * 60
    [zero, last_zero]
  end

  def self.parse_duration(input)
    tokens = {
      's' => (1),
      'm' => (60),
      'h' => (60 * 60),
      'd' => (60 * 60 * 24)
    }

    # input like xx:xx:xx
    if /(?<hour>\d+):(?<min>\d+):(?<sec>\d+)/ =~ input
      hour * tokens['h'] + min * tokens['m'] + sec
    else
      time = 0
      input.scan(/(\d+)(\w)/).each do |amount, measure|
        time += amount.to_i * tokens[measure]
      end

      time
    end
  end

  def self.parse_duration2(input)
    # input like hh:mm:ss
    arr = input.split(':')
    arr[0].to_i * 3600 + arr[1].to_i * 60 + arr[2].to_i
  end

  # probability 0~1
  def self.decide(probability)
    probability ||= 0
    probability * RNDN > rand(RNDN)
  end

  def self.deep_copy(o)
    Marshal.load(Marshal.dump(o))
  end

  def self.gen_id(prefix, hash)
    if hash.length > 0
      key = hash.keys.last
      num = key[1..-1].to_i + 1
      id = prefix << num.to_s
    else
      id = prefix << '1'
    end
  end

  def self.gen_instance_id(instances)
    gen_id('i', instances)
  end

  def self.gen_job_id(jobs)
    gen_id('j', jobs)
  end

  def self.symbolize_hash(h)
    Hash[h.map { |(k, v)| [k.to_sym, v] }]
  end

  def self.symbolize_hash!(h)
    h.keys.each do |key|
      h[(begin
           key.to_sym
         rescue
           key
         end) || key] = h.delete(key)
    end
  end

  def self.mrand(min, max)
    return 0 if min.nil? && max.nil?
    return min.to_i if max.nil?
    return max.to_i if min.nil?
    return max.to_i if min >= max
    rand(min..max).to_i
  end

  def self.fmrand(min, max)
    rand(min.to_f..max.to_f)
  end

  def self.validate_string(str)
    str.tr('a', 'a')
  rescue
    ''
  end

  def self.is_instance?(id)
    id =~ /^i_/
  end

  def self.get_tid_by_id(id)
    if is_instance?(id)
      id.split('_')[2]
    else
      id
    end
  end

  def self.decode_pid(pid)
    zone, uid, id = decode_player_id(pid)
    [uid.to_i, id]
  end

  def self.get_npc_pid(tid, zone)
    parts = tid.split('_')
    pid = tid
    if parts.length == 1
      return "#{tid}_#{zone}"
    else
      return tid
    end
  end

  def self.get_robot_tid(pid)
    pid.split('_').first
  end

  def self.get_npc_tid(pid)
    parts = pid.split('_')
    parts.first
  end

  def self.validate_string(str)
    begin
      str.gsub('a','a')
    rescue
      ''
    end
  end
end

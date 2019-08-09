
module TimeHelper
  def self.parse_date(t)
    return nil if t.nil? || t.blank?
    s = t.split('/')
    Time.new(s[2], s[0], s[1], 0, 0, 0, utc_offset)
  end

  def self.parse_date_time(dt)
    return nil if dt.nil? || dt.blank?
    s = dt.split(' ')
    d = s[0].split('/')
    t = s[1].split(':')
    Time.new(d[2], d[0], d[1], t[0], t[1], 0, utc_offset)
  end

  def self.gen_date(time)
    return '' if time.nil?
    time = Time.at(time) if time.is_a? Numeric
    time = time.utc + utc_offset
    time.strftime('%m/%d/%Y')
  end

  def self.gen_date_time(time)
    return '' if time.nil?
    time = Time.at(time) if time.is_a? Numeric
    time = time.utc + utc_offset
    time.strftime('%m/%d/%Y %H:%M')
  end

  def self.gen_date_time_sec(time)
    return '' if time.nil?
    time = Time.at(time) if time.is_a? Numeric
    time = time.utc + utc_offset
    time.strftime('%m/%d/%Y %H:%M:%S')
  end

  def self.timezone
    # '+08:00'
    Time.now.zone
  end

  def self.utc_offset
    Time.now.utc_offset
  end
end

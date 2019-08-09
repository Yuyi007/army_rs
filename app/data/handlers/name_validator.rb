class NameValidator
  attr_accessor :pid
  attr_accessor :name
  attr_accessor :zone

  def initialize(pid, zone, new_name)
    self.pid = pid
    self.zone = zone
    self.name = new_name
  end

  def valid?
    return [false, :name_nil] if name.nil? || name.empty?
    return [false, :name_char_invalid] unless /^[A-Za-z0-9\u{4e00}-\u{9fa5}\u{3130}-\u{318F}\u{AC00}-\u{D7A3}\u{0E00}-\u{0E7F}]+$/ =~ name
    return [false, :name_has_space] if name[' ']
    id = Player.read_id_by_name(name, zone)
    return true if id.nil? || id == 0
    return [false, :name_taken] if id != pid
    true
  end
end

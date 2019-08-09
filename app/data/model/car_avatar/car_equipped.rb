class CarEquipped
  attr_accessor :scheme_name
  attr_accessor :body
  attr_accessor :wheel
  attr_accessor :tail
  attr_accessor :decoration_f
  attr_accessor :decoration_b
  attr_accessor :paint
  attr_accessor :dust
  attr_accessor :notrigen


  include Jsonable
  include Loggable

  gen_from_hash
  gen_to_hash

  def initialize
    @scheme_name = ''
    @body   = ''
    @wheel  = ''
    @tail   = ''
    @decoration_f = ''
    @decoration_b = ''
    @paint = ''
    @dust = ''
    @notrigen = ''
  end

  def change_to_hash
    h = {}
    h["body"] = @body
    h["wheel"] = @wheel
    h["tail"] = @tail
    h["decoration_f"] = @decoration_f
    h["decoration_b"] = @decoration_b
    h["paint"] = @paint
    h["dust"] = @dust
    h["notrigen"] = @notrigen
    h
  end
end	
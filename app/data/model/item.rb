# Item.rb

class Item
  attr_accessor :tid
  attr_accessor :count
  attr_accessor :end_time
  attr_accessor :new_get_time
  attr_accessor :new_tag    #if plus

  include Jsonable

  gen_from_hash
  gen_to_hash

  def initialize(tid = nil, count = 0)
    init_from_type(tid, count) if tid
  end

  def init_from_type(tid, count)
    # type      = Config::ItemType.get(tid)
    @tid      = tid
    @count    = count
    end_t    = GameConfig.items[@tid].eff_dur_type
    if end_t
      # @end_time = end_t.to_i
      # @end_time = DateTime.parse(end_t).to_time.to_i
      @end_time = Time.parse(end_t).to_time.to_i
    else
    	@end_time = -1
    end
    @new_get_time = Time.now.to_i + 60 * 60 * 24 * 3
    @new_tag = true
  end

  def expired?
    @end_time > 0 && @end_time < Time.now.to_i
  end

  def get_recently?
    @new_get_time > Time.now.to_i
  end

  def click
    @new_tag = false
  end

  def new_get?
  	click if !get_recently? and @new_tag
    get_recently? && @new_tag
  end

  def operate(num = 1)
  	n = 1
    if @count > num
      @count -= num
      n = num
    else
    	n = @count
      @count = 0
    end
    return n
  end

  def type
    GameConfig.items[@tid]
  end
end

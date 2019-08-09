
class TimeStampValue
  attr_accessor :value
  attr_accessor :last_refresh_time
  attr_accessor :wait_interval
  attr_accessor :increase_value
  attr_accessor :limit
  attr_accessor :auto_delta_value # record time value autochanged dx
  include Loggable
  include Jsonable

  gen_from_hash
  gen_to_hash

  def initialize(wait_interval = 0, increase_value = 0)
    self.value = 0
    self.limit = 0
    self.last_refresh_time = Time.now.to_i
    @wait_interval = wait_interval
    @increase_value = increase_value
    @auto_delta_value = 0
  end

  def alter_value(v)
    correct
    # puts "check alter_value TimeStampValue: #{v}, #{@value}, #{@limit}"
    if v < 0 || limit == 0 || value < limit
      @value += v
      @value = limit if value > limit && limit != 0
      @value = 0 if value < 0
    end
    # puts "check alter_value TimeStampValue2222: #{v}, #{@value}, #{@limit}"
    @value
  end

  def change_increase_value(increase_value)
    correct
    @increase_value = increase_value
  end

  def change_limit_value(limit_value)
    correct
    @limit = limit_value
  end

  def correct
    get_value
  end

  def get_value
    now_time = Time.now.to_i
    interval = now_time - @last_refresh_time
    # temporary_value = @value
    # puts "check interval: #{interval}, #{@wait_interval}"
    if (@wait_interval > 0) &&  (interval > @wait_interval)
      @increase_value ||= 0
      # if @increase_value < 0 || @value < @limit
        temporary_value = ((interval / wait_interval) * @increase_value)
        # puts "check interval1111: #{@increase_value}, #{temporary_value}, #{@value}"
        @auto_delta_value +=  temporary_value
        @value += temporary_value
        # puts "check before final data: #{@value}, #{temporary_value}, #{left}, #{interval}, #{@wait_interval}, #{@auto_delta_value}"
        if @value < 0
          @auto_delta_value -= @value
          @value = 0
        end
        # allow over max
        # @value = @limit if (@limit > 0) && (@value > @limit)
      # end
      left = interval % @wait_interval
      @last_refresh_time = now_time - left
      # puts "check left: #{left}, #{now_time}"
    end
    # @value = @value.to_i
    # puts caller
    # puts "get value TimeStampValue: #{@value}"
    @value
  end

  def set_value(v)
    correct
    @value = v
  end
end

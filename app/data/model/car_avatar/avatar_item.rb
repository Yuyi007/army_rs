class AvatarItem
  attr_accessor :tid
  attr_accessor :count
  attr_accessor :end_time

  include Jsonable
  include Loggable

  gen_from_hash
  gen_to_hash

  def initialize(tid = nil, day = nil)
    @tid = tid
    if day
    	@end_time = Time.now.to_i + (60 * 60 * 24 * day).ceil
    	@count = 0
    else
      @end_time = -1
      @count = 1
    end
  end

  def alter(num)
    @count += num
  end

  def add_end_time(day)
  	if @end_time >= 0
  		if expired?
  			@end_time = Time.now.to_i + (60 * 60 * 24 * day).ceil
  		else
        @end_time += (60 * 60 * 24 * day).ceil
      end
    end
  end

  def buy
    @end_time = -1
    @count = 1
  end

  def expired?
    @end_time > 0 && @end_time < Time.now.to_i && @count == 0
  end
end	
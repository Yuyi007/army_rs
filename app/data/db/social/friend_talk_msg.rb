class FriendTalkMsg
	attr_accessor :frompid
  attr_accessor :topid  
	attr_accessor :icon
  attr_accessor :gender 
	attr_accessor :level
	attr_accessor :name 
	attr_accessor :time
	attr_accessor :text
  
  include Jsonable
  include Loggable
  
  gen_from_hash
  gen_to_hash
  
  def initialize
    @frompid = ""
    @topid = ""
    @icon = ""
    @level = 1
    @gender = ""
    @name = ""
    @time = Time.now.to_i
    @text = ""
  end 	

  def set_msg(msg)
    # puts ">>>>>msg:#{msg}"
    @text = msg
  end 	
end	
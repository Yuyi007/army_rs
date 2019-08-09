class RoomInfo
	attr_accessor :creator
	attr_accessor :id
	attr_accessor :members 
	attr_accessor :time_stamp
  attr_accessor :type 
  attr_accessor :ch_ids

  include Jsonable
  include Loggable

  gen_from_hash
  gen_to_hash

  #uid: player id or pool_id
  #As windows limitation choose '-' as split char 
  def self.gen_room_id(uid)
    now = Time.now.to_i
    "RID-#{uid}-#{now}"  
  end

  def initialize(type, rid, uid)
    @type = type
  	@creator = uid
  	@id = rid
  	@time_stamp = Time.now.to_i
    @ch_ids = -1
    init_members
  end

  def init_members
    puts "init room members", type

    ##pos = 1,2,3    
    @members = []
    (0..2).each do |pos|
      @members[pos] = -1
    end 
    puts "@members>>>#{@members}" 
  end

  def vacant?(pos)
    pos == -1
  end

  def find_vacant(pos = nil)
    puts "find_vacant", pos, @members
    if pos.nil?
      @members.each_with_index do |info, pos|
        return pos if vacant?(info)
      end
      return nil
    else
      info = @members[pos]
      return pos if vacant?(info)
      return nil
    end
  end

  def add_side_chid(side, chid)
    @ch_ids[side] = chid
  end  

  def add_member(pos, uid, name)
    info = @members[pos]
    puts "info:#{info}"
      
  	@members[pos] = {:ready => false, 
  		:name => name, 
  		:uid => uid ,
  		:houseCreator => false}

    puts "@members:#{@members}"
  end

  def in_room?(uid)
    info = @members.find { |v| !vacant?(v) && v[:uid] == uid }
    return true if !info.nil?
    false
  end

  def set_ready(uid, ready)
    puts ">>>>>>members:#{@members}"
    info =  @members.find{|v| !vacant?(v) && v[:uid] == uid }
    return  if info.nil?
     
    info[:ready] = ready
  end 
  
  def set_house_creator( uid, isCreator)
    info =  @members.find{|v| !vacant?(v) && v[:uid] == uid }
    #puts "info:#{info}"
    return  if info.nil?
    info[:houseCreator] = isCreator
  end 

  def remove_member(uid)
    info = @members.find{ |v| !vacant?(v) && v[:uid] == uid }
    info = -1 if !info.nil?
  end

  def creator?(uid)
    @creator == uid
  end



  def all_ready?
    # @members.each do |mems|
    #   return false if !mems.all?{|info| vacant?(info) || info[:ready] }
    # end
    true
  end

  def count
    c = 0
    c += count_side(0)
    c += count_side(1)
  end

  def count_side(side)
    side = @members[side]
    side.count{|v| !vacant?(v)}
  end


  def member_uids
    uids = []
    @members.each do |side|
      side.each do |info|
        if !vacant?(info)
          uids << info[:uid]
        end
      end
    end
    uids
  end

  def full?
  	return true if members.length >= 3
    return false
  end
end

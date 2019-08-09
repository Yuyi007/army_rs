class EquippedData
  attr_accessor :selected_scheme
  attr_accessor :schemes
  
  include Jsonable
  include Loggable

  json_array :schemes, :CarEquipped

  gen_from_hash
  gen_to_hash

  def initialize
    @schemes ||= []
    @selected_scheme ||= 0
    (0..1).each do |i|
      @schemes.push(CarEquipped.new)
      str = ''
      if i < 10 
        str = '装备方案0'
      else
        str = '装备方案'
      end

      @schemes[i].scheme_name = str + (i + 1).to_s()
    end  
  end

  # def refresh
  #   @selected_scheme ||= 0
  #   @schemes ||= @schemes.push(CarEquipped.new)
   
  # end

  # def add_scheme()
    
  # end

end	
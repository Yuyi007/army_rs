
class Garage
  attr_accessor :cars
  attr_accessor :packsack
  
  include Jsonable
  include Loggable
 
  json_hash :cars, :Cars
  json_hash :packsack, :Packsack
  
  gen_from_hash
  gen_to_hash

	def initialize
		@cars ||= {}

  end

  def init_car(tids)
    tids.each do |tid|
      @cars[tid] = Cars.new(tid) unless @cars[tid]
    end
    return @cars 
  end    
  
  def set_refit(units,sacks)
    return nil unless units["tid"] 
    car_tid = units["tid"]
    @cars[car_tid] = Cars.new() unless @cars[car_tid]
    @cars.each do|tid,car| 
    	if tid == car_tid
        car.knapsack.clear
        car.set_knapsack(sacks)
        car.cartid = units["tid"]
        car.wheelRF = units["wheelRF"]
        car.wheelRB = units["wheelRB"]
        car.wheelLF = units["wheelLF"]
        car.wheelLB = units["wheelLB"]
        car.paint = units["paint"]
        car.init_decoration
        units["decoration"].each do|item|
          car.set_decoration(item)
        end
      end     
    end
    return @cars[car_tid]
  end
  
end
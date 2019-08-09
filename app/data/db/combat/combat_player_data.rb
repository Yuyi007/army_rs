class CombatPlayerData
	attr_accessor :name
	attr_accessor :icon
	attr_accessor :icon_frame
	attr_accessor :level
	attr_accessor :avatar
	attr_accessor :attrs
	attr_accessor :score
  attr_accessor :selected_car

	include Jsonable 
	include Loggable

	gen_from_hash
  gen_to_hash

  def initialize
  	@name = ''
		@icon = nil
		@icon_frame = nil
		@level = 0
		@score = 0
		@avatar = {}
		@attrs = {}
    @selected_car = 'car001'
  end
end
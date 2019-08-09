class RobotBase

	attr_accessor :id
	attr_accessor :name
	attr_accessor :level
	attr_accessor :icon
	attr_accessor :icon_frame
	attr_accessor :score
	attr_accessor :zone

	include Jsonable
	include Loggable

	gen_from_hash
	gen_to_hash

	def initialize(id, level, icon, zone=1)
		@id = id
		@name = 'RP'
		@name << (id-8000000).to_s
		@level = level
		@icon = icon
		@score = 0
		@zone = zone
	end

	def pid
		"#{zone}_#{id}_1"
	end

	def zone
		@zone
	end

	def pdata
		pdata = CombatPlayerData.new
		pdata.avatar = RobotManager.defavatar
		pdata.icon = @icon
		pdata.icon_frame = @icon_frame
		pdata.level = @level
		pdata.name = @name

		pdata
	end

	

	

end
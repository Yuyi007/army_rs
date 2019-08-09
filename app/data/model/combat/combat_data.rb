#匹配战斗的战斗数据
class CombatData
	attr_accessor :pid 				#玩家PID
	attr_accessor :stat 			#统计数据
	attr_accessor :records 		#最近20场记录

	include Loggable
  include Jsonable

  json_object :stat, :CombatStat
  json_array :records, :CombatRecord

  gen_to_hash
  gen_from_hash
	
  def initialize(pid = nil)
  	@pid = pid
  	@stat ||= CombatStat.new
  	@records ||= []
  end

	def add_record(record)
		@records << record
		@records = @records.last(20)
	end
end
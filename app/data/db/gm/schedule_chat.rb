class ScheduleChat
	attr_accessor :start_time
	attr_accessor :stop_time
	attr_accessor :interval
	attr_accessor :name
	attr_accessor :content
	attr_accessor :zones
	attr_accessor :times
	attr_accessor :color

	include Loggable
  include Jsonable

  gen_from_hash
  gen_to_hash

	def initialize(zones = [], start_time = 0, stop_time = 0, interval = 0, content = '', name = '', times = 3, color = "#ffc500")
		@zones = zones
		@start_time = start_time
		@stop_time = stop_time
		@interval = interval.to_i
		@content = content
		@name = name
		@times = times.to_i
		@color = color
	end

	def start?
		now = Time.now.to_i
		now >= @start_time
	end

	def timeup?
		now = Time.now.to_i
		# puts ">>>>@last_send_time:#{@last_send_time}"
		if @last_send_time.nil? then
		  true
		else
		  #@last_send_time ||= now
		  # puts ">>>>content:#{content} (now - @last_send_time):#{(now - @last_send_time)} interval:#{@interval}"
		  (now - @last_send_time) >= @interval
		end
	end

	def timeout?
		now = Time.now.to_i
		now >= @stop_time
	end

	def care?(zone)
		@zones.include?(zone)
	end

	def check_send_msg(zones)
		return if !start? || !timeup? || timeout? 
		sent = false
		zones.each do |zone|
			next if !care?(zone)
			info ">>>send msg #{@content} zone:#{zone}"
			sent = ChannelHelper.send_system_message_with_zone(nil, zone, @content, @times, @color)
		end
		@last_send_time = Time.now.to_i if sent
	end
end
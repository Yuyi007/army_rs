class OnlineParser
  include Stats::StatsParser

  public

  def on_start
    @stats = {}
  end

  def parse_command(record_time, command, param)
    ol = Oj.load(param)
    ol.each do |k, v|
      if k == 'total'
        zone_id = '999'
      else
        zone_id, = *k.scan(/^z:(\d+)/)[0]
      end

      num = v.to_i
      zone_id = zone_id.to_i

      @stats[zone_id] ||= {}
      @stats[zone_id][record_time.hour] ||= {} 

      @stats[zone_id][record_time.hour][:min] ||= 0 
      @stats[zone_id][record_time.hour][:max] ||= 0 

      if num > @stats[zone_id][record_time.hour][:max]
        @stats[zone_id][record_time.hour][:max] = num
      end

      if @stats[zone_id][record_time.hour][:min] == 0 or num < @stats[zone_id][record_time.hour][:min]
        @stats[zone_id][record_time.hour][:min] = num
      end
    end
  end

  def on_finish
    date = @options[:date].to_date

    @stats.each do |zone_id, data|
      data.each do |hour, hdata|
        record = StatsModels::OnlineUserNumber.where(:date => date, :zone_id => zone_id, :hour => hour).first_or_initialize

        record.min = hdata[:min]
        record.max = hdata[:max]

        record.save
      end
    end
  end 
end
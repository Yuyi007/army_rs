class  DigLoginParser
  include Stats::StatsParser

  public

  def on_start
    @diff_new = {}
    @diff_ret = {}
    @fix_data = {}
    @date09 = Time.parse('2017-08-09').to_i
    load_diffs
  end

  def load_diffs
    path = '/data/log/stat/diff08new_proc.json'
    if !File.exists?(path)
      json_str = File.read('/data/log/stat/diff08new.json')
      @diff_new  = JSON.parse(json_str)  
    else
      json_str = File.read(path)
      @diff_new  = JSON.parse(json_str)  
    end

    path = '/data/log/stat/diff09ret_proc.json'
    if !File.exists?(path)
      json_str = File.read('/data/log/stat/diff09ret.json')
      @diff_ret = JSON.parse(json_str)  
    else
      json_str = File.read(path)
      @diff_ret  = JSON.parse(json_str)  
    end

    json_str = File.read('/data/log/stat/fix_data.json')
    hs = JSON.parse(json_str)  
    date = @options[:date]
    str_date = date.strftime('%Y-%m-%d')
    puts ">>>>str_date:#{str_date}"
    @fix_data = hs[str_date]
  end

  def parse_command(record_time, command, param)
    id, zone_id, sid, platform, sdk, market = param.split(",").map{|x| x.strip}

    if @fix_data.nil?
      fit_fix = true 
    else
      fit_fix = !@fix_data[id].nil?
    end

    if fit_fix and @diff_new[id] and !@diff_new[id].is_a?(::Hash)
      @diff_new[id] = {:fvid => @diff_new[id], :login_time => record_time}
    end

    if fit_fix and @diff_ret[id] and !@diff_ret[id].is_a?(::Hash) and record_time.to_i >= @date09 
      @diff_ret[id] = {:fvid => @diff_ret[id], :login_time => record_time}
    end
  end

  def on_finish
    path = '/data/log/stat/diff08new_proc.json'
    json = JSON.pretty_generate(@diff_new).to_s.strip
    File.open(path, 'w+') do |f|
      f.write(json)
    end

    path = '/data/log/stat/diff09ret_proc.json'
    json = JSON.pretty_generate(@diff_ret).to_s.strip
    File.open(path, 'w+') do |f|
      f.write(json)
    end
  end

end

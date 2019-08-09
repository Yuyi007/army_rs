class StatCommands < Thor
  include Thor::Actions

  class_option :env, :aliases => :e
  class_option :date, :aliases => :d
  class_option :scan, :type => :boolean, :aliases => :s
  class_option :verbose, :type => :boolean, :aliases => :v
  class_option :digger, :aliases => :g

  @log_path = nil

  ROUTES.keys.each do |key|
    desc key, "parsing stats #{key} log records"
    define_method key do
      init
      do_command(key, ROUTES[key])
    end
  end

  # DIGGERS.keys.each do |key|
  #   desc key, "parsing stats #{key} log records"
  #   define_method key do
  #     init
  #     do_command(key, DIGGERS[key])
  #   end
  # end

  def self.game_config
    @@game_config
  end

  desc 'regen', 'parse all stats logs'
  def regen
    start_time = Time.now

    init

    set_parsing
    # do_parse
    ROUTES.each {|k, r| do_command(k.to_sym, r)}

    fix_data

    do_reports 

    end_time = Time.now

    say "#{ Time.now} all logs have been parsed in " + "#{end_time - start_time}".color(:cyan) + " seconds"

    rc = StatsModels::SysFlags.where(:flag => 'today_gen_task').first_or_initialize
    rc.value = 'idle'
    rc.save
  end

  desc 'gen', 'parse all stats logs'
  def gen
    regen
  end

  desc 'dig', 'dig data buy stats logs'
  def dig
    start_time = Time.now
    init
    DIGGERS.each {|k, r|
      puts ">>>>>r[:class] :#{r[:class] } digger:#{@digger}"
      if @digger.to_sym == r[:class] 
        begin
          do_command(k.to_sym, r)
        rescue Exception => e
          puts "error: #{e.message}"
          next
        end
      end
    }
  end

  desc 'do_parse', 'parse all stats logs'
  def do_parse
    init
    @logfile = File.expand_path(File.join("#{@log_path}", "stat/stat_#{@date.strftime('%Y%m%d')}.log.gz"))
    @zip = true
    if !File.exists?(@logfile)
      @logfile = File.expand_path(File.join("#{@log_path}", "stat/stat_#{@date.strftime('%Y%m%d')}.log"))
      say "try " + "#{@logfile}".color(:yellow)
      @zip = false
      if !File.exists?(@logfile)
        say "log file " + "#{@logfile}".color(:yellow) + " not exists"
        exit(-1)
      end
    end
    if options[:scan]
      parsers = {}
      ROUTES.each do |command, profile| 
        parser = Object.const_get(profile[:class]).new :key_name => profile[:key], :date => @date, :env => @env, :config => @config, :verbose => @verbose
        if profile[:key].instance_of?(Array)
          profile[:key].each do |key|
            parsers[command] ||= parser
          end
        else
          parsers[profile[:key]] = parser
        end
      end

      puts ">>>>parsers:#{parsers.keys}"

      start_time = Time.now
      count = 0

      parsers.each do |_, parser|
        parser.on_start
      end

      line_exp = /^([\d\-:T\.]+[\+\-]\d\d:00) [0-9a-zA-Z\-_]+ stat\[\d+\]: [\d:\.]+ \[info\]+ -- (\w+), (.*)/
      $stdin.each_line do |line|
        count += 1
        say "[stats] #{Time.now} parse line: #{count}".color(:yellow)  if count % 10000 == 0
        record_time, command, param = *line.scan(line_exp)[0]
        parsers.each do |_, parser|
          parser.parse(record_time, command, param)
        end
      end

      start_time = Time.now
      parsers.each do |_, parser|
        parser.on_finish
      end
      end_time = Time.now
      say "[stats] #{Time.now} parse complete duration:#{end_time - start_time}".color(:green)

    else
      cat = 'zcat'
      cat = 'gzcat' if system('which gzcat')
      cat = 'cat' if !@zip

      if @config['system'] && @config['system']['bypass_hosts']
        script = "#{cat} #{@logfile} | grep -Ev '#{@config['system']['bypass_hosts'].join('|')}' "\
                 "| grep '#{@date.strftime('%Y-%m-%d')}' | #{EXECUTE_CMD} #{command} --env=#{@env} "\
                 "--date=#{@date.strftime('%Y-%m-%d')} --scan=true --verbose=#{@verbose} > log/log.txt"
      else
        script = "#{cat} #{@logfile} "\
                 "| grep '#{@date.strftime('%Y-%m-%d')}' | #{EXECUTE_CMD} #{command} --env=#{@env} "\
                 "--date=#{@date.strftime('%Y-%m-%d')} --scan=true --verbose=#{@verbose} > log/log.txt"
      end

      say script.color(:yellow)
      system(script)
    end
  end

  private

  def load_game_config
    file_path = File.expand_path(File.join(File.dirname(__FILE__), "../../../../game-config/config.json"))
    inflated = IO.read(file_path)
    @@game_config = Oj.load(inflated)
  end

  def load_server_config
    file_path = File.expand_path(File.join(File.dirname(__FILE__), "../../../../config/server_list.json"))
    inflated = IO.read(file_path)
    @@server_list = Oj.load(inflated)
    @@stats_servers = @@server_list['stats_servers']
  end

  def init
    @env = options[:env] ? options[:env] : STATS_ENV
    @date = options[:date] ? options[:date] : Time.at(Time.now.to_i - 1*24*60*60).strftime('%Y-%m-%d')
    @date = Time.parse(@date)
    @digger = options[:digger] ? options[:digger] : false
    @verbose = options[:verbose] ? options[:verbose] : false
    @all = options[:all] ? options[:all] : false

    load_server_config
    load_game_config

    configFile = File.expand_path(File.join(File.dirname(__FILE__), "../../config/database.yml"))

    @config = YAML::load(ERB.new(IO.read(configFile)).result())

    mysql_cfg = @config[@env]
    mysql_cfg['socket'] = '/tmp/mysql.sock'

    if !File.exists?( mysql_cfg['socket'] )
      mysql_cfg['socket'] = '/var/lib/mysql/mysql.sock'
    end

    @log_path = '/data/rs/log'
    @log_path = '/data/log' if @env == 'test'
    if not File.directory?(@log_path)
      say "log path " + "#{@log_path}".color(:yellow) + " not exists"
      exit(-1)
    end

    ActiveRecord::Base.establish_connection(mysql_cfg)
    ActiveRecord::Base.logger = Logger.new(STDOUT) if @options[:verbose]
    ActiveRecord::Base.default_timezone = :local
    # ActiveRecord::Base.time_zone_aware_attributes = false
    # ActiveRecord::Base.skip_time_zone_conversion_for_attributes = true

    #RedisFactory.init @config
    #Stats::GameDataLoader.init @config

    return true
  end


  def do_command(command, profile)
    @logfile = File.expand_path(File.join("#{@log_path}", "stat/stat_#{@date.strftime('%Y%m%d')}.log.gz"))
    @zip = true
    if !File.exists?(@logfile)
      @logfile = File.expand_path(File.join("#{@log_path}", "stat/stat_#{@date.strftime('%Y%m%d')}.log"))
      say "try " + "#{@logfile}".color(:yellow)
      @zip = false
      if !File.exists?(@logfile)
        say "log file " + "#{@logfile}".color(:yellow) + " not exists"
        exit(-1)
      end
    end

    if options[:scan]
      puts caller
      puts ">>>>profile[:class]:#{profile[:class]}"
      parser = Object.const_get(profile[:class]).new :date => @date, :env => @env, :config => @config, :verbose => @verbose
      parser.run
    else
      if profile[:key].instance_of?(Array)
        key_exp = profile[:key].map{|key| "\\-\\- #{key}"}.join('|')
      else
        key_exp = "\\-\\- #{profile[:key]}\s*,"
      end

      cat = 'zcat'
      cat = 'gzcat' if system('which gzcat')
      cat = 'cat' if !@zip

      if @config['system'] && @config['system']['bypass_hosts']
        script = "#{cat} #{@logfile} | grep -E '#{key_exp}' | grep -Ev '#{@config['system']['bypass_hosts'].join('|')}' "\
                 "| grep '#{@date.strftime('%Y-%m-%d')}' | #{EXECUTE_CMD} #{command} --env=#{@env} "\
                 "--date=#{@date.strftime('%Y-%m-%d')} --scan=true --verbose=#{@verbose}"
      else
        script = "#{cat} #{@logfile} | grep -E '#{key_exp}' "\
                 "| grep '#{@date.strftime('%Y-%m-%d')}' | #{EXECUTE_CMD} #{command} --env=#{@env} "\
                 "--date=#{@date.strftime('%Y-%m-%d')} --scan=true --verbose=#{@verbose}"
      end

      say script.color(:yellow)
      system(script)
    end
  end

  def set_parsing
    say "[stats] #{Time.now} begin parsing...".color(:yellow)
    rc = StatsModels::StatsServer.where(:name => @env, :date => @date.to_date)
    rc.destroy_all if rc
  end

  def set_ready_to_report
    say "[stats] #{Time.now} parse complete set ready to gen report...".color(:yellow)
    rc = StatsModels::StatsServer.new
    rc.date = @date.to_date
    rc.name = @env
    rc.save
  end

  def check_servsers_ready
    records = StatsModels::StatsServer.where(:date => @date.to_date)
    return false if records.nil?

    @@stats_servers.each do |server|
      ready = false
      records.each do |rc|
        if rc.name == server 
          ready = true
          break
        end
      end
      say "[stats]check #{server} ready #{ready}".color(:yellow)
      return false if !ready
    end
    say "[stats] #{Time.now} check server ready".color(:yellow)
    return true
  end

  def do_reports
    # set_ready_to_report
    #所有stats服务器都parse完ready才开始生成数据
    # return if !check_servsers_ready

    generator = ReportGenerator.new :date => @date, :config => @config, :verbose => @verbose, :servers => @config[@env]['servers']
    generator.run
  end

  def fix_data
    fixer = ReportFixer.new :date => @date, :config => @config, :env => @env
    fixer.fix
  end
end

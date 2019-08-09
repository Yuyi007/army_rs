
require 'open3'

class DataQueryController < ApplicationController

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2, :p3, :p4, :p5
  end

  include RsRails

  def index
    @total_player_count = 0
    @on_start = File.read(on_start_filename) if File.exists?(on_start_filename)
    @do_model = File.read(do_model_filename) if File.exists?(do_model_filename)
    @on_finish = File.read(on_finish_filename) if File.exists?(on_finish_filename)
    @queries = readQueries
  end

  def debug
    on_start = params[:on_start]
    do_model = params[:do_model]
    on_finish = params[:on_finish]
    colddata = params[:colddata] == 'true'
    players = params[:players].split.join(',')

    filename = saveQuery(on_start, do_model, on_finish)
    runQuery(filename, colddata, players)

    render :json => { :success => true }
  end

  def submit
    on_start = params[:on_start]
    do_model = params[:do_model]
    on_finish = params[:on_finish]
    colddata = params[:colddata] == 'true'

    filename = saveQuery(on_start, do_model, on_finish)
    runQuery(filename, colddata)

    render :json => { :success => true }
  end

  def showlog
    id = params[:id]

    logfile = File.expand_path(File.join(Rails.root, 'tmp', 'queries', "/q-#{id}.log"))

    if File.exists?(logfile)
      render :text => File.read(logfile).gsub("\n",'<br />')
    else
      render :text => 'file not exists, probably it\'s still running'
    end
  end

  def deletelog
    id = params[:id]

    pidfile = File.expand_path(File.join(Rails.root, 'tmp', 'queries', "/q-#{id}.pid"))

    q = readQuery pidfile

    if q[:status] == 'running'
      killQuery q[:pid]
    else
      logger.info "deletelog: #{q[:pid]} not running"
    end

    File.delete(q[:rbfile]) if File.exists?(q[:rbfile])
    File.delete(q[:pidfile]) if File.exists?(q[:pidfile])
    File.delete(q[:logfile]) if File.exists?(q[:logfile])
    File.delete(q[:outfile]) if File.exists?(q[:outfile])

    redirect_to data_query_index_url
  end

private

  def readQueries
    queries = {}
    Dir.glob(File.join(Rails.root, 'tmp', 'queries', '/q-*.pid')) do |pidfile|
      if File.exists?(pidfile)
        q = readQuery pidfile
        q[:pidfile] = File.basename(q[:pidfile])
        q[:rbfile] = File.basename(q[:rbfile])
        q[:logfile] = File.basename(q[:logfile])
        q[:outfile] = File.basename(q[:outfile])
        queries[q[:id]] = q
      end
    end
    queries
  end

  def readQuery pidfile
    pid = File.read(pidfile)
    id = pidfile.gsub(/\.pid$/, '').gsub(/.*-/, '')
    rbfile = pidfile.gsub(/\.pid$/, '.rb')
    logfile = pidfile.gsub(/\.pid$/, '.log')
    outfile = pidfile.gsub(/\.pid$/, '.out')
    startTime = Time.at(id.to_i)

    if queryIsAlive? pid
      status = 'running'
      endTime = nil
    else
      status = 'finished'
      if File.exists?(logfile)
        endTime = File.mtime(logfile)
      else
        endTime = nil
      end
    end

    return {
      :id => id,
      :pid => pid,
      :startTime => startTime,
      :endTime => endTime,
      :status => status,
      :pidfile => pidfile,
      :rbfile => rbfile,
      :logfile => logfile,
      :outfile => outfile
    }
  end

  def queryIsAlive? pid
    begin
      Process.getpgid(pid.to_i)
      true
    rescue Errno::ESRCH
      false
    end
  end

  def killQuery pid, &blk
    # Thread.new do
      begin
        logger.info("start to killing #{pid}...")
        Process.kill("TERM", pid.to_i)
        Timeout::timeout(30) do
          begin
            sleep 1
          end while !!(`ps -p #{pid}`.match pid)
        end
      rescue Timeout::Error
        logger.info("forcefully kill #{pid} after 30 secs")
        Process.kill("KILL", pid.to_i)
      ensure
        logger.info("killed #{pid}")
        yield if block_given?
      end
    # end
  end

  def saveQuery on_start, do_model, on_finish
    q = File.read(File.expand_path(File.join(Rails.root, 'lib', 'query.rb')))
    q.gsub!(/^#__ON_START__$/, on_start)
    q.gsub!(/^#__DO_MODEL__$/, do_model)
    q.gsub!(/^#__ON_FINISH__$/, on_finish)

    begin
      Dir.mkdir(File.expand_path(File.join(Rails.root, 'tmp', 'queries')))
    rescue => er
    end

    now = Time.now.to_i
    filename = File.expand_path(File.join(Rails.root, 'tmp', 'queries', "q-#{now}.rb"))
    File.open(filename, 'w+') do |f|
      f.write(q)
    end

    File.open(on_start_filename, 'w+') do |f| f.write(on_start) end
    File.open(do_model_filename, 'w+') do |f| f.write(do_model) end
    File.open(on_finish_filename, 'w+') do |f| f.write(on_finish) end

    filename
  end

  def runQuery filename, colddata, players = nil
    Thread.new do
      logger.info("runQuery file=#{filename} colddata=#{colddata} players=#{players}")

      env = Gm::Application.config.cocs_environment
      logfile = filename.gsub(/\.rb$/, '.log')
      args = [ '-e', "#{env}", '-o', "#{logfile}" ]

      if colddata
        args << "-c"
      end

      if players and players.length > 0
        args << "-p" << "#{players}"
      end

      # stdin, stdout_err, wait_thr = Open3.popen2e('ruby', filename, args)
      # pid = wait_thr.pid
      # pidfile = filename.gsub(/\.rb$/, '.pid')
      # File.open(pidfile, 'w+') do |f|
      #   f.write(pid)
      # end

      # exit_code = wait_thr.value
      # outfile = filename.gsub(/\.rb$/, '.out')
      # File.open(outfile, 'w+') do |f|
      #   f.write(stdout_err.gets(nil))
      # end
      # stdin.close
      # stdout_err.close

      Open3.popen2e('ruby', filename, *args) do |stdin, stdout_err, wait_thr|
        pid = wait_thr.pid
        pidfile = filename.gsub(/\.rb$/, '.pid')
        File.open(pidfile, 'w+') do |f|
          f.write(pid)
        end

        Thread.new do
          begin
            outfile = filename.gsub(/\.rb$/, '.out')
            f = File.open(outfile, 'w+')
            loop do
              f.write(stdout_err.gets)
            end
          ensure
            f.close
          end
        end

        exit_code = wait_thr.value
      end

      logger.info("runQuery done.")
    end
  end


  def on_start_filename
    File.expand_path(File.join(Rails.root, 'tmp', 'queries', 'on_start.part'))
  end

  def do_model_filename
    File.expand_path(File.join(Rails.root, 'tmp', 'queries', 'do_model.part'))
  end

  def on_finish_filename
    File.expand_path(File.join(Rails.root, 'tmp', 'queries', 'on_finish.part'))
  end

end


require 'uri'
require 'chronic'

module Boot

  module Helper

    # sleep adpated to both EM and normal environments
    def self.sleep(time)
      if EM.reactor_running? and not $boot_cleanup
        EM::Synchrony.sleep time
      else
        Kernel.sleep time
      end
    end

    # hold mutex
    def self.lock_mutex mutex, max_try_limit = 100, try_interval = 0.05
      counter = 0
      while not mutex.try_lock do
        raise "lock_mutex failed!" if counter > max_try_limit
        Boot::Helper.sleep try_interval # yield for other fibers to free mutex
        counter += 1
        # puts "wait mutex=#{mutex} counter=#{counter} ========="
      end
      # puts "acquired mutex=#{mutex} counter=#{counter} ========="
    end

    # free mutex
    def self.unlock_mutex mutex
      # puts "unlock mutex=#{mutex} ========="
      mutex.unlock
    end

    def self.schedule_everyday(timeString, &blk)
      now = Time.now
      duration = Chronic.parse(timeString) - now
      if duration < 0
        duration = Chronic.parse("tomorrow at #{timeString}") - now
      end

      EM::Synchrony.add_timer(duration) do
        begin
          yield
        rescue => e
          Log_.error('schedule_everyday Error: ', e)
        ensure
          Helper.schedule_everyday(timeString, &blk)
        end
      end

      Log_.info("schedule_everyday: scheduled after #{duration} (#{(now + duration)})")
    end

    def self.perform_with_delay(duration, &_blk)
      if duration > 0
        EM::Synchrony.add_timer(duration) do
          begin
            yield
          rescue => e
            Log_.error('schedule_at Error: ', e)
          end
        end

        Log_.info("schedule_at: scheduled after #{duration} ")
      end
    end

    def self.schedule_at(time, &_blk)
      duration = time.to_i - Time.now.to_i

      if duration > 0
        EM::Synchrony.add_timer(duration) do
          begin
            yield
          rescue => e
            Log_.error('schedule_at Error: ', e)
          end
        end

        Log_.info("schedule_at: scheduled after #{duration} (#{Time.at(time.to_i)})")
      end
    end

    # sufficient for our use at the moment, no need for a 3rd party gem
    def self.processor_count
      case RbConfig::CONFIG['host_os']
      when /darwin9/
        `hwprefs cpu_count`.to_i
      when /darwin/
        ((`which hwprefs` != '') ? `hwprefs thread_count` : `sysctl -n hw.ncpu`).to_i
      when /linux/
        `cat /proc/cpuinfo | grep processor | wc -l`.to_i
      when /freebsd/
        `sysctl -n hw.ncpu`.to_i
      when /mswin|mingw/
        require 'win32ole'
        wmi = WIN32OLE.connect('winmgmts://')
        cpu = wmi.ExecQuery('select NumberOfCores from Win32_Processor') # TODO: count hyper-threaded in this
        cpu.to_enum.first.NumberOfCores
      end
    end

    @@flamegraph_index = 0

    def self.flamegraph_rotate(n = 8, &blk)
      @@flamegraph_index = (@@flamegraph_index + 1) % n
      require 'flamegraph'
      Flamegraph.generate("graph-#{@@flamegraph_index}.html", :fidelity => 0.5) do
        blk.call
      end
    end

  end
end

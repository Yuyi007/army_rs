
module Stats
  module BaseParser

    def redis
      return RedisFactory.stat_redis
    end

    def payment_hash_key
      :payment_list_hash
    end

    def payment_user_key(zone_id, user_id)
      "_plh_#{zone_id}_u_#{user_id}"
    end

    def is_paid_user?(zone_id, user_id)
      redis.hget(payment_hash_key, payment_user_key(zone_id, user_id)).to_i > 0
    end

    def run
      counter = 0
      @start_time = Time.now

      on_start

      $stdin.each_line do |line|
        counter += 1
        puts "[#{self.class.name}]".color(:green) + " #{Time.now}" + " #{counter} ".color(:cyan) + 'has been parsed' if counter % 1000 == 0
        parse_line line
      end

      @end_time = Time.now
      puts "[#{self.class.name}]".color(:green) + " parsed total " + "#{counter}".color(:cyan).bright + " lines, running time: " + "#{@end_time - @start_time} seconds".color(:magenta)

      on_finish

      @finish_time = Time.now
      puts "[#{self.class.name}]".color(:green) + " commiting time: " + "#{@finish_time - @end_time} seconds".color(:magenta)
    end

  end

  module StatsParser
    include BaseParser

    def initialize(options={})
      @line_exp = /^([\d\-:T\.]+[\+\-]\d\d:00) [0-9a-zA-Z\-_]+ stat\[\d+\]: [\d:\.]+ \[info\]+ -- (\w+), (.*)/
      # @line_exp = /^([\d\-:T\.]+[\+\-]\d\d:00) [0-9a-zA-Z\-\.]+ stat\[\d+\]:+ \[info\]+ -- (\w+), (.*)/ #local
      @options = options
      @config = options[:config]
    end

    def parse_line(line)
      record_time, command, param = *line.scan(@line_exp)[0]
      parse(record_time, command, param)
    end

    def parse(record_time, command, param)
      # puts "command:#{command}  @options[:key_name]:#{ @options[:key_name]}"
      # puts ">>>>command:#{command} @options[:key_name]:#{@options[:key_name] }"
      # is_key_arr = @options[:key_name].instance_of?(Array)
      # return if is_key_arr && !@options[:key_name].include?(command)
      # return if !is_key_arr && command != @options[:key_name] 
      record_time = DateTime.parse(record_time).to_time if record_time

      if record_time
        begin
          parse_command record_time, command, param
        rescue => e
          puts "parse line: " + line.color(:yellow) + " FAILED!".color(:red)
          puts e.inspect.color(:red)
          ap e.backtrace
        end
      end
    end

    #return: pid cid
    def parse_pid(uid)
      arr = uid.split('_')
      if arr.length == 1
        return [uid, uid]
      else
        return [uid, arr[1]]
      end
    end

    # def batch(model, condition, batch_num = 1000)
    #   @batchs ||= {}
    #   @batchs[model.to_s] ||= []
    #   batch = @batchs[model.to_s]

    #   table_name = model.table_name

    #   data = yield({})
    #   data ||= {}

    #   tmp_cols = []
    #   tmp_vals = []
    #   tmp_mads = []

    #   data.each do |k, v|
    #     column = model.column_hash[column_name]

    #     vs = ''
    #     case column.type
    #     when :string
    #       vs =  "'#{v.to_s}'"
    #     when :date
    #       vs =  "'#{v.to_s}'"
    #     when :integer
    #       vs = v.to_s
    #     else
    #       vs = v.to_s
    #     end

    #     tmp_mads << " #{column_name} = #{vs} "
    #   end

    #   modify_data = tmp_mads.join(', ')

    #   model.attribute_names.each do |column_name|
    #     column = model.column_hash[column_name]

    #     k = column_name.to_s
    #     tmp_cols << k

    #     v = data[k] || column.default
    #     vs = ''
    #     case column.type
    #     when :string
    #       vs =  "'#{v.to_s}'"
    #     when :date
    #       vs =  "'#{v.to_s}'"
    #     when :integer
    #       vs = v.to_s
    #     else
    #       vs = v.to_s
    #     end
    #     tmp_vals << vs
    #   end

    #   column_data = tmp_cols.join(', ')
    #   new_data = tmp_vals.join(', ')
      

    #   sql = %Q{
    #     INSERT INTO #{table_name} (#{columns}) VALUES (#{new_data}) ON DUPLICATE KEY UPDATE #{modify_data}
    #   }
        
    #   puts ">>>sql:#{sql}"
    #   batch << sql
    #   return if batch.length < batch_num
      
    #   sql = batch.join(' \n ')
    #   ActiveRecord::Base.connection.exec_query(sql)
    #   @batchs[model.to_s] = []
    # end

    def batch_commit(model)
      batch = @batchs[model.to_s]
      return if batch.nil?

      model.import(batch)
      @batchs[model.to_s] = []
    end

    def batch(model, condition, batch_num = 1000)
      @batchs ||= {}
      @batchs[model.to_s] ||= []
      batch = @batchs[model.to_s]

      is_new = false
      record = model.where(condition).first
      if record.nil?
        is_new = true
        record = model.new
        condition.each do |k, v|
          record.send("#{k}=", v)
        end
        
        yield(record)

        batch << record
        if batch.length == batch_num
          model.import(batch)
          @batchs[model.to_s] = []
        end
      else
        yield(record)
        record.save
      end
    end
  end
end

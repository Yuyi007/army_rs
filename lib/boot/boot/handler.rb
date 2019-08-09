
module Boot
  class Handler
    include Loggable
    def self.multi_process(batch_num, session, msg, model)
      res = {"success" => true, "process_list" => []}
      batch_num.times do |i|
        res_sub = self.process(session, msg, model)
        res["process_list"] << res_sub
        res['hide_hero_attr_change'] = true if res_sub['hide_hero_attr_change']
        # puts "check batch num: #{i}, #{res_sub['success']}, #{res_sub['stop_batch']}"
        break if (not res_sub["success"]) || res_sub["stop_batch"]
      end
      res
    end


    def self.ng(reason, *ng_args)
      { 'success' => false, 'reason' => reason, 'ng_args' => ng_args }
    end

    def self.ng_code(reason)
      { 'success' => false, 'error_code' => reason}
    end

    def self.suc(data = nil)
      if data
        { 'success' => true }.merge(data)
      else
        { 'success' => true }
      end
    end

    def self.set_session_nonce(session, msg, res)
      # set nonce
      if AppConfig.dev_mode? && !msg.reset_nonce
        nonce = ServerEncoding.comm_nonce
      else
        nonce = RbNaCl::Random.random_bytes(24)
      end
      nonce_arr = nonce.unpack('C*')
      @@bi_nonce_arr ||= ServerEncoding.bi_nonce.unpack('C*')

      res['nonce'] = nonce_arr
      res['bi_nonce'] = @@bi_nonce_arr

      # after sending the response of this handler, we set nonce to the new nonce
      session.codec_state_next = CodecState.new(nonce)
      
      res
    end

    def self.get_cid_by_pid(pid)
      Helper.get_cid_by_pid(pid)
    end

    def self.log_drops_or_reduces(instance, reason, bonuses, reduces)
      cid  = instance.chief_id
      zone = instance.zone
      pid  = instance.player_id

      reason ||= self.name
      array_bonuses = get_item_list_info(bonuses) || []
      array_reduces = get_item_list_info(reduces) || []

      if array_reduces.size > 0 || array_bonuses.size > 0
        obtain_str = ''
        reduce_str = ''
        obtain_str = "gain:#{array_bonuses.join(',')}" if array_bonuses.size > 0
        reduce_str = "uses:#{array_reduces.join(',')}" if array_reduces.size > 0
        currency_str = get_currency_info(instance)
        # d {"log_drops_or_reduces #{cid} #{zone} #{reason} #{reduce_str} #{obtain_str} #{currency_str}"}
        ActionDb.log_action(cid, zone, reason, pid, reduce_str, obtain_str, currency_str)
      end
    end

    def self.get_item_list_info(item_list)
      array = nil
      if item_list && item_list.size > 0 && item_list.is_a?(::Array)
        # puts "check item list: #{item_list}"  # 【 nil 】 if bag oversize when give item with cheat code
        array = item_list.map do |o|
          # puts "check o : #{o}, #{o.nil?}"
          next "" if o.nil?
          tid = o.tid
          next '' unless tid
          o = o.to_hash unless o.is_a?(::Hash)
          count = o['count'] || 1

          type = GameConfig.get_type(tid)
          if type
            "#{tid}x#{count.abs}"
          else
            ''
          end
        end

        array.delete_if {|x| x.to_s.empty?}
      end

      array
    end

    def self.get_currency_info(instance)
      if instance
         "coins:#{instance.coins} money:#{instance.money} credits:#{instance.credits}"
      else
        return ""
      end
    end

    # get the drop stats from the bonuses list
    # @param bonuses [Array] an array of bonus hashes
    #
    # @return [Hash] [hash of {tid => num}]
    def self.get_drop_stats(bonuses)
      fail 'bonuses must be an Array' unless bonuses.is_a?(::Array)

      hash = {}
      bonuses.each do |data|
        next unless data.is_a?(::Hash)
        next unless data.tid

        hash[data.tid] ||= 0
        if data['count']
          hash[data.tid] += data['count']
        else
          hash[data.tid] += 1
        end
      end
      hash
    end

    def self.get_reduce_stats(reduces)
      fail 'reduces must be an Array' unless reduces.is_a?(::Array)

      hash = {}
      reduces.each do |data|
        next unless data.is_a?(::Hash)
        next unless data.tid

        hash[data.tid] ||= 0
        if data['count']
          hash[data.tid] += data['count'].abs
        else
          hash[data.tid] += 1
        end
      end
      hash
    end
  end
end

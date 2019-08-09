class CombatServerDB
	include RedisHelper
	include Loggable
  @@timeout = 5*2

	GET_SERVER = %Q{
		local count_key, status_key, tick_key = unpack(KEYS)
  	local now, timeout = unpack(ARGV)
  	local tmp = redis.call('hgetall', tick_key)
  	
    now = tonumber(now)
    timeout = tonumber(timeout)

  	local STATUS_DISABLE = 0
    local STATUS_ENABLE = 1

  	--check server usable
  	for i=1,#tmp,2 do 
  		local srv = tmp[i]
  		local tick = tonumber( tmp[i+1] )
  		if (now - tick) > timeout then
  			redis.call('hset', status_key, srv, STATUS_DISABLE)
      else
        redis.call('hset', status_key, srv, STATUS_ENABLE)
  		end
  	end

  	--get usables server keys
  	local srvs = {}
  	tmp = redis.call('hgetall', status_key)
  	for i=1,#tmp,2 do 
  		local srv = tmp[i]
  		local status = tmp[i+1]
  		srvs[srv] = tonumber( status )
  	end

  	
  	local counts = redis.call('hgetall', count_key)
  	local min = nil
    local srv = nil
  	for i=1,#counts,2 do 
      local _srv = counts[i]
      if srvs[_srv] == STATUS_ENABLE then 
        local _count = counts[i+1]
        if not min then
          srv = _srv
          min = _count
        else
      		if min > _count then
            srv = _srv
      			min = _count
      		end 
        end
      end
  	end

  	--increase payload
    if min then 
  	   redis.call('hset', count_key, srv, min + 1)
    end

  	return srv
	}

 
  def self.get_all_server
    srvList=[]
    now = Time.now.to_i
    tickList=redis.hgetall(tick_key)
    begintickList=redis.hgetall(begintick_key)
    roomcountList=redis.hgetall(room_count_key)
    conncountList=redis.hgetall(conn_count_key)
    sendList=redis.hgetall(send_bytes_key)
    recvList=redis.hgetall(recv_bytes_key)
    tickList.each do |key,value|
      srv= {}
      srv['key']=key
      srv['tick']=value
      srv['begin_tick']=begintickList[key]
      if now-value.to_i > @@timeout then
        srv['conn_count']=0
        srv['room_count']=0
        srv['send_bytes']=0
        srv['recv_bytes']=0
        srv['status']=0
      else
        srv['conn_count']=conncountList[key]
        srv['room_count']=roomcountList[key]
        srv['send_bytes']=sendList[key]
        srv['recv_bytes']=recvList[key]
        srv['status']=1
      end
      srvList << srv
    end
    return srvList
  end

	def self.get_server
		now = Time.now.to_i
		srv = redis.evalsmart(GET_SERVER, keys: [count_key, status_key, tick_key], argv: [now, @@timeout])
    if srv.nil?
  		warn "no combat server available" 
      return [nil, nil]
    end
		return srv.split('_')
	end

	private

	def self.redis
		get_redis(:servers)
	end

	def self.count_key
		"{combat_servers}:count"
	end

	def self.status_key
		"{combat_servers}:status"
	end

	def self.tick_key
		"{combat_servers}:tick"
	end

  def self.begintick_key
    "{combat_servers}:begintick"
  end
  def self.conn_count_key
    "{combat_servers}:conncount"
  end

  def self.room_count_key
    "{combat_servers}:roomcount"
  end

  def self.send_bytes_key
    "{combat_servers}:sendbytes"
  end

  def self.recv_bytes_key
    "{combat_servers}:recvbytes"
  end


end
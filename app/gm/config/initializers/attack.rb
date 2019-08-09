# Always allow requests from localhost
# (blacklist & throttles are skipped)
Rack::Attack.whitelist('allow from localhost') do |req|
  # Requests are allowed if the return value is truthy
  '127.0.0.1' == req.ip
end

# Block requests
Rack::Attack.blacklist('block some IPs') do |req|
  # Request are blocked if the return value is truthy
  '1.2.3.4' == req.ip
end

# Block logins from a bad user agent
Rack::Attack.blacklist('block bad UA logins') do |req|
  req.path =~ /user_sessions/ && req.post? && req.user_agent == 'Microsoft URL Control'
end

# Lockout IP addresses that are hammering your login page.
# After 20 requests in 1 minute, block all requests from that IP for 1 hour.
Rack::Attack.blacklist('allow2ban login scrapers') do |req|
  # `filter` returns false value if request is to your login page (but still
  # increments the count) so request below the limit are not blocked until
  # they hit the limit.  At that point, filter will return true and block.
  Rack::Attack::Allow2Ban.filter(req.ip, :maxretry => 20, :findtime => 1.minute, :bantime => 12.hour) do
    # The count for the IP is incremented if the return value is truthy.
    req.path =~ /user_sessions/ and req.post?
  end
end

# Throttle requests to 50 requests per second per ip
Rack::Attack.throttle('req/ip', :limit => 50, :period => 1.second) do |req|
  # If the return value is truthy, the cache key for the return value
  # is incremented and compared with the limit. In this case:
  #   "rack::attack:#{Time.now.to_i/1.second}:req/ip:#{req.ip}"
  #
  # If falsy, the cache key is neither incremented nor checked.

  req.ip
end

# Throttle login attempts for a given email parameter to 20 reqs/minute
# Return the email as a discriminator on POST /login requests
Rack::Attack.throttle('logins/ip', :limit => 100, :period => 5.minutes) do |req|
  req.ip if req.path =~ /user_sessions/ and req.post?
end

ActiveSupport::Notifications.subscribe('rack.attack.throttle_data') do |name, start, finish, request_id, req|
  #Rails.logger.info "rack.attack.throttle_data=#{req.env['rack.attack.throttle_data']} REMOTE_ADDR=#{req.env['REMOTE_ADDR']}"
end

Rack::Attack.blacklisted_response = lambda do |env|
  # Using 503 because it may make attacker think that they have successfully
  # DOSed the site. Rack::Attack returns 403 for blacklists by default
  [ 503, {}, ['Blocked']]
end

Rack::Attack.throttled_response = lambda do |env|
  # name and other data about the matched throttle
  body = [
    env['rack.attack.matched'],
    env['rack.attack.match_type'],
    env['rack.attack.match_data']
  ].inspect

  # Using 503 because it may make attacker think that they have successfully
  # DOSed the site. Rack::Attack returns 429 for throttling by default
  [ 503, {}, [body]]
end

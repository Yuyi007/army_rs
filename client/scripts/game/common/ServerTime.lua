
class('ServerTime')

ServerTime.timeDiff = 0

local math, os, string = math, os, string

local seconds_a_day   = 60*60*24
local seconds_a_min   = 60
local seconds_an_hour = 60 * 60

local dayHash = {hour = 0}

function ServerTime.update(serverTime)
  if not serverTime then
    -- logwarn('serverTime not provided')
    return
  end

  local now = unity.osTime()
  local ping = mp:getAverageRTT()
  ServerTime.serverResetTime = serverTime.reset_time
  ServerTime.timeDiff = math.round(now - (serverTime.time + (ping / 2000)))
  -- loge('serverTime = %s, now = %s, ping = %s, diff = %s', serverTime.time, now, ping / 2000, ServerTime.timeDiff)
end

function ServerTime.time()
  local now = unity.osTime()
  return (now - ServerTime.timeDiff)
end

function ServerTime.ptime()
  local now = unity.preciseTime()
  return (now - ServerTime.timeDiff)
end

function ServerTime.zeroClock(time)
  local zero = time or ServerTime.time()
  zero       = os.date("*t", zero)

  dayHash.year  = zero.year
  dayHash.month = zero.month
  dayHash.day   = zero.day
  dayHash.hour  = 0

  return os.time(dayHash)
end

function ServerTime.resetTime()
  if ServerTime.serverResetTime then
    return ServerTime.serverResetTime
  end

  local now = ServerTime.time()
  local dateData = os.date("*t", now)

  dayHash.year  = dateData.year
  dayHash.month = dateData.month
  dayHash.day   = dateData.day
  dayHash.hour  = 0
  return os.time(dayHash)
end

function ServerTime.getDateString(time)
  local dateData = os.date("*t", time)
  return loc('str_birthday_disp', dateData.year, dateData.month, dateData.day)
end

function ServerTime.getTimeInHour(hour)
  return ServerTime.resetTime() + hour * 3600
end

function ServerTime.resetTimeInHour(hour)
  local t = hour * 3600
  local rt = ServerTime.resetTime()
  local now = ServerTime.time()
  local time = ServerTime.getTimeInHour(hour)
  if now - rt < t then
    time = time - 86400
  end
  return time
end

function ServerTime.isTimeInInterval(hour1, hour2)
  local now = ServerTime.time()
  return now >= ServerTime.getTimeInHour(hour1) and now <= ServerTime.getTimeInHour(hour2)
end

-- 返回星期  sunday = 0
function ServerTime.wday(time)
  local now = time or ServerTime.time()
  local nowData = os.date("*t", now)
  return nowData.wday - 1
end

function ServerTime.calcResetTime(time)
  local resetTime = ServerTime.resetTime()
  local offsetTime = (math.floor((time - resetTime) / seconds_a_day) * seconds_a_day)
  --logd('calcResetTime %s %s', resetTime, offsetTime)
  return resetTime + offsetTime
end

function ServerTime.nowDate()
  -- logd("nowDate begin")
  local now = ServerTime.time()
  -- logd("nowDate end")
  return os.date("*t", now)
end

function ServerTime.sinceTime(time)
  local now = ServerTime.time()
  local difftime = now - time
  local days = math.floor(difftime / seconds_a_day)
  difftime = difftime - days * seconds_a_day
  local hours = math.floor(difftime  / seconds_an_hour)
  difftime = difftime - hours * seconds_an_hour
  local mins = math.floor(difftime / seconds_a_min)
  return days, hours, mins
end

function ServerTime.timeSpan(startTime, endTime)
  if game.location == 'th2' then
    return os.date("%d", startTime)..loc('str_lua_116')..
                            os.date("%m", startTime)..'-'..
                            os.date("%d", endTime)..loc('str_lua_116')..
                            os.date("%m", endTime)
  else
    return os.date("%m", startTime)..loc('str_lua_116')..
                            os.date("%d", startTime)..'-'..
                            os.date("%m", endTime)..loc('str_lua_116')..
                            os.date("%d", endTime)
  end
end

function ServerTime.timeLeft(time)
  local now = ServerTime.time()
  local difftime = math.max(time - now, 0)
  return ServerTime.duration(difftime)
end

function ServerTime.duration(duration)
  duration = duration or 0
  local difftime = duration

  local days = math.floor(difftime / seconds_a_day)
  difftime = difftime - days * seconds_a_day
  local hours = math.floor(difftime  / seconds_an_hour)
  difftime = difftime - hours * seconds_an_hour
  local mins = math.floor(difftime / seconds_a_min)
  difftime = difftime - mins * seconds_a_min
  local seconds = difftime
  return days, hours, mins, seconds
end

function ServerTime.guild_cd(cd)
  return ServerTime.format(ServerTime.duration(cd))
end

function ServerTime.cd(time)
  return ServerTime.format(ServerTime.timeLeft(time))
end

function ServerTime.cd2(time)
  return ServerTime.format2(ServerTime.timeLeft(time))
end

function ServerTime.cd3(time)
  local days, hours, mins, seconds = ServerTime.timeLeft(time)
  return string.format("%d:%02d:%02d", days * 24 + hours, mins, seconds)
end

function ServerTime.cd4(time)
  return ServerTime.format9(ServerTime.timeLeft(time))
end

function ServerTime.cd5(time)
  local now = stime()
  local difftime = math.max(now - time, 0)
  return ServerTime.format2(ServerTime.duration(difftime))
end

function ServerTime.cd6(time)
  local days, hours, mins, seconds = ServerTime.duration(time)
  return ServerTime.format5(mins, seconds)
end

function ServerTime.cd7(time)
  return ServerTime.format2(ServerTime.duration(time))
end

function ServerTime.cd8(time)
  return ServerTime.format10(ServerTime.duration(time))
end

function ServerTime.format2(days, hours, mins, seconds)
  return string.format("%02d:%02d:%02d", hours, mins, seconds)
end

function ServerTime.format5(mins, seconds)
  return string.format("%02d:%02d", mins, seconds)
end

function ServerTime.format9(days, hours, mins, seconds)
  return string.format("%02d%02d%02d", hours, mins, seconds)
end

function ServerTime.format10(days, hours, mins, seconds)
  local int_seconds = math.floor(seconds)
  local milliseconds = seconds - int_seconds
  seconds = int_seconds
  milliseconds = math.floor(milliseconds*100)
  return string.format("%02d:%02d:%02d", mins, seconds, milliseconds)
end

function ServerTime.formatDuration(duration)
  local days, hours, mins, seconds = ServerTime.duration(duration)
  local arr = {}

  if days > 0 then
    table.insert(arr, loc('str_time_days', days))
  end

  if hours > 0 then
    table.insert(arr, loc('str_time_hours', hours))
  end

  if mins > 0 then
    table.insert(arr, loc('str_time_mins', mins))
  end

  if seconds > 0 then
    table.insert(arr, loc('str_time_sec', seconds))
  end

  return table.concat(arr, '')
end

function ServerTime.format(days, hours, mins, seconds)
  if days > 0 then
    return loc('str_time_days', days)
  end

  if hours > 0 then
    return loc('str_time_hours', hours) .. loc('str_time_mins', mins)
  end

  if mins > 0 then
    return loc('str_time_mins', mins) .. loc('str_time_sec', seconds)
  end

  if seconds > 0 then
    return loc('str_time_sec', seconds)
  end
end

function ServerTime.formatTimePast(time)
  local duration = stime() - time
  local days, hours, mins, seconds = ServerTime.duration(duration)
  if days > 30 then
    return loc('str_time_months_ago', math.floor(days / 30))
  end

  if days > 7 then
    return loc('str_time_weeks_ago', math.floor(days / 7))
  end

  if days > 0 then
    return loc('str_time_days_ago', days)
  end

  if hours > 0 then
    return loc('str_time_hours_ago', hours)
  end

  if mins > 0 then
    return loc('str_time_mins_ago', mins)
  end

  if seconds > 0 then
    return loc('str_time_secs_ago', seconds)
  else
    return loc('str_ui_employ_111', seconds)
  end
end

function ServerTime.formatTimePast2(time)
  local duration = ServerTime.zeroClock() + 24 * 60 * 60 - time
  local days, hours, mins, seconds = ServerTime.duration(duration)

  if days > 30 then
    return loc('str_time_months_ago', math.floor(days / 30))
  end

  if days > 7 then

    return loc('str_time_weeks_ago', math.floor(days / 7))
  end

  if days > 1 then
    return loc('str_time_days_ago', days)
  end
  if days == 1 then
    return loc('str_chat_time_yesterday')
  end

  return os.date("%H:%M", time)
end

function ServerTime.format3(time)
  return os.date("%Y/%m/%d %X", time)
end

function ServerTime.format4(time)
  return os.date("%Y-%m-%d", time)
end



function ServerTime.format6(time)
  local o = os.date("*t", time)
  return string.format('%s月%s日', o.month, o.day)
end

function ServerTime.format7(time)
  local o = os.date("*t", time)
  return string.format('%s年%s月%s日', o.year, o.month, o.day)
end

function ServerTime.format8(time)
  local o = os.date("*t", time)
  return string.format('%s/%s/%s %s', o.year, o.month, o.day, os.date("%H:%M", time) )
end

function ServerTime.hourMin(time)
  return os.date("%H:%M", time)
end

-- time string format like this
-- dd:hh:mm:ss
-- hh:mm:ss
-- mm:ss
-- ss
function ServerTime.parseDuration(timeStr)
  local timeSegs = string.split(timeStr, ":")
  local timeTable = {
    1,
    seconds_a_min,
    seconds_an_hour,
    seconds_a_day,
  }

  local duration = 0
  local idx = 1
  for i = #timeSegs, 1, -1 do
    duration = duration + timeTable[idx] * tonumber(timeSegs[i])
    idx = idx + 1
  end
  return duration
end

function ServerTime.month(time)
  local time = time or ServerTime.time()
  local o = os.date("*t", time)
  return o.month
end

function ServerTime.day(time)
  local time = time or ServerTime.time()
  local o = os.date("*t", time)
  return o.day
end

function ServerTime.getMonthDays()
  local now = ServerTime.time()
  local dateData = os.date("*t", now)

  dayHash.year  = dateData.year
  dayHash.month = dateData.month + 1
  if dayHash.month > 12 then
    return 31
  end
  dayHash.day   = 1
  dayHash.hour  = 0
  dateData = os.date("*t", os.time(dayHash) - 1)
  return dateData.day
end

function ServerTime.isManualResetTimePassed(manual_secs, record_time, cur_time)
  local rt = ServerTime.calcResetTime(record_time) + manual_secs
  local cur_time = cur_time or stime()
  if record_time > rt then rt = rt + 24 * 3600 end
  return cur_time > rt
end


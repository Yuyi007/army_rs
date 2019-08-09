require_relative 'stats_req'

class RechargeController < ApplicationController

  def get_player_recharge_record
    return ng('verify fail') if !check_session

    zone_id = params[:zone_id]
    date_start = params[:start_date]
    date_end = params[:end_date]
    platform = params[:platform]
    return ng('invalid args') if zone_id.nil? || date_start.nil? || date_end.nil? || platform.nil?

    start_date = DateTime.parse(date_start).to_date
    str_start_date = start_date.strftime('%Y-%m-%d')

    end_date = DateTime.parse(date_end).to_date
    str_end_date = end_date.strftime('%Y-%m-%d')


    sql = %Q{
      select pid, date, zone_id, platform, num, goods, first_date
      from recharge_record
      where zone_id = #{zone_id} and platform = '#{platform}' and
            ((date >= '#{str_start_date}' and date <= '#{date_end}') or
             (first_date >= '#{str_end_date}' and first_date <= '#{date_end}'))
      order by goods desc
    }

    rcs = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end

  def get_player_recharge_report
    return ng('verify fail') if !check_session

    cat = params[:cat]
    date_start = params[:date_start]
    date_end = params[:date_end]
    platform = params[:platform]
    return ng('invalid args') if cat.nil? || date_start.nil?  || date_end.nil?  || platform.nil?

    start_date = DateTime.parse(date_start).to_date
    str_start_date = start_date.strftime('%Y-%m-%d')

    end_date = DateTime.parse(date_end).to_date
    str_end_date = end_date.strftime('%Y-%m-%d')

    days = end_date - start_date

    arr = cat.split('#')
    key_type = arr[0].to_sym
    key_value = Mysql.escape_string(arr[1])

    puts ">>>key_type:#{key_type}"
    cond_sz = 'true'
    cond_sz_player = 'true'
    case key_type
    when :sdk
      cond_sz = "sdk = '#{key_value}' and zone_id = 0"
      cond_sz_player = "sdk = '#{key_value}'"
    when :zone_id
      cond_sz = "zone_id = #{key_value} and sdk is null"
      cond_sz_player = "zone_id = #{key_value}"
    when :all
      cond_sz = "sdk is null and zone_id != 0"
    end

    cond_plat = "platform = '#{platform}'"
    cond_plat = 'true' if platform == 'all'

    sql = %Q{
      select distinct(goods)
      from recharge_report
      where #{cond_plat} and date >= '#{str_start_date}' and date <= '#{str_end_date}' and #{cond_sz}
    }
    data = []
    rcs = execSql(sql)
    if !rcs.nil?
      puts ">>>>days:#{days}"
      (0..days).each do |i|
        date = (start_date + i).strftime('%Y-%m-%d')

        rcs.to_hash.each do |rc|
          d = { :goods => rc['goods'],
                :platform => platform,
                :key_value => key_value,
                :date => date,
                :new_num => 0,
                :num => 0,
                :new_players => 0,
                :players => 0}
          # puts ">>>rcs.to_hash:#{rcs.to_hash}"


          sql = %Q{
            select sum(num) as num
            from recharge_report
            where #{cond_sz} and #{cond_plat} and date = '#{date}' and isnew = 1 and  goods='#{d[:goods]}'
          }
          c = execSql(sql)
          if !c.nil?
            d[:new_num] = c.first['num'] || 0
          end

          sql = %Q{
            select sum(num) as num
            from recharge_report
            where #{cond_sz} and #{cond_plat} and date = '#{date}' and isnew = 0 and goods='#{d[:goods]}'
          }
          c = execSql(sql)
          if !c.nil?
            d[:num] = c.first['num'] || 0
          end


          sql = %Q{
            select count(distinct pid) as count
            from recharge_record
            where #{cond_sz_player} and #{cond_plat} and date = '#{date}' and isnew = 1 and goods='#{d[:goods]}'
          }
          c = execSql(sql)
          if !c.nil?
            d[:new_players] = c.first['count'] || 0
          end

          sql = %Q{
            select count(distinct pid) as count
            from recharge_record
            where #{cond_sz_player} and #{cond_plat} and date = '#{date}' and goods='#{d[:goods]}'
          }
          c = execSql(sql)
          if !c.nil?
            d[:players] = c.first['count'] || 0
          end

          data << d
        end
      end
    end

    #总数统计增加一条记录
    date = (start_date + days).strftime('%Y-%m-%d')
    d = {:goods => '总计',
          :platform => platform,
          :key_value => key_value,
          :date => date,
          :new_num => 0,
          :num => 0,
          :new_players => 0,
          :players => 0}
    sql = %Q{
         select sum(num) as num
            from recharge_report
            where #{cond_sz} and #{cond_plat} and date >= '#{str_start_date}' and date <= '#{str_end_date}' and isnew = 1
      }
    c = execSql(sql)
    num = 0
    num = c.first['num'] if !c.nil?
    d[:new_num] = num

    sql = %Q{
         select sum(num) as num
            from recharge_report
            where #{cond_sz} and #{cond_plat} and date >= '#{str_start_date}' and date <= '#{str_end_date}' and isnew = 0
      }
    c = execSql(sql)
    num = 0
    num = c.first['num'] if !c.nil?
    d[:num] = num


    sql = %Q{
      select count(distinct cid) as num
      from recharge_record
      where #{cond_sz_player} and #{cond_plat} and date >= '#{str_start_date}' and date <= '#{str_end_date}' and isnew = 1
    }
    c = execSql(sql)
    num = 0
    num = c.first['num'] if !c.nil?
    d[:new_players] = num

    sql = %Q{
      select count(distinct cid) as num
      from recharge_record
      where #{cond_sz_player} and #{cond_plat} and date >= '#{str_start_date}' and date <= '#{str_end_date}'
    }
    c = execSql(sql)
    num = 0
    num = c.first['num'] if !c.nil?
    d[:players] = num

    data << d

    res = {'success' => 'ok'}
    # puts ">>>>data:#{data}"
    res['res'] = data
    sendc(res)
  end


  def get_new_player_recharge_report
    return ng('verify fail') if !check_session

    cat = params[:cat]
    date_start = params[:start_date]
    date_end = params[:end_date]
    platform = params[:platform]
    return ng('invalid args') if cat.nil? || date_start.nil? || date_end.nil? || platform.nil?

    arr = cat.split('#')
    key_type = arr[0].to_sym
    key_value = Mysql.escape_string(arr[1])

    puts ">>>key_type:#{key_type}"
    cond_sz = 'true'
    cond_sz_player = 'true'
    case key_type
    when :sdk
      cond_sz = "sdk = '#{key_value}' "
      cond_sz_player = "sdk = '#{key_value}'"
    when :zone_id
      cond_sz = "zone_id = #{key_value}"
      cond_sz_player = "zone_id = #{key_value}"
    end

    cond_plat = "platform = '#{platform}'"
    cond_plat = 'true' if platform == 'all'

    data = []
    sql = %Q{
      select distinct(goods)
      from recharge_record
      where #{cond_sz} and #{cond_plat} and first_date = '#{date_start}' and date <= '#{date_end}' and isnew = 1
    }
    rcs = execSql(sql)
    puts ">>>>rcs:#{rcs}"
    if !rcs.nil?
      rcs.to_hash.each do |rc|
        goods = rc['goods']

        sql = %Q{
          select sum(total_num) as num
          from recharge_record
          where #{cond_sz} and #{cond_plat} and first_date = '#{date_start}' and date <= '#{date_end}' and isnew = 1 and goods = '#{goods}'
        }
        c = execSql(sql)
        num = 0
        num = c.first['num'] if !c.nil?

        sql = %Q{
          select count(distinct cid) as count
          from recharge_record
          where #{cond_sz_player} and #{cond_plat} and first_date = '#{date_start}' and date <= '#{date_end}' and isnew = 1 and goods = '#{goods}'
        }
        c = execSql(sql)
        accounts = 0
        accounts = c.first['count'] if !c.nil?

        data << {:goods => goods, :num => num, :accounts => accounts}
      end
    end

    #总数统计增加一条记录
    sql = %Q{
        select sum(total_num) as num
        from recharge_record
        where #{cond_sz} and #{cond_plat} and first_date = '#{date_start}' and date <= '#{date_end}' and isnew = 1
      }
    c = execSql(sql)
    num = 0
    num = c.first['num'] if !c.nil?

    sql = %Q{
      select count(distinct cid) as count
      from recharge_record
      where #{cond_sz_player} and #{cond_plat} and first_date = '#{date_start}' and date <= '#{date_end}' and isnew = 1
    }
    c = execSql(sql)
    accounts = 0
    accounts = c.first['count'] if !c.nil?
    data << {:goods => '总计', :num => num, :accounts => accounts}

    res = {'success' => 'ok'}
    # puts ">>>>data:#{data}"
    res['res'] = data
    sendc(res)
  end

end
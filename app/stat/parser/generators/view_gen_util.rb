class ViewGenerator
  #categories max is 20
  def tmp_gen_view_by_category_zone(args)
    zone_id = args[:zone_id]
    view_name = args[:view_name]
    categories = args[:categories]
    aliases = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n','o', 'p', 'q', 'r', 's', 't', 'u']
    type_col = args[:type_col] 
    src_table = args[:src_table] 
    columns = args[:columns] 

    index = 0
    cols = " tb_x.date as date"
    categories.each do |cat, name|
      alia = aliases[index]
      tmp_cols = ""
      columns.each do |col, col_name|
        tmp_cols += ", ifnull(#{alia}.#{cat}_#{col}, 0) as #{name}#{col_name}"
      end
      cols += tmp_cols
      index += 1
    end

    index = 0
    tbs = " tmp_date tb_x "
    categories.each do |cat, _|
      tmp_cols = ""
      columns.each do |col, _|
        tmp_cols += ", #{col} as #{cat}_#{col}"
      end
      alia = aliases[index]
      tbs += " left join (select date #{tmp_cols} from #{src_table} where #{type_col} = '#{cat}' and zone_id = #{zone_id}) #{alia} on #{alia}.date = tb_x.date"
      index += 1
    end

    sql = %Q{create or replace view #{view_name} as
              select #{cols} from #{tbs} order by date desc
              }
    # puts ">>>>>#{view_name} sql:#{sql}"
    ActiveRecord::Base.connection.execute(sql)
  end
end
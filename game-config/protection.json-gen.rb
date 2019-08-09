require_relative 'table_help'
select_sheet(0, 2)

all = {}
3.upto $sheet.last_row do |l|
  record = $sheet.row(l)
  # os = {}
  # 2.upto $header.length - 1 do |c|
  #   os[$header[c].to_s] = parse(record[c]) if !record[c].nil? and record[c] != ''
  # end
  all[record[1]] = parse(record[2]) if !record[2].nil? and record[2] != ''
end

save_json('protection', all)
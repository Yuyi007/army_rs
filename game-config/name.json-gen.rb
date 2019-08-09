require_relative 'table_help'
select_sheet(0, 3)

all = []
4.upto $sheet.last_row do |l|
	record = $sheet.row(l)
	# os = []
	
	1.upto $header.length - 1 do |c|
		str = parse(record[0])
		all << str.concat(parse(record[c]))  if !str.nil? and str != ''
	end
end

save_json('name', all)
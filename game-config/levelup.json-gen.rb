require_relative 'table_help'

select_sheet(0, 3)

all = {}
4.upto $sheet.last_row do |l|
	record = $sheet.row(l)
	os = {}
	0.upto $header.length - 1 do |c|
		os[$header[c].to_s] = parse(record[c]) if !record[c].nil? and record[c] != ''
	end
	all[os.level] = os 
end

save_json('levelup', all)
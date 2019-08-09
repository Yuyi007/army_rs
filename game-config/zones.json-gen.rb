require_relative 'table_help'
select_sheet(0,2)

all = []
4.upto $sheet.last_row do |l|
	rec = $sheet.row(l)
	os = {}
	0.upto $header.length - 1 do |c|
		os[$header[c].to_s] = parse(rec[c]) if !rec[c].nil? and rec[c] != ''
	end

	all << os
end

save_json('zones',all)


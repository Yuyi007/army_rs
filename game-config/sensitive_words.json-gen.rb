require_relative 'table_help'

list = {}
select_sheet(0, 1)

list = $sheet.column(1).drop(3)

list.each_with_index do |x, index|
  list[index] = x.to_s.delete('*').strip.downcase
end

list.delete_if { |x| x.to_s.empty? }
list.delete('item')
list.delete('audio')
list.delete('link_item')
list.delete('link_player')
list.delete('link_audio')
list.delete('#')
list.delete('link')
list.delete('player')
list.delete('_')
list.delete('www')

list.uniq!

save_json('sensitiveWords', list)
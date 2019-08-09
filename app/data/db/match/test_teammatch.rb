$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'team_match_5v5'
require 'team_match_3v3'

#a = TeamMatch5V5.new(100, 300)
#(1..500).each do |item|
#	a.addTeam(item, item, rand(1..5))
#end
#tt = a.domatch()
#puts "result 5-5: ", tt



b = TeamMatch3V3.new(1000, 3000)
#add team info 
(1..500).each do |item|
	b.addTeam(item, item, rand(1..3))
end
#do match
tt = b.domatch()
puts "result 3-3: ", tt
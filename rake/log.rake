namespace :log do 

desc 'compress log for today'

task :compress do 
	#server log
	srver_dir = "/var/log/server"
	#stat and sdk
	stat_dir = "/var/log/stat"
	#combat
	combat_dir = "/var/log/combat"

	today = Time.now.to_date
	filename = today.strftime('%Y-%m-%d')
	
	system("zip -r #{filename}.zip #{srver_dir}/server.log")
	system("cat /dev/null > #{srver_dir}/server.log")

	system("zip -r #{filename}.zip #{stat_dir}/server.log")
	system("cat /dev/null > #{stat_dir}/server.log")

	system("zip -r #{filename}.zip #{combat_dir}/server.log")
	system("cat /dev/null > #{combat_dir}/server.log")

	keep_day = today - 15
	filename = today.strftime('%Y-%m-%d')
	system("cat /dev/null > #{srver_dir}/#{filename}.zip")
	system("cat /dev/null > #{stat_dir}/#{filename}.zip")
	system("cat /dev/null > #{combat_dir}/#{filename}.zip")
end
	
end
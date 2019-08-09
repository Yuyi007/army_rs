class CreateStatsServers < ActiveRecord::Migration
	def up
		create_table :stats_server, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string	 :name, 					:null => false
      t.date     :date, 					:null=>false
		end
	end

	def down
		drop_table :stats_server
	end
end
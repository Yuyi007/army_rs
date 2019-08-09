class CreatePlayerRecord < ActiveRecord::Migration
	def up
		create_table :player_record, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string	 :kind, 					:null => false
      t.string   :pid,						:null => false
      t.string   :data,						:null => false
		end
	end

	def down
		drop_table :player_record
	end
end
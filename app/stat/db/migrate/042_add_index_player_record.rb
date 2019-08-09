
class AddIndexPlayerRecord < ActiveRecord::Migration
	def up
		add_index :player_record, [:kind, :pid, :data]
	end
end
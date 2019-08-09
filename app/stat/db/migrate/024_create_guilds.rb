class CreateGuilds < ActiveRecord::Migration
  def change
    create_table :guilds do |t|
      t.string :guild_id
      t.integer :zone
      t.integer :level
      t.integer :member_size
    end
    add_index :guilds, [:guild_id, :zone]
  end
end

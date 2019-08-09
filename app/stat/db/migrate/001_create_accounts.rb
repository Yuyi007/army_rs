class CreateAccounts < ActiveRecord::Migration
  def up
    create_table :accounts, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string   :name
      t.string   :surname
      t.string   :email
      t.string   :crypted_password
      t.string   :role
      t.datetime :login_at,         :null => false
      t.datetime :created_at,       :null => false
      t.datetime :updated_at,       :null => false
    end

    add_index :accounts, :email, :unique => true
    add_index :accounts, :name
  end
 
  def down
    drop_table :accounts
  end
end
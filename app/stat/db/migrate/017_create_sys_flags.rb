require_relative '../../app/models/stats_models'

class CreateSysFlags < ActiveRecord::Migration
  def up
    create_table :sys_flags, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string :flag, primary: true, :null => false
      t.string :value, :limit => 64
    end
    add_index :sys_flags, :flag, :unique => true
    StatsModels::SysFlags.create :flag => 'today_gen_task', :value => 'idle' #'working'
  end

  def down
    drop_table :sys_flags
  end
end
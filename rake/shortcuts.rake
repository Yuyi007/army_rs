# shortcuts.rake

desc 'shortcut: Run combat server'
task c: [:"run:combat"]

desc 'shortcut: Run combat server'
task test: [:"run:loadtest"]

desc 'shortcut: Run verify server'
task v: [:"run:verify"]

desc 'shortcut: Profile gate server'
task pg: [:"run:gate_profile"]

desc 'shortcut: Run data server'
task s: [:"run:data"]

desc 'shortcut: Run data server 2'
task s2: [:"run:data2"]

desc 'shortcut: Run data server 3'
task s3: [:"run:data3"]

desc 'shortcut: Run data server 4'
task s4: [:"run:data4"]

desc 'shortcut: Run checker server'
task checker: [:"run:checker"]

desc 'shortcut: Run checker server 1'
task checker1: [:"run:checker1"]

desc 'shortcut: Run checker server 2'
task checker2: [:"run:checker2"]

desc 'shortcut: Run gm server'
task gm: [:"run:gm"]

desc 'shortcut: Run stats server'
task stats: [:"run:stats"]

desc 'shortcut: Run payment server'
task pay: [:"run:pay"]

desc 'shortcut for game_config:dat'
task config: ['game_config:dat']

desc 'shortcut for game_config:xls'
task xls: ['game_config:xls']

desc 'shortcut for game_config:xlsf[file_name]'
task :xlsf, [:file_name] do |_t, args|
  # :game_config:xlsf[:file_name] # args[:file_name]
  system("rake game_config:xlsf[#{args[:file_name]}]")
end

desc 'shortcut for template:view_add[path_file,prefalb_path_file]'
# rake view_add[camera/PhotoBonusView,ui/camera/camera_event_pop]
task :view_add, [:path_file, :prefab_path_file] do |_t, args|
  # :game_config:xlsf[:file_name] # args[:file_name]
  system("rake template:view_add[#{args[:path_file]},#{args[:prefab_path_file]}]")
end

desc 'shortcut for template:handler_add[path_file,handler_no]'
# rake handler_add[camera/RedeemPhotoBonus,203]
task :handler_add, [:path_file, :handler_no] do |_t, args|
  # :game_config:xlsf[:file_name] # args[:file_name]
  system("rake template:handler_add[#{args[:path_file]},#{args[:handler_no]}]")
end

desc 'shortcut for template:global_effect_add[effect_name]'
# rake effect_add[UpgradeRefundEffect]
task :effect_add, [:effect_name] do |_t, args|
  # :game_config:xlsf[:file_name] # args[:file_name]
  system("rake template:global_effect_add[#{args[:effect_name]}]")
end


desc 'shortcut for template:quest_condition_add[:condition_type]'
# rake quest_condition_add[shot_ghost]
task :quest_condition_add, [:condition_type] do |_t, args|
  # :game_config:xlsf[:file_name] # args[:file_name]
  system("rake template:quest_condition_add[#{args[:condition_type]}]")
end



desc 'shortcut for template:rb_add[file_name]'
task :rb_add, [:file_name, :base_path, :replace_clasee_name] do |_t, args|
  # :game_config:xlsf[:file_name] # args[:file_name]
  system("rake template:rb_add[#{args[:file_name]},#{args[:base_path]},#{args[:replace_clasee_name]}]")
end

desc 'shortcut for template:rb_add_custom[class_name]'
task :rb_add_custom, [:class_name] do |_t, args|
  system("rake template:rb_add_custom[#{args[:class_name]}]")
end

desc 'shortcut for game_config:xls_test'
task xls_test: ['game_config:xls_test']

desc 'shortcut for game_config:check'
task check_config: ['game_config:check']

desc 'shortcut for game_config:scan'
task scan: ['game_config:scan', 'game_config:graph']

desc 'shortcut for game_config:graph'
task graph: ['game_config:graph']

desc 'shortcut for game_config:touch'
task touch: ['game_config:touch']

task jenkins_config: [:xls, :check_config, :config]
# task jenkins_config: ['operation:ioscb']

desc 'task for designer to build test config'
task design_config: [:xls_test, :check_config, :config]

task :md5_copy do
  system("cp game-config/jenkins-xls-md5.json game-config/#{ENV['USER']}-xls-md5.json" )
end

# task :t3_ids do
#   list = JSON.parse(IO.read('alpha_data_back/t3_firevale_ids.json'))
#   hash = ::Hash[list.map {|x| [x, true]}]
#   IO.write('alpha_data/t3_firevale_ids.json', JSON.pretty_generate(hash))
# end

task :t3_chongzhi do
  hash = JSON.parse(IO.read('alpha_data/t3_chongzhi_ids.json'))
  hash = ::Hash[hash.sort_by {|k,v| v}]
  IO.write('alpha_data/t3_chongzhi_ids.json', JSON.pretty_generate(hash))
end


namespace 'template' do
  require 'colorize'


  UI_PATH = "client/scripts/game/ui"
  HANDLER_PATH = "app/data/handlers"
  QUEST_MODEL_PATH = "app/data/model/quests"
  RB_PATH = "app/data/model"
  def get_view_data
    return IO.read("templates/client/View.lua")
  end
  def get_handler_data
    return IO.read("templates/server/handler.rb")
  end
  def get_quest_condition_data
    return IO.read("templates/server/quest_condition.rb")
  end
  def get_effect_data
    return IO.read("templates/server/effect.rb")
  end

  def update_ui_data(path_view_name)
    data = IO.read("#{UI_PATH}/ui.lua")
    data = data.gsub("--TemplateUIFlag", "require \"game/ui/#{path_view_name}\"\n--TemplateUIFlag")
    save_template_data("#{UI_PATH}/ui.lua", data)
  end


  def update_handler_require(handler_no, handler_file_name, handler_name, handler_path)
    data = IO.read("app/world/handler.ex")
    data = data.gsub("#TEMPLATE_HANDLER_FLAG", "  handle_request #{handler_no}, :#{handler_name}\n#TEMPLATE_HANDLER_FLAG")
    save_template_data("app/world/handler.ex", data)

    file  = "handlers/#{handler_path}/#{handler_file_name}"
    if handler_path == "." then
      file = "handlers/#{handler_file_name}"
    end

    data = IO.read("app/data/handlers.rb")
    data = data.gsub("#Template_handler_add", "require \"#{file}\"\n#Template_handler_add")
    save_template_data("app/data/handlers.rb", data)
  end


  def update_effect_require(effect_file_path)
    data = IO.read("app/data/rs.rb")
    data = data.gsub("#Template_effects", "require \"#{effect_file_path}\"\n#Template_effects")
    save_template_data("app/data/rs.rb", data)
  end


  def update_model_require(handler_path_name)
    data = IO.read("app/data/rs.rb")
    data = data.gsub("#Template_quest_condition", "require \"#{handler_path_name}\"\n#Template_quest_condition")
    save_template_data("app/data/rs.rb", data)
  end

  def update_rb_data(rb_file_name, path_rb_name)
    update_model_require("model/#{rb_file_name}/#{path_rb_name}")
  end

  def update_quest_condition_param(condition_type)
    data = IO.read("client/scripts/game/common/quests/QuestProgressCalculator.lua")
    data = data.gsub("--Template_quest_condition", "
function calc_#{condition_type}(params, monitor)
  return m.get_simple_had_count(monitor.count, params.num, monitor)
end
--Template_quest_condition")
    # data = data.gsub("#Template_quest_condition", "require \"#{handler_path_name}\"\n#Template_quest_condition")
    save_template_data("client/scripts/game/common/quests/QuestProgressCalculator.lua", data)


    data = IO.read("game-config/quest_complete_param.rb")
    data = data.gsub("#Template_quest_condition", "
  def self.gen_#{condition_type}(params)
    { \"num\" => params[3].to_i }
  end
#Template_quest_condition")
    # data = data.gsub("#Template_quest_condition", "require \"#{handler_path_name}\"\n#Template_quest_condition")
    save_template_data("game-config/quest_complete_param.rb", data)
  end

  def update_rpc_require(handler_no, handler_name)
    data = IO.read("client/scripts/game/model/ModelRpc.lua")
    data = data.gsub("--TemplateRpcHandler", "
function Model:rpc#{handler_name}(onComplete)
  mp:sendMsg(#{handler_no}, {}, function(msg)
    if msg.success == false then return end
    onComplete(msg)
  end)
end
--TemplateRpcHandler")
    save_template_data("client/scripts/game/model/ModelRpc.lua", data)
  end

  def save_template_data(path_file, data)
    path = File.dirname(path_file)
    Dir.mkdir(path) unless Dir.exist?(path)
    File.open(path_file, 'w+') do |f|
      f.write(data)
    end
    puts "Update file: #{path_file}"
  end

  desc 'add view template use rake view_add[test/MobileView,ui/camera/camera_slot]'
  task :view_add, [:path_view_name,:prefab] do |t, args|
    # puts("check args:#{args}")
    view_detail = File.split(args[:path_view_name])
    prefab = args[:prefab]
    data = get_view_data
    # puts "check view add:#{view_detail}"
    view_name = view_detail[1]
    view_path = view_detail[0]
    puts("check view name:#{view_name} ,path: #{view_path}")
    puts("check view add prefab:#{prefab}, nil? #{prefab.nil?}")
    data = data.gsub("ViewName", view_name)
    data = data.gsub("PrefabPath", (prefab.nil? || prefab == "") ? "nil" : "'prefab/#{prefab}'")
    # puts("check view data:#{data}")
    file  = "#{UI_PATH}/#{view_path}/#{view_name}.lua"
    if view_path == "." then
      file = "#{UI_PATH}/#{view_name}.lua"
      # save_template_data(, data)
    end
    user_agree = true
    if File.exist?(file)
      puts "WARNING: #{file} exits, override it ? y/n"
      input = $stdin.gets.chomp
      if input.downcase[0] != "y"
        puts "User quit, file not generate!!!"
        user_agree = false
      end
    end
    if user_agree
      save_template_data(file, data)
      update_ui_data(args[:path_view_name])
      puts("gen view complete")
    end
  end


  desc 'add quest_condition template use rake quest_condition_add[shot_ghost]'
  task :quest_condition_add, [:condition_type] do |t, args|
    # puts("check args:#{args}")
    condition_type = args[:condition_type]
    file_name = "m#{condition_type}.rb"
    class_name = condition_type.gsub("_", "")
    class_name = "M#{class_name}"
    data = get_quest_condition_data
    data = data.gsub("class_name", class_name)
    puts "check quest condition type::#{condition_type}, #{file_name}, #{class_name}"

    user_agree = true
    file = "#{QUEST_MODEL_PATH}/#{file_name}"
    file_exist = File.exist?(file)
    if file_exist
      puts ("WARNING: #{file} exits, ovrride it ? y/n").colorize(:red)
      input = $stdin.gets.chomp
      if input.downcase[0] != "y"
        puts "User quit, file not generate!!!"
        user_agree = false
      end
    end
    if user_agree
      save_template_data(file, data)
      # if not file_exist
        update_model_require("model/quests/m#{condition_type}")
        update_quest_condition_param(condition_type)
      # end
      str = "CONGRATULATIONS from wisly. Now you may need fill the real param to following files:
      --------------->>>>>  quest_complete_param.rb
      --------------->>>>>  m#{condition_type}.rb
      --------------->>>>>  QuestProgressCalculator.lua"
      puts str.colorize(:green)
    end
  end


  def rb_add_handle(path_rb, base_path, replace_clasee_name)
        #:path_rb, :base_path, :replace_clasee_name

    view_detail = File.split(path_rb)
    data = IO.read(base_path)
    puts "check handler add:#{view_detail}"
    view_name = view_detail[1]
    view_path = view_detail[0]
     view_file_name = view_name.gsub(/[A-Z]/){|s| "_" + s.downcase}
    if view_file_name[0] == "_"
      view_file_name = view_file_name[1..-1]
    end
    puts("check handler name:#{view_name} ,path: #{view_path}")
    puts("check handler add , #{view_file_name}")

    file  = "#{RB_PATH}/#{view_path}/#{view_file_name}.rb"
    if view_path == "." then
      file = "#{RB_PATH}/#{view_file_name}.rb"
      # save_template_data(, data)
    end

    if File.exist?(file)
      return
      puts "WARNING: #{file} exits, ovrride it ? y/n"
      input = $stdin.gets.chomp
      if input.downcase[0] != "y"
        raise "User quit, file not generate!!!"
      end
    end


    puts("----#{file}")
    data = data.gsub(replace_clasee_name, view_name)
    puts("data ====#{data}")
    save_template_data(file, data)
    update_rb_data(view_path, view_file_name)
    puts("gen rb complete")

  end

  task :rb_add, [:path_rb, :base_path, :replace_clasee_name] do |t, args|
    rb_add_handle(args[:path_rb],args[:base_path],args[:replace_clasee_name])
  end

  task :handler_add, [:path_handler_name,:handler_no] do |t, args|
    puts("check args:#{args}")
    handler_detail = File.split(args[:path_handler_name])
    handler_no = args[:handler_no]
    data = get_handler_data
    puts "check handler add:#{handler_detail}"
    # data = data.gsub("ViewName", view_name)

    handler_name = handler_detail[1]
    handler_path = handler_detail[0]
    handler_file_name = handler_name.gsub(/[A-Z]/){|s| "_" + s.downcase}
    if handler_file_name[0] == "_"
      handler_file_name = handler_file_name[1..-1]
    end
    puts("check handler name:#{handler_name} ,path: #{handler_path}")
    puts("check handler add handler_no:#{handler_no}, #{handler_file_name}")

    raise "ERROR Server Hander NO #{handler_no}"  if handler_no.nil? || handler_no == ""


    file  = "#{HANDLER_PATH}/#{handler_path}/#{handler_file_name}.rb"
    if handler_path == "." then
      file = "#{HANDLER_PATH}/#{handler_file_name}.rb"
      # save_template_data(, data)
    end
    # raise "test"
    if File.exist?(file)
      puts "WARNING: #{file} exits, ovrride it ? y/n"
      input = $stdin.gets.chomp
      if input.downcase[0] != "y"
        raise "User quit, file not generate!!!"
      end
    end
    data = data.gsub("handler_name", handler_name)
    save_template_data(file, data)
    update_handler_require(handler_no, handler_file_name, handler_name, handler_path)
    update_rpc_require(handler_no, handler_name)
    puts "handler generated"
  end

  task :rb_add_custom, [:class_name] do |t, args|  # rb_add_handle("要生成的路径和类名", "借用的模板路径", "要替换的借用名称")
    # rb_add_handle("quests/m#{args[:class_name]}", "app/data/model/quests/msns_likes.rb", "Msnslikes")
    # rb_add_handle("title/achievement/A#{args[:class_name]}", "app/data/model/title/achievement/a_ability.rb", "Aability")
    rb_add_handle("title/record/#{args[:class_name]}Record", "app/data/model/title/record/npc_friendship_record.rb", "NpcFriendShipRecord")
  end


  task :global_effect_add, [:effect_name,] do |t, args|
    puts("check effect_name args:#{args}")
    effect_name = args[:effect_name]
    effect_file_name = effect_name.gsub(/[A-Z]/){|s| "_" + s.downcase}
    if effect_file_name[0] == "_"
      effect_file_name = effect_file_name[1..-1]
    end

    file  = "#{RB_PATH}/effects/#{effect_file_name}.rb"
    # raise "test"
    if File.exist?(file)
      puts "WARNING: #{file} exits, ovrride it ? y/n"
      input = $stdin.gets.chomp
      if input.downcase[0] != "y"
        raise "User quit, file not generate!!!"
      end
    end
    data = get_effect_data
    data = data.gsub("EffectName", effect_name)
    save_template_data(file, data)
    update_effect_require("model/effects/#{effect_file_name}")
    puts "global_effect_add generated"
  end

end

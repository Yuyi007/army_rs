
def copy_loc(loc)
  if File.exist?("loc/#{loc}/strings.json")
    cp "loc/#{loc}/strings.json", 'game-config/strings_loc.json'
  end

  files = [
    "loc/#{loc}/config.dat",
    "loc/#{loc}/cdkeys.json"
  ]
  files.each do |file|
    cp file, 'game-config' if File.exist?(file)
  end

  Dir.glob("loc/#{loc}/*.db") do |file|
    cp file, 'game-config'
  end
end

namespace :loc do
  desc 'generate localizaed strings'
  task :gen do
    sh 'loc/setup.sh'
    ruby "./game-config/strings.json-gen.rb #{design_dir}"
    ruby "./game-config/sensitiveWords.json-gen.rb #{design_dir}"
    ruby "./game-config/chiefNames.json-gen.rb #{design_dir}"
  end

  # 分地区的活动
  desc 'Rake loc-related xls for the relevant events'
  task :event do
    EVENT_FILES.each do |e|
      gen = "./game-config/#{e}.json-gen.rb"
      xls = "#{design_dir}/Database/#{e}.xls"
      ruby "-C. -Iapp/data #{gen} #{xls}"
    end
  end

  LOCS.each do |loc|
    desc "copy loc files #{loc}"
    task loc do |t|
      copy_loc(t.name)
    end
  end
end

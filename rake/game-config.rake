# config.rake
#

directory 'temp'

$operation_scheme = 'default'
$operation_files = []


def set_config_folder(config_folder)
  ENV['JSON_CONFIG_FOLDER'] = config_folder
end


def set_operation_scheme(scheme)
  $operation_scheme = scheme
  ENV['JSON_PROCESS_CONFIG_FOLDER'] = "operation/#{scheme}-processed"
  ENV['JSON_CONFIG_FOLDER'] = "operation/#{scheme}"
  system("mkdir -p operation/#{scheme}/")
  system("mkdir -p operation/#{scheme}-processed/")
end

def merge_exec
  File.join(server_root, 'game-config', 'merge_jsons.rb')
end

# xls md5 file is now user based to avoid not building
# the xls when someone polutes it with the latest md5 but generating with an old .xls
def user_md5_xls
  build_env = ENV['BUILD_ENV']
  if build_env == 'k6' then
    puts "using k6-xls-md5.json"
    "game-config/k6-xls-md5.json"
  else
    "game-config/#{ENV['USER']}-xls-md5.json"
  end
end

def read_md5
  file = user_md5_xls
  build_env = ENV['BUILD_ENV']
  if build_env != 'k6'
    if File.exist?(file)
      return JSON.parse(IO.read(file))
    else
      return {}
    end
  else
    puts "k6 uses a merged md5 to ensure the correct config is build"
    md5 = {}
    if File.exist?(file)
      md5 = JSON.parse(IO.read(file))
    else
      md5 = {}
    end

    jenkins_md5 = JSON.parse(IO.read('game-config/jenkins-xls-md5.json'))
    md5.merge!(jenkins_md5) do |k, ov, nv|
      if ov != nv
        ov + nv
      else
        ov
      end
    end
    md5
  end
end

def write_md5(md5)
  file = user_md5_xls
  IO.write(file, JSON.pretty_generate(md5))
end

def merge(options)
  jsonFiles = options[:jsonFiles]
  folder = options[:folder]
  includes = options[:includes]
  client_only_config = options[:client_only_config]

  rm_f File.join(folder, 'config.dat')

  system "rm -rf #{folder}/*.db"
  rm_f File.join(folder, 'config.json')
  if includes && client_only_config
    puts includes
    ruby "#{merge_exec} merge #{jsonFiles.join(' ')} -f #{folder} -i #{includes.join(' ')} -e #{client_only_config.join(' ')}"
  elsif client_only_config
    puts client_only_config
    ruby "#{merge_exec} merge #{jsonFiles.join(' ')} -f #{folder} -e #{client_only_config.join(' ')}"
  else
    puts "nothing"
    ruby "#{merge_exec} merge #{jsonFiles.join(' ')} -f #{folder}"
  end
end

def zip(input, output)
  if File.exist?(input)
    json = IO.read(input)
    deflated = Zlib::Deflate.deflate json
    IO.write(output, deflated)
  end
end

def get_gen_name(basename)
  gen = "game-config/#{basename}.json-gen.rb"
  return gen if File.exist? gen

  gen = "game-config/#{basename}s.json-gen.rb"
  return gen if File.exist? gen

  gen = "game-config/#{basename}es.json-gen.rb"
  return gen if File.exist? gen
end

task :touch, :xls do |_t, args|
  system("rake game_config:touch[#{args[:xls]}]")
end


MERGE_EXCLUDE = [
  /config\.json/,
  /config_client\.json/,
  /mqs_tmp\.json/,
  /xls-md5\.json/,
  /gameDataStrings/,
  /cdkeys/,
  /animators_base/,
  /animators_special/,
  /hero_attrs/,
  /hero_display/
]

SERVER_ONLY = %w(
)

CLINET_ONLY_CONFIG = %w(
)

JSON_PROCESSED_FOLDER = 'game-config-processed'
JSON_FOLDER = 'game-config'

namespace :game_config do
  task cf: [:touch, :config]

  desc 'Remove the <file>.xls from the md5 list to force a build'
  task :touch, :xls do |_t, args|
    md5 = read_md5
    f = args[:xls]
    if f == 'all'
      md5.clear
    else
      md5.delete(f)
    end
    write_md5(md5)
  end

  def gen_configs(scheme_files = [])
    scheme = $operation_scheme

    output_folder = JSON_FOLDER
    output_processed_folder = JSON_PROCESSED_FOLDER


    if scheme == 'default'
      system("rm -f #{unity_root}/Assets/StreamingAssets/*.db")

    else
      output_processed_folder = "operation/#{scheme}-processed"
      output_folder = "operation/#{scheme}"
    end

    system('mkdir -p temp')
    system("mkdir -p #{JSON_PROCESSED_FOLDER}")

    system('rm -f temp/*')

    if scheme == 'default'
      system("cp -f #{unity_root}/Assets/StreamingAssets/*.json temp/") # copy ru jsons because we have write level2.json
    end

    system("cp -f #{output_folder}/*.json temp/")
    system("cp -f #{output_processed_folder}/*.json temp/")
    system("rm -f #{output_processed_folder}/*.db")
    fileList = FileList['temp/*.json']

    MERGE_EXCLUDE.each do |x|
      fileList = fileList.exclude(x)
    end

    # if !scheme_files.empty?
    #   fileList.delete_if do |file|
    #     basename = File.basename(file, '.json')
    #     !scheme_files.include?(basename)
    #   end
    # end



    merge(jsonFiles: fileList,
          folder: File.join(server_root, output_processed_folder))

    if scheme != 'default'
      origin = JSON.parse(IO.read("#{JSON_PROCESSED_FOLDER}/config.json"))
      scheme_config = JSON.parse(IO.read("#{output_processed_folder}/config.json"))
      scheme_config = origin.merge(scheme_config)
      scheme_config.delete('level2')
      # puts scheme_config.keys
      puts "writing server final config: #{output_folder}/config.json"
      IO.write("#{output_folder}/config.json", JSON.pretty_generate(scheme_config))
    else
      system("cp -f #{JSON_PROCESSED_FOLDER}/config.json #{JSON_FOLDER}/ 2> /dev/null")
    end

    if scheme != 'default'
      system("mkdir -p #{unity_root}/operation/#{scheme}/")
      client_scheme_folder = "#{unity_root}/operation/#{scheme}/"
      puts "deleting existing db files in #{client_scheme_folder}.."
      system("rm -fv #{client_scheme_folder}/*.db")
      out_files = FileList["#{output_processed_folder}/*.db"].exclude(/level2/)
      out_files.each do |file|
        system("cp -fv #{file} #{client_scheme_folder}")
      end
    else
      #gen_pipeline_config

      system("cp -f #{JSON_PROCESSED_FOLDER}/*.db #{unity_root}/Assets/StreamingAssets/")
      system("cp -f #{JSON_FOLDER}/strings.json #{unity_root}/Assets/StreamingAssets/")
    end
  end

  desc 'Generate config.json files'
  task :dat do
    gen_configs
  end

  def merge_physic_json
    scheme = $operation_scheme
    system('mkdir -p physic-entity')
    if scheme == 'default'
      system("cp -f #{unity_root}/Assets/Editor/PhysicEditor/PhysicData/*.json physic-entity/")
    end
    fileList = FileList['physic-entity/*.json']

    MERGE_EXCLUDE.each do |x|
      fileList = fileList.exclude(x)
    end

    ruby "#{merge_exec} merge_jsons #{fileList.join(' ')} -f #{JSON_FOLDER}"

  end

  desc 'merge PhysicEntity files'
  task :mpj do
    merge_physic_json
  end

  def gen_pipeline_config
    o = {}
    config = JSON.parse(IO.read("#{JSON_FOLDER}/config.json"))

    o['common'] = config['common']
    o['animators_base'] = JSON.parse(IO.read("#{JSON_FOLDER}/animators_base.json"))
    o['animators_special'] = JSON.parse(IO.read("#{JSON_FOLDER}/animators_special.json"))
    o['animators_ms'] = JSON.parse(IO.read("#{JSON_PROCESSED_FOLDER}/animators_ms.json"))
    IO.write("#{unity_root}/Assets/StreamingAssets/config.json", JSON.pretty_generate(o))
  end

  task :gen_pipeline_config do
    gen_pipeline_config
  end

  def post_process_json
    post_files = FileList['game-config/*.json-post.rb']

    post_files.each do |x|
      post_gen = x
      if post_gen 
        puts "post process json file:#{post_gen}"
        ruby "-C. -Iapp/data -Ilib/boot #{post_gen}"
      end
    end
  end

  def process_graph
    process = 'game-config/graphdata.json-process.rb'
    ruby "-C. -Iapp/data -Ilib/boot #{process}"
  end

  def scan_assets
    unity_exec = ENV['UNITY'] || '/Applications/Unity/Unity.app/Contents/MacOS/Unity'
    system("#{unity_exec} -projectPath #{ENV['KFC']} -buildTarget ios -batchmode -quit -executeMethod ScanHelper.Scan #{ENV['KFS']}/game-config/ -logFile ")
  end

  desc 'Scan scene and characters and anim data'
  task :scan do
    scan_assets
  end

  def should_pull_design?
    ENV['USER'] != 'jenkins'
  end

  def pull_design
    Dir.chdir(design_dir) do
      puts "updating #{design_dir}"
      system('git pull')
    end
  end

  def pull_bundle
    Dir.chdir(art_dir) do
      puts "updating #{art_dir}"
      system('cd ./AssetsBundles && git pull')
    end
  end

  def build_xls(database, gen_md5 = true)
    puts database
    xlsFiles = FileList["#{design_dir}/#{database}/*.xlsx"]
    if $operation_scheme != 'default'
      config_output_folder = "operation/#{$operation_scheme}"
      set_config_folder(config_output_folder)
    else
      set_config_folder('game-config')
    end

    old = read_md5

    md5 = {}

    xlsFiles.each do |x|
      file = File.basename(x, '.xlsx')
      gen_file = get_gen_name(file)
      if gen_file
        md5[file] = Digest::MD5.hexdigest(File.read(x) + File.read(gen_file))
      end
    end

    md5.each do |k, v|
      basename = File.basename(k)
      xls = "#{k}.xlsx"
      gen = get_gen_name(basename)
      next unless v != old[k]
      if k =~ /(strings|sensitiveWords|chiefNames)/
        puts "gen json file:#{gen}"
        ruby "-C. -Iapp/data -Ilib/boot #{gen} #{design_dir}"
      elsif gen && File.exist?(gen)
        puts "gen json file:#{gen}"
        ruby "-C. -Iapp/data -Ilib/boot #{gen} #{design_dir}/#{database}/#{xls}"
      else
        puts "error: gen-script '#{gen}' doesn't exists for '#{basename}' xls sheet"
      end
    end

    if gen_md5
      write_md5(md5)
    end
  end

  desc 'Build xls files from database'
  task :xls do |_t|
    # pull_design if should_pull_design?
    build_xls('database')
    post_process_json
  end

  task :graph do
    process_graph
  end

  def post_process(file_name)
    post_files = FileList["game-config/#{file_name}.json-post.rb", "game-config/#{file_name}s.json-post.rb", "game-config/#{file_name}es.json-post.rb"]
    post_files.each do |x|
      post_gen = x
      if File.exist?(post_gen)
        ruby "-C. -Iapp/data -Ilib/boot #{post_gen}"
      end
    end
  end

  def ck_process(file_name)
      ck = "game-config/#{file_name}.json-ck.rb"
      unless File.exist? ck
        file_name = "#{file_name}s"
        ck = "game-config/#{file_name}.json-ck.rb"
        return unless File.exist? ck
      end
      puts "==> Check json file:#{ck}"
      begin
        ruby "-C. -Iapp/data -Ilib/boot #{ck} game-config/", verbose: false
      rescue => er
        exec('exit 1')
      end
  end

  task :ai do |_t, args|
    post_process('ai')
  end

  task :xlsf, [:file_name] do |_t, args|
    puts("check args:#{args}")
    file_name = args[:file_name]
    xlsFile = "#{design_dir}/database/#{file_name}.xls"
    gen = get_gen_name(file_name)
    post_files = "game-config/#{file_name}.json-post.rb"
    if file_name =~ /(strings|sensitiveWords|chiefNames)/
      puts "gen json file:#{gen}"
      ruby "-C. -Iapp/data -Ilib/boot #{gen} #{design_dir}"
    elsif gen && File.exist?(gen)
      puts "gen json file:#{gen}"
      ruby "-C. -Iapp/data -Ilib/boot #{gen} #{xlsFile}"

      post_process(file_name)
      ck_process(file_name)
      if  %w(item equip garments).include?(file_name)
        post_process('stall')
      end
    else
      puts "error: gen-script '#{gen}' doesn't exists for '#{file_name}' xls sheet"
    end
  end

  desc 'Build xls files from database_test'
  task :xls_test do |_t|
    pull_design
    build_xls('database_test')
    post_process_json
  end

  task :string do
    ruby "-C. -Iapp/data -Ilib/boot game-config/strings.json-gen.rb #{design_dir}"
  end

  desc "post process one file"
  task :post do |t, args|
    a = args.extras
    args.extras.each do |cfg|
      post_process(cfg)
    end
  end

  desc 'Check json files'
  task :check do |_t|
    json_files = FileList['game-config/*.json']
    json_files.each do |x|
      name = File.basename(x)
      ck = "game-config/#{name}-ck.rb"
      next unless File.exist? ck
      puts "==> Check json file:#{ck}"
      begin
        ruby "-C. -Iapp/data -Ilib/boot #{ck} game-config/", verbose: false
      rescue => er
        exec('exit 1')
      end
    end
  end

end

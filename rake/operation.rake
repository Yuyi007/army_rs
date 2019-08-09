namespace :operation do
  SCHEMES = [
    'ioscb',
  ]

  def gen_scheme_config(scheme)
    database = "database_operation_#{scheme}"
    if !File.exist?("#{design_dir}/#{database}")
      puts "#{database} folder not found, skipping #{scheme}"
      return
    end

    output_folder = "operation/#{scheme}/"
    output_processed_folder = "operation/#{scheme}-processed/"

    system("mkdir -p #{output_folder}")
    system("mkdir -p #{output_processed_folder}")

    system("rm -rf #{output_folder}/*.json")
    system("rm -rf #{output_processed_folder}/*.json")

    set_operation_scheme(scheme)

    build_xls(database, false)


    out_files = FileList["#{output_folder}/*.json"]
    out_files = out_files.map {|x| File.basename(x.to_s, '.json')}
    out_files.delete('config')
    out_files.delete('level2')

    ENV['SCHEME_CONFIG_FILES'] = JSON.generate(out_files.to_a)
    ENV['KFC_CONFIG_SCEHEME'] = scheme
    post_process_json

    gen_configs(out_files)
  end

  # desc 'generate config for operaion schemes '
  # task :config do |t, args|
  #   schemes = args.extras
  #   schemes.each do |scheme|
  #     gen_scheme_config(scheme)
  #   end
  # end

  desc 'gen game config for all operation schemes'
  task :all do |t|
    SCHEMES.each do |scheme|
      gen_scheme_config(scheme)
    end
  end

  SCHEMES.each do |scheme|
    database = "database_operation_#{scheme}"
    if !File.exist?("#{design_dir}/#{database}")
      # puts "#{database} folder not found, skipping #{scheme}"
      next
    end

    desc "generate game config for #{scheme}"
    task(scheme) do |t|
      gen_scheme_config(scheme)
    end
  end

end
#!/usr/bin/env ruby
# change camel case names to underscore names
# of ruby files recursively in a directory

# for the love of underscore names

# TODO fix method names?

class String
  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
end

def process_file(file)
  dir_name = File.dirname(file)
  ext_name = File.extname(file)
  base_name = File.basename(file, ext_name)
  underscore_name = base_name.underscore
  if underscore_name != base_name
    file = "#{dir_name}/#{underscore_name}#{ext_name}"
    puts "rename #{dir_name}/#{base_name}#{ext_name}"
    File.rename("#{dir_name}/#{base_name}#{ext_name}", file)
  end

  puts "modifying content of #{file}"
  File.open("#{file}.tmp", 'w+') do |f|
    File.open(file).each do |line|
      if line =~ /^require\s+[\'\"][\w]+(\/[\w\d]+)*[\'\"]/
        f.puts line.underscore
      else
        f.puts line
      end
    end
  end
  File.rename("#{file}.tmp", file)
end

#####

src_dir = ARGV[0]

if File.directory?(src_dir)
  Dir.glob("#{src_dir}/**/*.rb").each do |file|
    process_file(file)
  end
else
  process_file(src_dir)
end
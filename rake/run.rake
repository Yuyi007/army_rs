
def combat_config
  "config/config.#{USER}.combat"
end

def loadtest_config
  "config/config.#{USER}.loadtest"
end

def verify_config
  "config/config.#{USER}.verify"
end

def loadtest2_config
  "config/config.#{USER}.loadtest2"
end

def loadtest3_config
  "config/config.#{USER}.loadtest3"
end

def data_args(port)
  "--port #{port} --serverid data#{port}@local"
end

def checker_args(index)
  "--serverid checker#{index}@local --serverindex #{index}"
end

namespace :run do
  task :test => :spec
  task :test_app => :spec_app

  desc "Run all unit tests"
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = ["-c", "-f p", "-r ./spec/boot/spec_helper.rb"]
    t.pattern = 'spec/**/*_spec.rb'
  end

  desc "Run all unit tests for app"
  RSpec::Core::RakeTask.new(:spec_app) do |t|
    t.pattern = 'spec/app/*_spec.rb'
  end

  desc "Run all unit tests for single spec file"
  RSpec::Core::RakeTask.new(:spec_one, :file) do |t, task_args|
    puts("------ task_args:#{task_args}")
    t.pattern = "spec/app/#{task_args[:file]}_spec.rb"
  end


  desc "Run combat server"
  task :combat do
    system %Q/ps -ef|grep combat|grep -v grep|awk '{print "kill -9 "$2}'|sh/
    system "cd lib/skynet && ./skynet ../../#{combat_config}"
  end

  desc "Run loadtest server"
  task :loadtest do
    system %Q/ps -ef|grep loadtest|grep -v grep|awk '{print "kill -9 "$2}'|sh/
    system "cd lib/skynet && ./skynet ../../#{loadtest_config}"
  end

  desc "Run loadtest server"
  task :verify do
    system %Q/ps -ef|grep verify|grep -v grep|awk '{print "kill -9 "$2}'|sh/
    system "cd lib/skynet && ./skynet ../../#{verify_config}"
  end

  desc "Run loadtest server"
  task :loadtest2 do
    system "cd lib/skynet && ./skynet ../../#{loadtest2_config}"
  end

  desc "Run loadtest server"
  task :loadtest3 do
    system "cd lib/skynet && ./skynet ../../#{loadtest3_config}"
  end

  desc "Run data server"
  task :data do
    system %Q/ps -ef|grep init.rb|grep -v grep|awk '{print "kill -9 "$2}'|sh/
    ruby "-C. -Ilib/boot -Iapp/data app/data/launchers/init.rb #{task_args} #{data_args(5081)}"
  end

  desc "Run data server 2"
  task :data2 => :'deps:bundle' do
    ruby "-C. -Ilib/boot -Iapp/data app/data/launchers/init.rb #{task_args} #{data_args(5082)}"
  end

  desc "Run data server 3"
  task :data3 => :'deps:bundle' do
    ruby "-C. -Ilib/boot -Iapp/data app/data/launchers/init.rb #{task_args} #{data_args(5083)}"
  end

  desc "Run data server 4"
  task :data4 => :'deps:bundle' do
    ruby "-C. -Ilib/boot -Iapp/data app/data/launchers/init.rb #{task_args} #{data_args(5084)}"
  end

  desc "Run checker"
  task :checker do
    ruby "-C. -Ilib/boot -Iapp/data app/data/launchers/checker.rb #{task_args} #{checker_args(0)}"
  end

  desc "Run checker1"
  task :checker1 do
    ruby "-C. -Ilib/boot -Iapp/data app/data/launchers/checker.rb #{task_args} #{checker_args(1)}"
  end

  desc "Run checker2"
  task :checker2 do
    ruby "-C. -Ilib/boot -Iapp/data app/data/launchers/checker.rb #{task_args} #{checker_args(2)}"
  end

  desc "Run gm server"
  task :gm do
    system("cd app/gm && bundle install --local &> /dev/null && \
      BUNDLE_GEMFILE=../../Gemfile bundle exec rails s -p 3008 #{task_args}")
  end

  desc "Run payment server"
  task :pay do
    system("cd app/payment && bundle install --local &> /dev/null && \
      BUNDLE_GEMFILE=../../Gemfile bundle exec rails s -p 3009 #{task_args}")
  end

  desc "Run stat server"
  task :stats do
    system("cd app/stat && bundle install --local &> /dev/null && \
      exec rails s -p 3010 #{task_args}")
  end

  desc "Run redis cluster locally"
  task :cluster do
    system("cd redis-cluster && ./stop-all.sh && ./start-all.sh")
  end

end


def luajit_dir
  '../luajit'
end

def remote_luajit_dir
  'jenkins@jenkins.firevale.com:/home/jenkins/luajit'
end

def dest_dir
  './deps/erlang_lua'
end

namespace :slua do
  desc 'copy all needed files'
  task copy: [:copy_libs, :copy_headers]

  desc 'copy lib files from luajit project'
  task :copy_libs do
    system "cp #{luajit_dir}/luajit/prebuilt/mac/libluajit.a #{dest_dir}/prebuilt/mac/"
    system "cp #{luajit_dir}/luaext/prebuilt/mac/libluaext.a #{dest_dir}/prebuilt/mac/"

    system "scp #{remote_luajit_dir}/luajit/prebuilt/linux/libluajit.a #{dest_dir}/prebuilt/linux/"
    system "scp #{remote_luajit_dir}/luaext/prebuilt/linux/libluaext.a #{dest_dir}/prebuilt/linux/"
  end

  desc 'copy header files from luajit project'
  task :copy_headers do
    system "cp #{luajit_dir}/luaext/luaext.h #{dest_dir}/include/"
    system "cp #{luajit_dir}/luajit/include/*.h #{dest_dir}/include/"
  end
end

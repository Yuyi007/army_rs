# coding: utf-8

require 'fileutils'
require 'yaml'
require 'json'
require 'digest'
require 'zlib'

def unity_root
  ENV['LAU']
end

def client_file_root
  "#{unity_root}/Assets"
end

def server_root
  ENV['LAS'] || File.expand_path(File.dirname(__FILE__))
end

def design_dir
  ENV['DESIGN'] || File.expand_path(server_root + '/../design')
end

def art_dir
  ENV['LART'] || File.expand_path(server_root + '/../art')
end


def ulimit_nofile
  if RUBY_PLATFORM =~ /darwin/
    if File.exist?('/Library/LaunchDaemons/limit.maxfiles.plist')
      # assuming you're on Mavericks, Yosemite or El Capitan
      # see http://unix.stackexchange.com/questions/108174/how-to-persist-ulimit-settings-in-osx-mavericks
      ulimit = 40_000
    else
      ulimit = 40_000
    end
  elsif RUBY_PLATFORM =~ /linux/
    ulimit = 40_000 # assuming you're in jenkins user
  else
    fail "Are you sure you want to develop on #{RUBY_PLATFORM}?"
  end

  ulimit
end

USER = ENV['USER']

ERL_OPTIONS_CONTENT = "+P 262144 +Q 655360 +t 1048576 +hms 200 +K true \
  +sbwt none +sub true +C multi_time_warp -sbt db -env ERL_MAX_ETS_TABLES 3500 \
  +MEas bf +MHas bf +MBas aobf +MBsbct 128 +MBsmbcs 128 +MBlmbcs 128"
ERL_OPTIONS = "ELIXIR_ERL_OPTIONS='#{ERL_OPTIONS_CONTENT}' "

Rake::FileUtilsExt.verbose(false)

MD5_XLS = 'game-config/xls-md5.json'

LOC_FILES = %w(

)

EVENT_FILES = %w(

)

LOCS = %w(
)

LOC_DEP = {
}

if ENV['DESIGN']
  DESIGNDIR = ENV['DESIGN'].strip
else
  DESIGNDIR = '../design'
end



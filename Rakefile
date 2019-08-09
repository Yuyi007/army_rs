#!/usr/bin/env rake
# coding: utf-8

require 'fileutils'
require 'yaml'
require "rspec/core/rake_task"
require 'pathname'
require 'digest'
require 'json'

def task_args; ARGV.drop(1).join(' '); end

import 'rake/common.rake' if File.exists?('rake/common.rake')
Dir.glob('rake/*.rake').each { |file| import file }
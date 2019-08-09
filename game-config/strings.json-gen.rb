#!/usr/bin/env ruby
# coding:utf-8

require 'roo'
require 'json'
require 'ostruct'
require 'iconv'
require 'tradsim'
require 'spreadsheet'
require 'boot'
require_relative 'table_help'

strings = {}

designdir = ARGV[0] or "#{ENV['RS']}/../design"
# b = Spreadsheet.open("#{designdir}/Database/strings.xlsx")

s = Roo::Excelx.new("#{designdir}/database/strings.xlsx")
s.default_sheet = s.sheets.first
1.upto(s.last_row) do |l|
  record = s.row(l)
  next if record[0].to_s.strip.empty?
  key = record[0].to_s.strip
  key.gsub!(/\s/, '')
  key.delete!(' ')
  v = record[1].to_s.strip
  v.gsub!('\\n', "\n")
  strings[key] = v
end

save_json('strings', strings)

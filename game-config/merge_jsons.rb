#!/usr/bin/env ruby

# merge several json files

require 'optparse'
require 'rubygems'
require 'sqlite3'
require 'json'
require 'zlib'
require 'openssl'
require 'digest'
require 'msgpack'
require 'thor'
require_relative '../bin/encrypt'

def encrypt data
  encrypt_rc4 data
end

class Merge < Thor

  include Thor::Actions

  def self.exit_on_failure?
    true
  end

  desc 'merge <json>', 'merge json files'
  class_option :folder, :required => true, :aliases => '-f'
  class_option :includes, :aliases => '-i', :default => nil, :type => :array
  class_option :exclude_config_json, :aliases => '-e', :default => [], :type => :array

  def merge(*argv)
    config = {}
    strings = {}
    level2_cfg = {}

    argv.each do |name|
      file = File.open(name, "r:UTF-8")
      raw = file.read()
      json = JSON.parse(raw)
      k = File.basename(name, '.json')
      if config.has_key?(k)
        puts "When parsing " + name + ": key '" + k + "' already exists! exiting"
        raise Thor::Error, "When parsing " + name + ": key '" + k + "' already exists! exiting"
      end
      if k != 'strings'
        config[k] = json
      end


      if gen_db(k, json, raw) then
        level2_cfg[k] = {}
        json.each do |name2, _cfg2|
          level2_cfg[k][name2] = true
        end
      end
    end

    gen_json(config, :folder => folder, :name => 'config')

    gen_json(level2_cfg, {:folder => folder, :name => 'level2'}, false)
    gen_db('level2', level2_cfg, JSON.generate(level2_cfg))
  end


  desc 'merge <json>', 'merge and modify json files'
  class_option :folder, :required => true, :aliases => '-f'

  def merge_jsons(*argv)
    config={}
    argv.each do |name|
      file = File.open(name, "r:UTF-8")
      raw = file.read()
      json = JSON.parse(raw)
      k = File.basename(name, '.json')
      if config.has_key?(k)
        puts "When parsing " + name + ": key '" + k + "' already exists! exiting"
        raise Thor::Error, "When parsing " + name + ": key '" + k + "' already exists! exiting"
      end
      config[k] =json;

      json["cubeData"].each do |x|
        puts x["posX"]= (x["posX"]*0.06).round(4)
      end

      gen_json(config,:folder=> folder,:name=>"physic_entity")

    end
  end

  no_tasks do

    def fixConfig(config)
    end

    def method_missing(name, *argv)
      options[name.to_sym]
    end

    def deep_copy(hash)
      raw = MessagePack.pack(hash)
      hash = MessagePack.unpack(raw)
    end

    def encode_value obj
      if obj.is_a? Hash or obj.is_a? Array
        # json = JSON.generate(obj)
        json = MessagePack.pack(obj)
        encoding = (if json.length > 128 then 5 else 4 end)
        if encoding == 5 then
          deflated = Zlib::Deflate.deflate json
          raw = encrypt deflated
        else
          raw = encrypt json
        end
        return raw, encoding
      elsif obj.is_a? String
        return obj, 3
      elsif obj.is_a? Numeric
        return obj.to_s, 2
      elsif !!obj == obj
        return obj.to_s, 1
      elsif obj == nil
        return obj, 0
      else
        raise "invalid type of obj #{obj.inspect}"
      end
    end

    def gen_separete_files(config)
      config.each do |file, cfg|
        gen(cfg, :folder => folder, :name => file)
      end
    end

    def gen(hash, o = nil)
      json = JSON.generate(hash)
      deflated = Zlib::Deflate.deflate json
      raw = encrypt deflated
      if o and o[:folder] and o[:name] then
        folder, name = o[:folder], o[:name]
        IO.write(File.join(folder, name + ".dat"), raw)
      end
    end

    def gen_json(hash, o = nil, exclude = true)
      hash1 =  deep_copy(hash)
      options.exclude_config_json.each do |ex|
        hash1.delete(ex)
      end if exclude 

      hash1.each do |k, v|
        if k == 'drops'
          v.each do |tid, o|
            o.delete('displays')
          end
        end
      end

      json = JSON.pretty_generate(hash1)
      if o and o[:folder] and o[:name] then
        folder, name = o[:folder], o[:name]
        IO.write(File.join(folder, name + ".json"), json)
      end
    end

    def gen_db(name, cfg, raw)
      return if options.includes && !options.includes.include?(name)

      maxlength = get_max_length(name)
      level2 = gen_level2_db?(name, cfg, raw)

      if level2 then
        cfg.each do |name2, cfg2|
          gen_db_file("#{name}.#{name2}", cfg2, maxlength, level2)
        end
      else
        gen_db_file(name, cfg, maxlength, level2)
      end

      level2
    end

    def get_max_length(name)
      return 256
    end

    def gen_level2_db?(name, cfg, raw)
      return (
        (name == 'city') or
        (name == 'city_triggers') or
        (cfg.is_a? Hash and cfg.length < 8 and raw.length > 8196 and name != 'level2')
        )
    end

    def gen_db_file(dbname, cfg, maxlength, level2)
      fname = "#{dbname}.db"
      filename = File.join(folder, fname)
      if level2 then
        puts "creating #{filename}... (level2)"
      else
        puts "creating #{filename}..."
      end
      File.delete(filename) if File.exists? filename
      db = SQLite3::Database.new filename

      db.execute "PRAGMA synchronous = OFF"
      db.execute "PRAGMA journal_mode = MEMORY"
      db.execute "PRAGMA count_changes = OFF"
      db.execute <<-SQL
        CREATE TABLE config(
          name varchar(#{maxlength}),
          idx int,
          value text,
          encoding int
        );
      SQL

      # put it into a transaction so insertion would be faster
      db.transaction do
        db.prepare "INSERT INTO config VALUES (?, ?, ?, ?)" do |stmt|
          if cfg.is_a? Hash
            cfg.each do |id, table|
              raise "[#{fname}] id length shouldn't be larger than #{maxlength} id = #{id}" if id.length > maxlength
              raw, encoding = encode_value(table)
              stmt.bind_params id, nil, raw, encoding
              stmt.execute!
              stmt.reset!
            end
          elsif cfg.is_a? Array
            cfg.each_with_index do |table, i|
              raw, encoding = encode_value(table)
              stmt.bind_params nil, i, raw, encoding
              stmt.execute!
              stmt.reset!
            end
          end
        end
      end

      # create index after insert so insertion would be faster
      db.execute "CREATE UNIQUE INDEX index_name ON config(name);"
      db.execute "CREATE UNIQUE INDEX index_idx ON config(idx);"
    end

  end
end

Merge.start(ARGV)


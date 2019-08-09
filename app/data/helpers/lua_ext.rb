# LuaExt.rb
paths = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'client', 'scripts', 'rlua'))
case RbConfig::CONFIG['host_os']
when /darwin/
  paths += '/liblua.5.1.dylib'
when /linux/
  paths += '/liblua.so.5.1.5'
else
  raise "rufus-lua doesn't support your platform!"
end

ENV['LUA_LIB'] = paths

require 'rufus-lua'
require 'oj'

module Rufus::Lua

  module Lib
    paths = ENV['LUA_LIB']

    begin
      ffi_lib_flags(:lazy, :global)
      ffi_lib(paths)
    rescue LoadError => le
      fail RuntimeError.new(
        "Didn't find the Lua dynamic library on your system. " +
        "Set LUA_LIB in your environment if have that library or " +
        "go to https://github.com/jmettraux/rufus-lua to learn how to " +
        "get it. (paths: #{paths.inspect})"
      )
    end

    attach_function :luaL_loadfile, [ :pointer, :string ], :int
    attach_function :luaL_loadstring, [ :pointer, :string ], :int
    attach_function :lua_close, [ :pointer ], :void

    attach_function :luaL_openlibs, [ :pointer ], :void

    attach_function :lua_call, [ :pointer, :int, :int ], :void
    %w[ base package string table math io os debug ].each do |libname|
      attach_function "luaopen_#{libname}", [ :pointer ], :void
    end

    attach_function :lua_pcall, [ :pointer, :int, :int, :int ], :int
    #attach_function :lua_resume, [ :pointer, :int ], :int

    attach_function :lua_toboolean, [ :pointer, :int ], :int
    attach_function :lua_tonumber, [ :pointer, :int ], :double
    attach_function :lua_tolstring, [ :pointer, :int, :pointer ], :pointer

    attach_function :lua_type, [ :pointer, :int ], :int
    attach_function :lua_typename, [ :pointer, :int ], :string

    attach_function :lua_gettop, [ :pointer ], :int
    attach_function :lua_settop, [ :pointer, :int ], :void

    attach_function :lua_objlen, [ :pointer, :int ], :int
    attach_function :lua_getfield, [ :pointer, :int, :string ], :pointer
    attach_function :lua_gettable, [ :pointer, :int ], :void

    attach_function :lua_createtable, [ :pointer, :int, :int ], :void
    #attach_function :lua_newtable, [ :pointer ], :void
    attach_function :lua_settable, [ :pointer, :int ], :void

    attach_function :lua_next, [ :pointer, :int ], :int

    attach_function :lua_pushnil, [ :pointer ], :pointer
    attach_function :lua_pushboolean, [ :pointer, :int ], :pointer
    attach_function :lua_pushinteger, [ :pointer, :int ], :pointer
    attach_function :lua_pushnumber, [ :pointer, :double ], :pointer
    attach_function :lua_pushstring, [ :pointer, :string ], :pointer
    attach_function :lua_pushlstring, [ :pointer, :pointer, :int ], :pointer

    attach_function :lua_remove, [ :pointer, :int ], :void
      # removes the value at the given stack index, shifting down all elts above

    #attach_function :lua_pushvalue, [ :pointer, :int ], :void
      # pushes a copy of the value at the given index to the top of the stack
    #attach_function :lua_insert, [ :pointer, :int ], :void
      # moves the top elt to the given index, shifting up all elts above
    #attach_function :lua_replace, [ :pointer, :int ], :void
      # pops the top elt and override the elt at given index with it

    attach_function :lua_rawgeti, [ :pointer, :int, :int ], :void

    attach_function :luaL_newstate, [], :pointer
    attach_function :luaL_loadbuffer, [ :pointer, :string, :int, :string ], :int
    attach_function :luaL_ref, [ :pointer, :int ], :int
    attach_function :luaL_unref, [ :pointer, :int, :int ], :void

    attach_function :lua_gc, [ :pointer, :int, :int ], :int

    callback :cfunction, [ :pointer ], :int
    attach_function :lua_pushcclosure, [ :pointer, :cfunction, :int ], :void
    attach_function :lua_setfield, [ :pointer, :int, :string ], :void
  end

  class State
    def dofile(filename)
      bottom = stack_top
      result = Lib.luaL_loadfile(@pointer, filename);

      fail_if_error('dofile', result, filename, nil, nil)
      pcall(bottom, 0, nil, filename, nil)
    end

    def eval(str)
      self.dostring(str)
    end

    def dostring(str)
      bottom = stack_top
      result = Lib.luaL_loadstring(@pointer, str);

      fail_if_error('dostring', result, nil, nil, nil)
      pcall(bottom, 0, nil, nil, nil)
    end

    def []=(k, v)
      if v and (v.is_a?(::Array) or v.is_a?(::Hash) or v.respond_to?(:to_json))
        self.dostring("#{k} = cjson.decode(#{Rufus::Lua.to_lua_s(v).inspect})")
      else
        self.dostring("#{k} = #{Rufus::Lua.to_lua_s(v)}")
      end
    end

  end

end

module Rufus::Lua

  def self.to_lua_s(o)

    case o
    when String then o.inspect
    when Fixnum then o.to_s
    when Float then o.to_s
    when TrueClass then o.to_s
    when FalseClass then o.to_s
    when NilClass then 'nil'

    when Hash then to_lua_table_s(o)
    when Array then to_lua_table_s(o)
    else
      if o.respond_to?(:to_json) then
        o.to_json
      else
        raise ArgumentError.new(
          "don't how to turning into a Lua string representation "+
          "Ruby instances of class '#{o.class}'")
      end
    end
  end

  # Turns a Ruby Array or Hash instance into a Lua parseable string
  # representation.
  #
  def self.to_lua_table_s(o)
    s = Oj.dump(o, :mode => :compat)
    s
  end
end

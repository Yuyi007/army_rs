require 'ftools'
require 'json'
require 'ostruct'

DESIGN = ENV["KOF_DESIGN"]
KFC = ENV["KFC"]
KFS = ENV["KFS"]

namespace :ai do
  def parseAgent(dir_agent, dir_attr, dir_method, methods, inc)
    arr = IO.readlines(dir_agent)
    mode = "w"
    mode = "a" if inc
    fattr = open(dir_attr,mode)
    fmethod = open(dir_method,mode)

    readAttr = false
    readMethod = false
    readDoc = false
    start = 0
    curmethod = {}
    arr.each do |v|
      readAttr = true if v.index("--interface of attributes")
      readAttr = false if v.index("--end attributes")

      readMethod = true if v.index("--interface of agent")
      readMethod = false if v.index("--end method")

      if ((readAttr || readMethod ) && v.index("--[[") )
        fattr.puts("\n") if readAttr
        fmethod.puts("\n") if readMethod
        readDoc = true
      end

      if ((readAttr || readMethod ) && v.index("]]") )
        start = 0
        readDoc = false
      end

      if readDoc
        fattr.puts(v) if readAttr && start > 0

        if readMethod && start > 0
          fmethod.puts(v)

          if v.include?("方法:")
            s = v.index("方法:")
            name = v[s+3...v.length]
            name = name.delete(' ')
            puts(">>>>name:#{name}")
            os = {}
            os["name"] = name
            curmethod = os
            methods << os
          end

          if v.include?("别名:")
            s = v.index("别名:")
            displayname = v[s+3...v.length]
            displayname = displayname.delete(' ')
            curmethod["displayname"] = displayname
          end

          1.upto(9) do |i|
            if v.include?("arg#{i}")
              s = v.index("[") + 1
              e = v.index("]")
              a = v[s,e-s]
              a = a.delete(' ')
              curmethod["arg#{i}"] = a
            end
          end
        end

        start = start + 1
      end
    end

    fattr.close
    fmethod.close
  end

  desc "Run generate ai agent interface of access attribute"
  task :gen_doc do
    methods = []
    dir_agent = "client/scripts/game/fight3d/ai/AIAgent.lua"
    dir_attr = "#{DESIGN}/01技术相关/AI/Enemy支持的属性.txt"
    dir_method = "#{DESIGN}/01技术相关/AI/Enemy支持的方法.txt"
    dirconfig = "#{KFC}/Assets/Editor/BTEditor/Assets/methodcfg_enemy.json"
    parseAgent(dir_agent, dir_attr, dir_method, methods, false)
    dir_agent = "client/scripts/game/fight3d/ai/AIEnemyAgent.lua"
    parseAgent(dir_agent, dir_attr, dir_method, methods, true)

    json = JSON.pretty_generate(methods).to_s.strip
    json = json.gsub('\n','')
    File.open(dirconfig,"w") do |f|
      f.write(json)
    end

    methods = []
    dir_agent = "client/scripts/game/fight3d/ai/AIAgent.lua"
    dir_attr = "#{DESIGN}/01技术相关/AI/Player支持的属性.txt"
    dir_method = "#{DESIGN}/01技术相关/AI/Player支持的方法.txt"
    dirconfig = "#{KFC}/Assets/Editor/BTEditor/Assets/methodcfg_player.json"
    parseAgent(dir_agent, dir_attr, dir_method, methods, false)
    dir_agent = "client/scripts/game/fight3d/ai/AIPlayerAgent.lua"
    parseAgent(dir_agent, dir_attr, dir_method, methods, true)

    json = JSON.pretty_generate(methods).to_s.strip
    json = json.gsub('\n','')
    File.open(dirconfig,"w") do |f|
      f.write(json)
    end

    json = JSON.pretty_generate(methods).to_s.strip
    json = json.gsub('\n','')
    File.open(dirconfig,"w") do |f|
      f.write(json)
    end
  end
end

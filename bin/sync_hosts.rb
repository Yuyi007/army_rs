#!/usr/bin/env ruby
#
# Sync hosts from deployment description files to local hosts file and puppet
#
# Usage:
# sync_hosts.rb rs_ad.rb rs_tf.rb
#

require 'fileutils'

DEF_FILES = ARGV
HOSTS_FILE = '/etc/hosts'
HOSTS_BACKUP = "#{ENV['HOME']}/hosts.backup"
HOSTS_NEW = "#{ENV['HOME']}/hosts.new"
PUPPET_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'puppet'))
NAGIOS_DIR = File.expand_path(File.join(PUPPET_DIR, 'modules', 'cocs', 'files', 'nagios', 'conf.d'))

class Parser

  def parse(files)
    hosts = {}
    files.each do |file|
      puts "parsing #{file}..."
      env = File.basename(file, '.rb')
      File.open(file).each do |line|
        # match = line.match(/(^\w+[\w\d]*):?\s+(\d+\.\d+\.\d+\.\d+).*\s+/i)
        match = line.match(/^\s*server\s*['"](\d+\.\d+\.\d+\.\d+)['"].*ip:\s*['"](\d+\.\d+\.\d+\.\d+)['"].*env:\s*:(\w+)/i)
        if match and match.captures
          # host, ip = match.captures
          ext_ip, ip, host = match.captures
          procs, checkers = 0, 0
          match0 = line.match(/:gate/)
          match1 = line.match(/.+procs:\s*(\d+)/)
          match2 = line.match(/.+checkers:\s*(\d+)/)
          gate = true if match0
          procs = match1.captures[0] if match1
          checkers = match2.captures[0] if match2
          mem = 64
          puts "found host=#{host} ip=#{ip} ext_ip=#{ext_ip} mem=#{mem} gate=#{gate} procs=#{procs} checkers=#{checkers}"
          hosts[host] = {
            'ip' => ip,
            'ext_ip' => ext_ip,
            'env' => env,
            'gate' => gate,
            'procs' => procs.to_i,
            'checkers' => checkers.to_i,
            'mem' => mem,
          }
        end
      end
    end
    return hosts
  end

end

class Modifier

  def save_env_yaml(hosts)
    hosts.each do |host, info|
      host_alias = 'vm' + info['ip'].gsub('.', '-')
      env_file = PUPPET_DIR + '/hieradata/' + info['env'] + '.yaml'
      if File.readlines(env_file).grep(/#{host}:/).length == 0
        puts "adding #{host} to #{env_file}..."
        system(%Q{
cat >> #{env_file} <<ENDCAT
  #{host}:
    ip: #{info['ip']}
    host_aliases:
      - #{host_alias}
ENDCAT})
      end

      host_file = PUPPET_DIR + '/hieradata/' + info['env'] + '/' + "#{host}.yaml"
      if not (File.exist?(host_file) and File.size?(host_file))
        puts "adding host file #{host_file}}..."
        system(%Q{
cat > #{host_file} <<ENDCAT
# #{host}.yaml
classes:
  - 'rs::elasticsearch'
  - 'rs::god'
  - 'rs::elixir'
ENDCAT})
      end
    end
  end

  def save_nagios_hosts(hosts)
    hosts.each do |host, info|
      nagios_file = NAGIOS_DIR + '/hosts.cfg.' + info['env']
      FileUtils.touch(nagios_file)
      st = 0
      found = false
      lines = []
      File.open(nagios_file).each do |line|
        if line.match(/host_name\s+#{host}/)
          st = st + 1
          found = true
        elsif line.match(/host_name\s+/)
          st = 0
        elsif st > 0 and line.match(/_SYSTEM_MEMORY\s*/)
          st = st + 1
          # puts "#{host} memory set to #{info['mem']}"
          line = "  _SYSTEM_MEMORY '#{info['mem']}G'"
        elsif st > 0 and line.match(/_RSPROCS\s*/)
          st = st + 1
          # puts "#{host} procs set to #{info['procs']}"
          line = "  _RSPROCS '#{info['procs']}'"
        elsif st > 0 and line.match(/_RSCHECKERS\s*/)
          st = st + 1
          # puts "#{host} checkers set to #{info['checkers']}"
          line = "  _RSCHECKERS '#{info['checkers']}'"
        elsif st > 0 and not info['gate'] and line.match(/,rs_gate/)
          st = st + 1
          line = line.gsub(',rs_gate', '')
        elsif st > 0 and info['procs'] == 0 and line.match(/,rs_data/)
          st = st + 1
          line = line.gsub(',rs_data', '')
        elsif st > 0 and info['checkers'] == 0 and line.match(/,rs_checker/)
          st = st + 1
          line = line.gsub(',rs_checker', '')
        end
        lines << line
      end
      File.open(nagios_file, 'w+') do |f|
        lines.each { |line| f.puts line }
      end

      if not found then
        puts "add nagios host #{host}..."
        rs_proc_str = ''
        rs_proc_str = 'rs_gate' if info['gate']
        rs_proc_str += ',rs_data' if info['procs'] > 0
        rs_proc_str += ',rs_checker' if info['checkers'] > 0
        system(%Q{
cat >> #{nagios_file} <<ENDCAT

define host {
  use linux-server ; Inherit default values from a Windows server template (make sure you keep this line!)
  host_name #{host}
  address #{info['ip']}
  hostgroups snmphosts,nrpehosts,#{rs_proc_str}
  _SYSTEM_MEMORY '#{info['mem']}G'
  _RSPROCS '#{info['procs']}'
  _RSCHECKERS '#{info['checkers']}'
}
ENDCAT})
      end
    end
  end

  def init_hosts(hosts)
    hosts.each do |host, info|
      if info['ext_ip'].start_with?('120.92.')
        # ksyun hosts
        system(%Q{
echo 'Connecting to #{host}...'
ssh root@#{info['ext_ip']} <<ENDSSH
echo 'Connected to #{host}!'
if grep #{host} /etc/puppet/puppet.conf >/dev/null; then
  echo '#{host} already inited!'
else
  echo 'Initing host #{host}...'
  rm -f /etc/init.d/elasticsearch-es-rs_k600
  mkdir -p /removed/puppet /removed/rs
  mv /data/* /removed/
  mv /var/lib/puppet/* /removed/puppet/
  mv /usr/local/rs/* /removed/rs/

  sed -i -e 's/^#\/dev\/vdb1/\/dev\/vdb1/g' /etc/fstab
  #sed -i -e 's/^#\/data\/swapfile1/\/data\/swapfile1/g' /etc/fstab

  ~/mount_data.sh
  ~/create_swapfile.sh

  sed -i -e "s/rs_k600/#{host}/g" /etc/puppet/puppet.conf
  sed -i -e "s/rs_k6/#{info['env']}/g" /etc/puppet/puppet.conf

  puppet agent -t

  echo 'Initing host #{host} done'
fi
ENDSSH

ssh root@puppet1.firevale.com <<ENDSSH
if puppet cert -l | grep #{host} >/dev/null; then
  puppet cert -s #{host}
fi
ENDSSH
})
      end
    end

    hosts.each do |host, info|
      system(%Q{
ssh root@#{info['ext_ip']} <<ENDSSH
puppet agent -t
ENDSSH
})
    end
  end

  def save_hosts(hosts)
    `cp -f #{HOSTS_FILE} #{HOSTS_BACKUP}`

    content_new = []
    hosts_exists = {}
    File.open(HOSTS_FILE).each do |line|
      match_host = nil
      hosts.each do |host, info|
        match = line.match(/\s+#{host}\s*$/)
        match_host = [ host, info['ext_ip'] ] if match and match.captures
      end
      if match_host
        hosts_exists[match_host[0]] = true
        content_new << "#{match_host[1]} #{match_host[0]}"
      else
        content_new << line.strip
      end
    end

    if hosts_exists.keys.length < hosts.keys.length
      content_new << "\n# Added by sync_hosts.rb (#{Time.now})"
      hosts.each do |host, info|
        content_new << "#{info['ext_ip']} #{host}" unless hosts_exists[host]
      end
    end

    File.open(HOSTS_NEW, "w+") do |f| f.puts content_new.join "\n" end

    puts "(You may have to enter your password to save #{HOSTS_FILE})"

    `sudo mv #{HOSTS_NEW} #{HOSTS_FILE}`

    puts "#{HOSTS_FILE} rewritten, a backup was saved to #{HOSTS_BACKUP}"
  end

end

hosts = Parser.new.parse(DEF_FILES)
modifier = Modifier.new

puts "======================================================="
puts "saving all hosts to #{HOSTS_FILE}..."
modifier.save_hosts(hosts)

puts "======================================================="
puts "saving all hosts to puppet yaml..."
modifier.save_env_yaml(hosts)

puts "======================================================="
puts "saving all hosts to puppet nagios hosts..."
modifier.save_nagios_hosts(hosts)

# puts "======================================================="
# puts "init all hosts with puppet..."
# modifier.init_hosts(hosts)

puts "all done!"
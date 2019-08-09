#!/usr/bin/env ruby
# parse gpu list from web:
# http://www.notebookcheck.net/Mobile-Graphics-Cards-Benchmark-List.844.0.html
#
# generate a lua file
#

require 'nokogiri'
require 'open-uri'
require 'erb'

Dir.chdir(File.expand_path(File.dirname(__FILE__) + '/..'))

url = "https://www.notebookcheck.net/Mobile-Graphics-Cards-Benchmark-List.844.0.html?type=&sort=&deskornote=3&or=0&search=&month=&benchmark_values=&gpubenchmarks=0&professional=0&archive=0&dx=0&multiplegpus=0&showClassDescription=1&condensed=0&showCount=0&showBars=1&showPercent=0&3dmark13_ice_gpu=1&3dmark13_cloud=1&3dmark13_cloud_gpu=1&3dmark13_fire=1&3dmark13_fire_gpu=1&3dmark11_gpu=1&vantage3dmarkgpu=1&3dmark06=1&gpu_fullname=1&codename=1&architecture=1&pixelshaders=1&vertexshaders=1&corespeed=1&shaderspeed=1&boostspeed=1&memoryspeed=1&memorybus=1&memorytype=1&directx=1&opengl=1&technology=1&daysold=1"
gpulist = []

# parse html for gpulist
doc = Nokogiri::HTML(open(url))
doc.xpath('//body//div//form//table//tr').each do |tr|
  if tr['class'] =~ /smartphone/ then
    gpu = {}
    tr.children.each_with_index do |c, i|
      case i
      when 1; gpu['rank'] = c.children[1].to_s.delete("\u00A0*").to_i
      when 2; gpu['name'] = c.children[0].inner_html
      when 3; gpu['codename'] = c.inner_html
      when 4; gpu['arch'] = c.inner_html
      when 13; gpu['opengl'] = c.inner_html
      when 15; gpu['days'] = c.inner_html.to_i
      when 16
        div = c.children[0]
        if div then
          span = div.children[3]
          if span then
            score_elem = span.children[0]
            if score_elem then
              gpu['score'] = score_elem.inner_html.to_f
            end
          end
        end
      end
    end
    gpulist << gpu
  end
end

# add custom gpus
gpulist << {'name'=>'Vivante GC2000', 'rank'=>9999, 'days'=>9999, 'codename'=>'', 'arch'=>'', 'opengl'=>''}
gpulist << {'name'=>'Emulated GPU running OpenGL ES 2.0', 'rank'=>100, 'days'=>9999, 'score'=>150000, 'codename'=>'', 'arch'=>'', 'opengl'=>''}

# add info
gpulist.each do |gpu|
  if gpu['name'] then
    gpu['keywords'] = gpu['name'].split(/\s|\-|\(|\)|\//).reject do |k|
      k == nil or k == '' or
      k == 'Qualcomm' or k == 'Apple' or k == 'NVIDIA' or k == 'ARM' or
      k == 'Intel' or k == 'Vivante' or k == 'Broadcom' or k == 'A9' or
      k == 'Bionic' or k == 'Fusion' or k == 'PowerVR'
    end
  else
    gpu['keywords'] = []
  end
  gpu['lua_keywords'] = gpu['keywords'].map{|k| "'#{k}', " }.join
end

# generate lua file
lua = ERB.new(%Q{-- gpulist.lua
-- generated with gen_gpulist.rb at #{Time.now}
-- DO NOT EDIT!!!

return {
<% gpulist.each do |gpu| %>
  {
    name = '<%= gpu['name'] %>',
    keywords = { <%= gpu['lua_keywords'] %> },
    rank = <%= gpu['rank'] %>,
    codename = '<%= gpu['codename'] %>',
    arch = '<%= gpu['arch'] %>',
    opengl = '<%= gpu['opengl'] %>',
    days = <%= gpu['days'] %>,
    score = <%= gpu['score'] || 'nil' %>,
  },
<% end %>
}
}).result

File.open('client/scripts/lullaby/utils/gpulist.lua', 'w+') do |f|
  f.puts lua
end


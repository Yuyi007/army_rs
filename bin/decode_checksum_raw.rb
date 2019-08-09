#!/usr/bin/env ruby

require 'base64'

SRC=ARGV[0]
DST="#{SRC}.raw"

File.open(SRC, "r") do |f|
	turn = f.gets()
	sum = f.gets()
	base = f.gets()
	File.open(DST, "wb+") do |f|
		f.write(Base64.decode64(base))
	end
end

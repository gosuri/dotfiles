#!/usr/bin/env ruby
# Requires imagesnap http://iharder.sourceforge.net/current/macosx/imagesnap/
# brew install imagesnap
file="#{Time.now.to_i}.jpg"
unless File.directory?(File.expand_path("../../rebase-merge", __FILE__))
  puts "Taking capture into #{file}!"
  system "imagesnap -q -w 3 #{file} &"
end
exit 0

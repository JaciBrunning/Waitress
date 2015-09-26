$LOAD_PATH << File.expand_path( File.dirname(__FILE__) + '/../lib' )
require 'waitress'

trap("INT") { exit }

conf = Waitress.serve! true
conf.run
conf.join

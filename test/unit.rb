$LOAD_PATH << File.expand_path( File.dirname(__FILE__) + '/../lib' )
require 'coveralls'
Coveralls.wear!
require 'test/unit'

require 'waitress'

require_relative 'query_test'
require_relative 'util_test'
